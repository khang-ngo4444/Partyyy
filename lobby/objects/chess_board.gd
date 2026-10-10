class_name ChessBoard
extends Node3D

## Mặt bàn cờ: chỉ hình học và gióng quân, không có luật. Lưới và hình va chạm của từng
## chế độ dựng sẵn trong ban_co.tscn / ban_caro.tscn; đổi chế độ chỉ bật/tắt chúng.
## Cờ vua 8×8 ô (quân giữa ô), cờ tướng 9×10 giao điểm (sông, cung), caro lưới đều.

enum Mode { CHESS, XIANGQI, CARO }

const LUOI := ["LuoiCoVua", "LuoiCoTuong", "LuoiCaro"]
const HINH := ["HinhCoVua", "HinhCoTuong", "HinhCaro"]

## Chế độ bàn, đặt trong scene.
@export var mode: int = Mode.CHESS

## Khoảng cách giữa hai ô / giao điểm; dưới ~0.5 m thì dễ nhặt nhầm.
@export var cell_size := 1.05

## Số đường của bàn caro.
@export var caro_lines := 28

## Bàn nằm phẳng trên sàn, không bậc (CharacterBody3D không tự trèo).
@export var surface_y := 0.02


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


## Toạ độ thế giới của chỗ đặt quân: tâm ô (cờ vua) hoặc giao điểm.
func point(col: int, row: int) -> Vector3:
	return to_global(Vector3(_axis(col, cols()), surface_y, _axis(row, rows())))


## Chỗ đặt quân gần nhất với một điểm; phép ngược của `_axis` (cờ vua floor, giao điểm round).
func nearest_point(world_pos: Vector3) -> Vector3:
	var local := to_local(world_pos)
	return point(_chi_so(local.x, cols()), _chi_so(local.z, rows()))


func _chi_so(v: float, count: int) -> int:
	var t := (v + _half(count)) / cell_size
	return clampi(floori(t) if mode == Mode.CHESS else roundi(t), 0, count - 1)


## Điểm có nằm trên mặt bàn không.
func contains(world_pos: Vector3) -> bool:
	var local := to_local(world_pos)
	return absf(local.x) <= _half(cols()) + cell_size * 0.5 \
		and absf(local.z) <= _half(rows()) + cell_size * 0.5


## Lật bàn quanh trục Z: xoay tới cạnh, dựng lưới mới, xoay nốt. `await` được.
func flip_to(new_mode: int, duration := 1.2) -> void:
	var t := create_tween()
	t.tween_property(self, "rotation:z", PI * 0.5, duration * 0.5)
	t.tween_callback(func():
		mode = new_mode
		rebuild())
	t.tween_property(self, "rotation:z", PI, duration * 0.5)
	# Đưa về 0 cho toạ độ khỏi lệch.
	t.tween_callback(func(): rotation.z = 0.0)
	await t.finished


## Hiện lưới và bật hình va chạm của chế độ hiện tại.
func rebuild() -> void:
	for m in LUOI.size():
		var luoi := get_node_or_null(LUOI[m]) as Node3D
		if luoi != null:
			luoi.visible = m == mode
		var hinh := get_node_or_null("StaticSurface_Board/" + HINH[m]) as CollisionShape3D
		if hinh != null:
			hinh.disabled = m != mode


## Toạ độ trên một trục theo chỉ số; cờ vua lệch nửa ô.
func _axis(i: int, count: int) -> float:
	if mode == Mode.CHESS:
		return (i + 0.5) * cell_size - _half(count)
	return i * cell_size - _half(count)


func _half(count: int) -> float:
	if mode == Mode.CHESS:
		return count * cell_size * 0.5
	return (count - 1) * cell_size * 0.5
