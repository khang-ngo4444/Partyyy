class_name PenguinCross
extends Node3D

## Penguin Cross — trò tham-hay-dừng. Một người bước, cả phòng đứng xem.
##
## KHÔNG CƯỢC BẰNG XU. Xu chỉ là đạo cụ, refill thoải mái, nên mất xu chẳng đau — trò sẽ vô
## nghĩa. **Cược bằng khán giả:** con cánh cụt đi thật trên đường ray giữa phòng, hệ số hiện
## to trên đầu, mọi người đứng nhìn bạn tham tới 8× rồi ngã. Cái mất là thua trước mặt cả
## phòng — không refill được, và miễn phí về mặt code.
##
## Người bước TỰ gieo rồi gửi kết quả đi, không hỏi master (xem mục 1aj). Chơi với bạn bè
## thì việc họ có thể sửa client để không bao giờ ngã không đáng bận tâm.

signal ended(walker_id: int, multiplier: float, fell: bool)

## Hệ số theo từng bước. Càng đi càng lãi, mà cũng càng dễ ngã.
const MULTIPLIER := [1.0, 1.2, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0]
## Xác suất SỐNG SÓT của mỗi bước. Hạ xuống so với bản đầu — trước đó đi tới 4x quá dễ nên
## chẳng ai phải cân nhắc, mà cân nhắc mới là toàn bộ cái hay của trò này.
## Đi trọn 8 bước giờ chỉ còn 0.90×0.80×0.70×0.58×0.46×0.34×0.24×0.15 ≈ 0.5%.
const SURVIVE := [0.90, 0.80, 0.70, 0.58, 0.46, 0.34, 0.24, 0.15]

@export var step_length := 0.34
@export var rail_width := 0.42
## Mặt bàn. Bằng bàn bài để cả khu board game cùng một tầm mắt.
@export var table_height := 0.75
## Ray nhô lên khỏi mặt bàn chừng này — ngã mới ra dáng ngã.
@export var rail_rise := 0.16

@onready var board: Label3D = $Board

## 0 = chưa ai bước.
var walker_id := 0
var step := 0

## Con cánh cụt: node `Penguin` trong penguin_cross.tscn — script chỉ dời nó theo ray.
@onready var _penguin: Node3D = $Penguin
var _ky_luc := 0.0
var _ky_luc_ten := ""


func _ready() -> void:
	add_to_group("penguin_cross")
	_build_rail()
	_reset()


func busy() -> bool:
	return walker_id != 0


## Ai bấm trước thì người đó bước. Chạy ở MỌI máy nên máy nào cũng biết đang tới lượt ai.
func begin(player_id: int) -> void:
	if busy():
		return
	walker_id = player_id
	step = 0
	_move_penguin(0.0)
	_penguin.rotation.z = 0.0
	_cap_nhat_bang()


## `song` do CHÍNH máy người bước quyết rồi gửi sang — mọi máy chỉ diễn lại.
func advance(song: bool) -> void:
	if not busy():
		return
	if not song:
		_nga()
		return
	step = mini(step + 1, MULTIPLIER.size() - 1)
	_move_penguin(step * step_length)
	if step >= MULTIPLIER.size() - 1:
		# Hết ray thì tự dừng — không có bước nào để tham thêm.
		stop()
		return
	_cap_nhat_bang()


func stop() -> void:
	if not busy():
		return
	var he_so: float = MULTIPLIER[step]
	var ten := Player.ten_theo_id(get_tree(), walker_id)
	if he_so > _ky_luc:
		_ky_luc = he_so
		_ky_luc_ten = ten
	board.text = "%s DUNG O %.1fx - AN TOAN%s" % [ten, he_so, _dong_ky_luc()]
	ended.emit(walker_id, he_so, false)
	walker_id = 0
	step = 0


## Xác suất sống của bước SẮP TỚI. Người bước tự gieo bằng con số này.
func survive_chance() -> float:
	return SURVIVE[mini(step, SURVIVE.size() - 1)]


func _nga() -> void:
	var he_so: float = MULTIPLIER[step]
	var ten := Player.ten_theo_id(get_tree(), walker_id)
	board.text = "%s NGA O %.1fx%s" % [ten, he_so, _dong_ky_luc()]
	ended.emit(walker_id, he_so, true)
	walker_id = 0
	step = 0
	# Ngã khỏi ray: lăn nghiêng rồi rơi xuống sàn. Đủ để cả phòng thấy chuyện gì vừa xảy ra.
	var t := create_tween()
	t.tween_property(_penguin, "rotation:z", PI * 0.5, 0.25)
	t.parallel().tween_property(_penguin, "position:y", table_height - 0.25, 0.35)
	t.tween_interval(1.6)
	t.tween_callback(_reset)


func _reset() -> void:
	walker_id = 0
	step = 0
	_move_penguin(0.0)
	_penguin.rotation.z = 0.0
	board.text = "PENGUIN CROSS - BAM DI TIEP DE CHOI%s" % _dong_ky_luc()


func _mat_ray() -> float:
	return table_height + rail_rise


func _move_penguin(z: float) -> void:
	_penguin.position = Vector3(0.0, _mat_ray(), -_rail_length() * 0.5 + z)


func _rail_length() -> float:
	return (MULTIPLIER.size() - 1) * step_length


func _cap_nhat_bang() -> void:
	board.text = "%s  -  %.1fx  -  buoc sau song %d%%" % [
		Player.ten_theo_id(get_tree(), walker_id), MULTIPLIER[step], roundi(survive_chance() * 100.0)]


func _dong_ky_luc() -> String:
	return "" if _ky_luc <= 0.0 else "\nKY LUC: %s %.1fx" % [_ky_luc_ten, _ky_luc]



## Ray đặt TRÊN MỘT CÁI BÀN, giống mọi board game khác trong khu — chỉ hai bàn cờ mới nằm
## thẳng trên sàn. Ray vẫn nhô cao hơn mặt bàn để cú ngã đọc được.
func _build_rail() -> void:
	var dai := _rail_length()
	var rong := rail_width + 0.5
	var sau := dai + step_length + 0.3

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(rong, _mat_ray(), sau)
	shape.shape = bs
	shape.position.y = _mat_ray() * 0.5
	body.add_child(shape)
	add_child(body)

	# Chân bàn
	_khoi(Vector3(0.0, table_height * 0.5, 0.0), Vector3(rong * 0.5, table_height, sau * 0.5),
			Color("3d4048"))
	# Mặt bàn
	_khoi(Vector3(0.0, table_height - 0.04, 0.0), Vector3(rong, 0.08, sau), Color("2f5d3f"))
	# Ray chạy
	_khoi(Vector3(0.0, table_height + rail_rise * 0.5, 0.0),
			Vector3(rail_width, rail_rise, dai + step_length), Color("2b3a55"))

	# Vạch từng bước + hệ số ghi ngay trên ray.
	for i in MULTIPLIER.size():
		var z := -dai * 0.5 + i * step_length
		_khoi(Vector3(0.0, _mat_ray() + 0.01, z), Vector3(rail_width, 0.02, 0.03),
				Color("d9d2c5"))
		var tag := Label3D.new()
		tag.text = "%.1fx" % MULTIPLIER[i]
		tag.font_size = 30
		tag.pixel_size = 0.0018
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.outline_size = 6
		tag.modulate = Color("f5d90a").lerp(Color("e5484d"), float(i) / (MULTIPLIER.size() - 1))
		tag.position = Vector3(-rail_width * 0.5 - 0.16, _mat_ray() + 0.1, z)
		add_child(tag)

	_build_buttons()


## ĐÚNG HAI NÚT. Chưa ai bước thì ĐI TIẾP chính là nút bắt đầu — không cần nút BẮT ĐẦU riêng,
## vì bước đầu tiên và bước thứ hai là cùng một hành động dưới mắt người chơi.
func _build_buttons() -> void:
	var packed := load("res://lobby/objects/pressable.tscn") as PackedScene
	var x := rail_width * 0.5 + 0.38
	for i in 2:
		var b: Pressable = packed.instantiate()
		b.name = "PenguinStep" if i == 0 else "PenguinStop"
		b.label = "DI TIEP" if i == 0 else "DUNG LAI"
		b.color = Color("f5d90a") if i == 0 else Color("e5484d")
		b.compact = true
		b.label_size = 30
		b.press_range = 2.4
		b.position = Vector3(x, table_height, -_rail_length() * 0.25 + i * _rail_length() * 0.5)
		add_child(b)


func _khoi(pos: Vector3, size: Vector3, mau: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = _mat(mau)
	m.position = pos
	add_child(m)


func _mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	return mat
