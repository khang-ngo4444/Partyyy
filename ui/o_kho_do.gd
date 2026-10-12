class_name OKhoDo
extends Button

## Một ô trong popup Kho đồ. Kéo-thả sang ô khác để đổi chỗ (báo qua `tha`).

signal tha(tu: int, toi: int)

var chi_so := 0
var mon := ""
var la_o_nhanh := false

var _danh_muc: DanhMucVatPham = preload("res://board/danh_muc_vat_pham.tres")
var _ten := Label.new()


func _init() -> void:
	custom_minimum_size = Vector2(76, 76)
	focus_mode = Control.FOCUS_ALL
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	clip_text = true
	add_theme_constant_override("icon_max_width", 42)
	for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
			"icon_focus_color", "icon_hover_pressed_color", "icon_disabled_color"]:
		add_theme_color_override(k, Color.WHITE)
	_ten.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ten.add_theme_font_size_override("font_size", 12)
	_ten.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ten.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_ten.clip_text = true
	add_child(_ten)
	_ten.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_ten.offset_left = 4
	_ten.offset_right = -4
	_ten.offset_top = -22
	_ten.offset_bottom = -4


func dat(i: int, m: String, dang_cam: bool) -> void:
	chi_so = i
	mon = m
	var hinh := _danh_muc.tim(m) if not m.is_empty() else null
	icon = hinh.icon if hinh != null else null
	_ten.text = VatPham.ten(m) if not m.is_empty() else ""
	tooltip_text = _ten.text
	var nen := Color("F3E3BC")
	if not m.is_empty():
		nen = Color.WHITE
	if la_o_nhanh and m.is_empty():
		nen = Color("FFF1B8")
	if dang_cam:
		nen = UIKit.VANG
	var thuong := UIKit.hop(nen, 14, 0 if m.is_empty() else 4, 3, 6)
	if m.is_empty():
		thuong.border_color = Color(UIKit.MUC, 0.35)
	if dang_cam:
		thuong.border_color = UIKit.CAM
		thuong.set_border_width_all(5)
	add_theme_stylebox_override("normal", thuong)
	add_theme_stylebox_override("hover", UIKit.hop(nen.lightened(0.3), 14, 6, 3, 6))
	add_theme_stylebox_override("pressed", UIKit.hop(nen.darkened(0.08), 14, 1, 3, 6))
	add_theme_stylebox_override("hover_pressed", UIKit.hop(nen.darkened(0.08), 14, 1, 3, 6))


# ---------- Kéo thả ----------

func _get_drag_data(_at: Vector2) -> Variant:
	if mon.is_empty():
		return null
	var anh := TextureRect.new()
	anh.texture = icon
	anh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	anh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	anh.custom_minimum_size = Vector2(64, 64)
	anh.size = Vector2(64, 64)
	anh.position = Vector2(-32, -32)
	var goc := Control.new()
	goc.add_child(anh)
	set_drag_preview(goc)
	return {"o_kho": chi_so}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("o_kho") and int(data["o_kho"]) != chi_so


func _drop_data(_at: Vector2, data: Variant) -> void:
	tha.emit(int(data["o_kho"]), chi_so)
