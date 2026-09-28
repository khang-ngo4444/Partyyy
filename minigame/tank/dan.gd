class_name Dan
extends Node2D

## MỘT viên đạn. Hình nằm trong `dan.tscn`; đạn tự bay, `TankBattle` chỉ phán nó trúng gì.

const TOC := 340.0

var huong := Vector2.ZERO
var chu := 0                     ## player_id người bắn — đạn không giết chủ nó


func _process(delta: float) -> void:
	position += huong * TOC * delta
