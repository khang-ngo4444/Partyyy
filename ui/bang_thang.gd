extends Control

## Bảng THẮNG cuối ván: ai thắng, bao nhiêu cốc. Che kín màn hình vài giây rồi tắt.
##
## CHỈ HIỂN THỊ. Không biết luật thắng, không biết ai đang chơi — `main.gd` đưa sẵn câu chữ.
## Bàn party ở dưới vẫn còn nguyên trong lúc bảng này hiện, nên người chơi thấy bàn mờ đi
## phía sau chứ không phải một màn hình đen trơ trọi.

@onready var _chu: Label = $Chu


func _ready() -> void:
	visible = false


func hien(chu: String) -> void:
	_chu.text = chu
	visible = true


func an() -> void:
	visible = false
