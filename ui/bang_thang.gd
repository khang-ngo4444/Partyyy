extends Control

## Bảng thắng cuối ván (`main.gd` đưa sẵn câu chữ).

@onready var _chu: Label = $Chu


func _ready() -> void:
	visible = false


func hien(chu: String) -> void:
	_chu.text = chu
	visible = true


func an() -> void:
	visible = false
