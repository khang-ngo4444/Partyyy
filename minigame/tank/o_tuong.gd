class_name OTuong
extends Node2D

## Một ô tường Tank: đổi màu theo loại.

## Gạch vỡ được, thép thì không.
enum Loai { GACH, THEP }

@export var loai: Loai = Loai.GACH:
	set(value):
		loai = value
		if is_node_ready():
			_ve()

## Màu theo thứ tự enum `Loai`.
@export var mau: Array[Color] = []

@onready var _mau: ColorRect = $Mau


func _ready() -> void:
	_ve()


func _ve() -> void:
	if loai >= 0 and loai < mau.size():
		_mau.color = mau[loai]
