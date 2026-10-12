class_name OMau
extends Button

## Ô màu tròn bấm được: viền mực + bóng cứng; đang chọn = dấu tích + viền dày.

var _mau := Color.WHITE


func _init() -> void:
	custom_minimum_size = Vector2(46, 46)
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_icon = true


func dat(mau: Color, dang_chon := false) -> void:
	_mau = mau
	var thuong := UIKit.hop(mau, 999, 4, 4, 6)
	var sang := UIKit.hop(mau.lightened(0.18), 999, 6, 4, 6)
	var lun := UIKit.hop(mau.darkened(0.1), 999, 1, 4, 6)
	if dang_chon:
		for s: StyleBoxFlat in [thuong, sang, lun]:
			s.set_border_width_all(6)
	add_theme_stylebox_override("normal", thuong)
	add_theme_stylebox_override("hover", sang)
	add_theme_stylebox_override("pressed", lun)
	add_theme_stylebox_override("hover_pressed", lun)
	# Ô có chữ (A/B ở LightPicker) giữ chữ, chỉ viền dày.
	icon = UIKit.icon("checkmark") if dang_chon and text == "" else null
	# Dấu tích tương phản với màu nền.
	var c := UIKit.MUC if mau.get_luminance() > 0.6 else Color.WHITE
	for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		add_theme_color_override(k, c)
