class_name DiceTable
extends Node3D

## Bàn gieo xúc xắc: cộng hai viên `Die` đang nằm trên bàn (đọc theo vị trí đã replicate).

## Đọc lại 4 lần/giây.
const REFRESH := 0.25

@export var table_radius := 0.9
@export var table_height := 0.75

var _acc := 0.0
var _last := ""

@onready var board: Label3D = $Result


func _ready() -> void:
	add_to_group("dice_table")


func _process(delta: float) -> void:
	_acc += delta
	if _acc < REFRESH:
		return
	_acc = 0.0
	var txt := _doc()
	if txt != _last:
		_last = txt
		board.text = txt


## Xúc xắc đang nằm trên bàn; viên đang cầm không tính.
func _doc() -> String:
	var tong := 0
	var n := 0
	for d in get_tree().get_nodes_in_group("die"):
		var die := d as Die
		# value 0 = viên đang lăn.
		if die == null or die.holder_id != 0 or die.value == 0:
			continue
		var v := die.global_position - global_position
		if Vector2(v.x, v.z).length() <= table_radius and absf(v.y - table_height) < 0.5:
			tong += die.value
			n += 1
	if n == 0:
		return "NEM XUC XAC LEN BAN"
	if n == 1:
		return "%d  (moi co 1 vien tren ban)" % tong
	return "%d" % tong

