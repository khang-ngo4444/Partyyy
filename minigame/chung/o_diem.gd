class_name ODiem
extends PanelContainer

## Một ô trong dải điểm: hạng, tên, điểm. Nền màu nhân vật, ô của mình viền vàng.

var _chu_cu := ""

@onready var _hang: Label = %Hang
@onready var _ten: Label = %Ten
@onready var _diem: Label = %Diem


func dat(hang: int, ten: String, mau: Color, chu: String, la_toi: bool) -> void:
	var s := UIKit.hop(mau.lerp(Color.WHITE, 0.55), 18, 5, 4, 8)
	if la_toi:
		s.border_color = UIKit.CAM
		s.set_border_width_all(6)
	add_theme_stylebox_override("panel", s)
	_hang.text = "#%d" % hang
	_hang.add_theme_color_override("font_color", UIKit.VANG if hang == 1 else Color.WHITE)
	_ten.text = ten
	_diem.text = chu
	if chu != _chu_cu and _chu_cu != "":
		UINav.nay(_diem, 1.3)
	_chu_cu = chu
