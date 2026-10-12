extends Control

## Bảng thắng cuối ván (`main.gd` đưa sẵn câu chữ): cúp nảy + pháo giấy.

@onready var _chu: Label = $Center/The/Cot/Chu
@onready var _the: Control = $Center/The
@onready var _cup: Control = $Center/The/Cot/Cup
@onready var _phao: CPUParticles2D = $PhaoGiay


func _ready() -> void:
	visible = false


func hien(chu: String) -> void:
	_chu.text = chu
	visible = true
	_phao.position = Vector2(size.x * 0.5, -20)
	_phao.emission_rect_extents = Vector2(size.x * 0.5, 4)
	_phao.restart()
	UINav.dap(_the)
	UINav.lo_lung(_cup, 8.0, 1.2)


func an() -> void:
	visible = false
	_phao.emitting = false
