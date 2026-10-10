class_name Dan
extends Node2D

## Một viên đạn tự bay.

const TOC := 340.0

var huong := Vector2.ZERO
var chu := 0                     ## player_id người bắn — đạn không giết chủ nó


func _process(delta: float) -> void:
	position += huong * TOC * delta
