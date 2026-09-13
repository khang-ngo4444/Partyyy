class_name ChessBoard
extends Node3D

## Mặt bàn cờ hai mặt. CHỈ là hình học và phép kết dính — không có luật cờ nào, không biết
## quân nào là quân gì, không quan tâm tới lượt đi.
##
## Hai chế độ khác nhau ở LƯỚI, không chỉ khác ở hình vẽ:
##   Cờ vua   — 8×8 Ô, quân đứng GIỮA Ô
##   Cờ tướng — 9×10 GIAO ĐIỂM, quân đứng TRÊN GIAO ĐIỂM, có sông và cung
##
## Vì vậy "lật mặt" không phải đổi texture — nó đổi cả cách tính vị trí.

enum Mode { CHESS, XIANGQI, CARO }

## Chế độ bàn. Đặt từ scene — bàn cờ vua/tướng và bàn caro là HAI instance khác nhau.
@export var mode: int = Mode.CHESS
## Khoảng cách giữa hai ô (cờ vua) hoặc hai giao điểm (cờ tướng, caro).
##
## Sàn dưới của khoảng cách này là ~0.5 m: người chơi ĐỨNG TRÊN bàn, mắt ở 1.65 m, nên hai
## giao điểm gần hơn thế sẽ cách nhau vài độ trong tầm nhìn và nhặt nhầm liên tục.
@export var cell_size := 1.05
## Số đường của bàn caro. 28×28 ở 0.5 m ra bàn 13.5 m — to nhưng vừa sàn.
@export var caro_lines := 28
## Bàn nằm PHẲNG trên sàn, không có bậc. Có bậc thì CharacterBody3D không tự trèo lên được,
## và người chơi sẽ vấp ở rìa bàn.
@export var surface_y := 0.02

@export var light_color := Color("d9d2c5")
@export var dark_color := Color("5c4a3d")
@export var board_color := Color("c9a86f")
@export var line_color := Color("3a2c1c")

func _ready() -> void:
	add_to_group("snap_surface")
	rebuild()


func cols() -> int:
	match mode:
		Mode.CHESS: return 8
		Mode.CARO: return caro_lines
		_: return 9


func rows() -> int:
	match mode:
		Mode.CHESS: return 8
		Mode.CARO: return caro_lines
		_: return 10


## Toạ độ thế giới của một vị trí đặt quân.
## Cờ vua: tâm ô. Cờ tướng: giao điểm.
func point(col: int, row: int) -> Vector3:
	return to_global(Vector3(_axis(col, cols()), surface_y, _axis(row, rows())))


## Điểm có nằm trên mặt bàn không. Rơi ra ngoài thì vật cứ nằm chỗ nó rơi.
func contains(world_pos: Vector3) -> bool:
	var local := to_local(world_pos)
	return absf(local.x) <= _half(cols()) + cell_size * 0.5 \
		and absf(local.z) <= _half(rows()) + cell_size * 0.5


## Lật mặt: xoay tới cạnh (không nhìn thấy gì), dựng lại lưới mới, rồi xoay nốt.
## Người chơi đã bị đẩy ra trước khi hàm này chạy.
##
## Xoay quanh trục Z — bàn lật NGANG, mép trái hất lên mép phải chúi xuống. Trước đây xoay
## quanh trục X (lật dọc, mép trước hất lên) trông như bàn đang đổ vào mặt người đứng xem.
##
## `await` được: người gọi cần biết lúc nào lật xong mới dám spawn bộ quân mới.
func flip_to(new_mode: int, duration := 1.2) -> void:
	var t := create_tween()
	t.tween_property(self, "rotation:z", PI * 0.5, duration * 0.5)
	t.tween_callback(func():
		mode = new_mode
		rebuild())
	t.tween_property(self, "rotation:z", PI, duration * 0.5)
	# Bàn phẳng nên xoay PI xong đưa về 0 là không ai thấy — chỉ để toạ độ khỏi lệch.
	t.tween_callback(func(): rotation.z = 0.0)
	await t.finished


func rebuild() -> void:
	for c in get_children():
		if c.name != &"StaticSurface_Board":
			c.queue_free()
	match mode:
		Mode.CHESS: _build_chess()
		Mode.CARO: _build_caro()
		_: _build_xiangqi()
	_dung_mat_va_cham()


## Mat ban co va cham duoc: quan co la RigidBody that, khong co mat nay thi quan roi xuyen xuong
## san phong, nam lun duoi mat ban 4 cm. Node StaticSurface_Board trong chess_board.tscn; lat mat ban
## thi chi doi co hinh theo luoi moi (gan hinh MOI — hai ban dung chung scene, khong sua hinh chung).
func _dung_mat_va_cham() -> void:
	var le := 0.0 if mode == Mode.CHESS else cell_size
	var hop := BoxShape3D.new()
	hop.size = Vector3(_half(cols()) * 2.0 + le, 0.04, _half(rows()) * 2.0 + le)
	var hinh := $StaticSurface_Board/CollisionShape3D as CollisionShape3D
	hinh.shape = hop
	hinh.position = Vector3(0.0, surface_y, 0.0)


## Cờ vua: 8×8 ô xen kẽ hai màu, dựng bằng code thay vì vẽ một texture bàn cờ.
func _build_chess() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(cell_size, 0.04, cell_size)
	var mats := [_flat(light_color), _flat(dark_color)]
	for row in rows():
		for col in cols():
			var m := MeshInstance3D.new()
			m.mesh = mesh
			m.material_override = mats[(row + col) % 2]
			m.position = Vector3(_axis(col, cols()), surface_y, _axis(row, rows()))
			add_child(m)


## Cờ tướng: mặt gỗ trơn + các đường kẻ. Sông là chỗ các đường dọc bên trong bị ngắt.
func _build_xiangqi() -> void:
	var w := _half(cols()) * 2.0
	var d := _half(rows()) * 2.0

	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w + cell_size, 0.04, d + cell_size)
	base.mesh = bm
	base.material_override = _flat(board_color)
	base.position = Vector3(0.0, surface_y, 0.0)
	add_child(base)

	var y := surface_y + 0.03

	# Đường ngang: kẻ suốt chiều rộng.
	for r in rows():
		_line(Vector3(0.0, y, _axis(r, rows())), Vector3(w, 0.03, 0.06))

	# Đường dọc: bị SÔNG ngắt ở giữa, trừ hai cột ngoài cùng.
	@warning_ignore("integer_division")
	var mid := rows() / 2
	var z_top := (_axis(0, rows()) + _axis(mid - 1, rows())) * 0.5
	var z_bot := (_axis(mid, rows()) + _axis(rows() - 1, rows())) * 0.5
	var half_len := absf(_axis(mid - 1, rows()) - _axis(0, rows()))
	for c in cols():
		var x := _axis(c, cols())
		if c == 0 or c == cols() - 1:
			_line(Vector3(x, y, 0.0), Vector3(0.06, 0.03, d))
		else:
			_line(Vector3(x, y, z_top), Vector3(0.06, 0.03, half_len))
			_line(Vector3(x, y, z_bot), Vector3(0.06, 0.03, half_len))

	# Cung: hai đường chéo ở mỗi đầu, cột 3..5.
	for side in 2:
		var r0 := 0 if side == 0 else rows() - 3
		_diagonal(_axis(3, cols()), _axis(r0, rows()), _axis(5, cols()), _axis(r0 + 2, rows()), y)
		_diagonal(_axis(5, cols()), _axis(r0, rows()), _axis(3, cols()), _axis(r0 + 2, rows()), y)


## Caro: mặt trơn + lưới kẻ đều, không sông không cung. Quân đứng trên giao điểm.
func _build_caro() -> void:
	var w := _half(cols()) * 2.0
	var d := _half(rows()) * 2.0

	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w + cell_size, 0.04, d + cell_size)
	base.mesh = bm
	base.material_override = _flat(board_color)
	base.position = Vector3(0.0, surface_y, 0.0)
	add_child(base)

	var y := surface_y + 0.03
	var thickness := minf(0.04, cell_size * 0.08)
	for r in rows():
		_line(Vector3(0.0, y, _axis(r, rows())), Vector3(w, 0.03, thickness))
	for c in cols():
		_line(Vector3(_axis(c, cols()), y, 0.0), Vector3(thickness, 0.03, d))


func _line(pos: Vector3, size: Vector3) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = _flat(line_color)
	m.position = pos
	add_child(m)


func _diagonal(x0: float, z0: float, x1: float, z1: float, y: float) -> void:
	var a := Vector3(x0, y, z0)
	var b := Vector3(x1, y, z1)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.03, a.distance_to(b))
	m.mesh = bm
	m.material_override = _flat(line_color)
	m.position = (a + b) * 0.5
	m.rotation.y = atan2(b.x - a.x, b.z - a.z)
	add_child(m)


func _flat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	return mat


## Toạ độ trên một trục theo chỉ số. Cờ vua lệch nửa ô (quân giữa ô); cờ tướng thì không
## (quân trên giao điểm).
func _axis(i: int, count: int) -> float:
	if mode == Mode.CHESS:
		return (i + 0.5) * cell_size - _half(count)
	return i * cell_size - _half(count)


func _half(count: int) -> float:
	if mode == Mode.CHESS:
		return count * cell_size * 0.5
	return (count - 1) * cell_size * 0.5
