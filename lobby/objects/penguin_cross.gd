class_name PenguinCross
extends Node3D

## Penguin Cross: trò tham-hay-dừng, một người bước trên ray, cả phòng xem.
## Người bước tự gieo rồi gửi kết quả, không hỏi master.

signal ended(walker_id: int, multiplier: float, fell: bool)

## Hệ số theo từng bước.
const MULTIPLIER := [1.0, 1.2, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0]

## Xác suất sống sót mỗi bước; đi trọn 8 bước ≈ 0.5%.
const SURVIVE := [0.90, 0.80, 0.70, 0.58, 0.46, 0.34, 0.24, 0.15]

@export var step_length := 0.34
@export var rail_width := 0.42

## Chiều cao mặt bàn (bằng bàn bài).
@export var table_height := 0.75

## Ray nhô khỏi mặt bàn chừng này.
@export var rail_rise := 0.16

## 0 = chưa ai bước.
var walker_id := 0
var step := 0
var _ky_luc := 0.0
var _ky_luc_ten := ""

@onready var board: Label3D = $Board

## Bàn, ray, vạch hệ số, nút dựng sẵn trong penguin_cross.tscn; script chỉ dời cánh cụt theo ray.
@onready var _penguin: Node3D = $Penguin


func _ready() -> void:
	add_to_group("penguin_cross")
	_reset()


func busy() -> bool:
	return walker_id != 0


## Ai bấm trước thì người đó bước; chạy ở mọi máy.
func begin(player_id: int) -> void:
	if busy():
		return
	walker_id = player_id
	step = 0
	_move_penguin(0.0)
	_penguin.rotation.z = 0.0
	_cap_nhat_bang()


## `song` do máy người bước quyết; mọi máy diễn lại.
func advance(song: bool) -> void:
	if not busy():
		return
	if not song:
		_nga()
		return
	step = mini(step + 1, MULTIPLIER.size() - 1)
	_move_penguin(step * step_length)
	if step >= MULTIPLIER.size() - 1:
		# Hết ray thì tự dừng.
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


## Xác suất sống của bước sắp tới.
func survive_chance() -> float:
	return SURVIVE[mini(step, SURVIVE.size() - 1)]


func _nga() -> void:
	var he_so: float = MULTIPLIER[step]
	var ten := Player.ten_theo_id(get_tree(), walker_id)
	board.text = "%s NGA O %.1fx%s" % [ten, he_so, _dong_ky_luc()]
	ended.emit(walker_id, he_so, true)
	walker_id = 0
	step = 0
	# Ngã khỏi ray: lăn nghiêng rồi rơi xuống sàn.
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
