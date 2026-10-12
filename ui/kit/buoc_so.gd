class_name BuocSo
extends PanelContainer

## Ô chỉnh số to: [ nhãn ][ - ][ 10 ][ + ].
## Cả hàng là một điểm focus: ←/→ (hoặc A/D) giảm/tăng, lăn chuột cũng được.

signal value_changed(value: float)

var min_value := 0.0
var max_value := 100.0
var step := 1.0
var suffix := ""
var value := 0.0:
	set(v):
		var moi := clampf(snappedf(v, step), min_value, max_value)
		if is_equal_approx(moi, value):
			return
		value = moi
		_cap_nhat()
		value_changed.emit(value)

var _nhan := Label.new()
var _so := Label.new()
var _tru := Button.new()
var _cong := Button.new()
var _hop_thuong: StyleBoxFlat
var _hop_focus: StyleBoxFlat


func _init(nhan := "", mau_nen := Color.WHITE) -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_hop_thuong = UIKit.hop(mau_nen, 18, 4, 4, 8)
	_hop_thuong.content_margin_left = 16
	_hop_focus = UIKit.hop(UIKit.VANG, 18, 4, 4, 8)
	_hop_focus.border_color = UIKit.CAM
	_hop_focus.set_border_width_all(5)
	_hop_focus.content_margin_left = 16
	add_theme_stylebox_override("panel", _hop_thuong)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	add_child(hb)
	_nhan.text = nhan
	_nhan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nhan.add_theme_font_size_override("font_size", 19)
	_nhan.tooltip_text = nhan
	_nhan.mouse_filter = Control.MOUSE_FILTER_PASS
	_nhan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_nhan.clip_text = true
	hb.add_child(_nhan)
	for b: Button in [_tru, _cong]:
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(42, 40)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.theme_type_variation = &"NutTrang"
		b.add_theme_font_size_override("font_size", 26)
		var s := UIKit.hop(Color.WHITE, 12, 3, 3, 0)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", UIKit.hop(Color("FFF1B8"), 12, 4, 3, 0))
		b.add_theme_stylebox_override("pressed", UIKit.hop(Color("F3E3BC"), 12, 1, 3, 0))
		var tat := UIKit.hop(Color("EEE6D6"), 12, 0, 3, 0)
		tat.border_color = Color(UIKit.MUC, 0.3)
		b.add_theme_stylebox_override("disabled", tat)
	_tru.text = "–"
	_cong.text = "+"
	_tru.pressed.connect(func(): _doi(-1))
	_cong.pressed.connect(func(): _doi(1))
	_so.custom_minimum_size = Vector2(64, 0)
	_so.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_so.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_so.theme_type_variation = &"ChuDauMuc"
	_so.add_theme_font_size_override("font_size", 26)
	hb.add_child(_tru)
	hb.add_child(_so)
	hb.add_child(_cong)
	focus_entered.connect(func(): add_theme_stylebox_override("panel", _hop_focus))
	focus_exited.connect(func(): add_theme_stylebox_override("panel", _hop_thuong))
	_cap_nhat()


func dat(gia_tri: float, phat := false) -> void:
	if phat:
		value = gia_tri
		return
	set_block_signals(true)
	value = gia_tri
	set_block_signals(false)


func _doi(huong: int) -> void:
	# Giữ Shift = bước x10.
	var k := 10.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0
	var cu := value
	value = value + huong * step * k
	if not is_equal_approx(cu, value):
		UINav.nay(_so, 1.3)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left", true) or (event is InputEventKey
			and event.pressed and event.keycode == KEY_A):
		_doi(-1)
		accept_event()
	elif event.is_action_pressed("ui_right", true) or (event is InputEventKey
			and event.pressed and event.keycode == KEY_D):
		_doi(1)
		accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_doi(1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_doi(-1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()


func _cap_nhat() -> void:
	_so.text = "%d%s" % [roundi(value), suffix]
	_tru.disabled = value <= min_value
	_cong.disabled = value >= max_value
