class_name UIKit
extends RefCounted

## Dựng nhanh các mảnh UI hoạt hình dùng chung (thẻ nút to, huy hiệu phím, chip phím).

const MUC := Color("2B1B3D")
const KEM := Color("FFF6DC")
const VANG := Color("FFD54F")
const CAM := Color("F58A2C")
const HONG := Color("F78FA7")
const TIM := Color("8E5CF7")
const LA := Color("6CC04A")
const DO := Color("EF4B4B")
const TROI := Color("4FC3F7")

## Màu theo loại ô board — giữ đồng bộ HUD ↔ map.
const MAU_O := {"dat": Color("F5B041"), "mau": Color("EF4B4B"),
		"tien": Color("FFD54F"), "trang_bi": Color("8E5CF7")}


static func icon(ten: String) -> Texture2D:
	return load("res://ui/icons/kenney/%s.png" % ten)


## Thẻ nút to: icon trên, chữ dưới (giống hàng Shop/Inventory ảnh mẫu).
static func the_nut(nut: Button, chu: String, ten_icon: String, bien_the: StringName,
		co := Vector2(170, 180), co_icon := 72, co_chu := 26) -> Button:
	nut.text = chu
	nut.icon = icon(ten_icon)
	nut.theme_type_variation = bien_the
	nut.custom_minimum_size = co
	nut.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nut.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	nut.expand_icon = false
	nut.add_theme_constant_override("icon_max_width", co_icon)
	nut.add_theme_font_size_override("font_size", co_chu)
	return nut


## Huy hiệu phím tắt góc trên-phải control (vd. "1", "Esc").
static func gan_phim(c: Control, phim: String) -> Control:
	var cu := c.get_node_or_null("HuyHieuPhim")
	if cu != null:
		cu.queue_free()
	var pill := PanelContainer.new()
	pill.name = "HuyHieuPhim"
	pill.theme_type_variation = &"ThePillMuc"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lb := Label.new()
	lb.text = phim
	lb.add_theme_color_override("font_color", KEM)
	lb.add_theme_font_size_override("font_size", 17)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(lb)
	c.add_child(pill)
	pill.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
	pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pill.position = Vector2(c.size.x - 30, -14)
	c.resized.connect(func():
		if is_instance_valid(pill):
			pill.position = Vector2(c.size.x - pill.size.x + 10, -14))
	return pill


## Chip gợi ý phím: [Space] Tung xúc xắc.
static func chip_phim(phim: String, mo_ta: String, noi := true) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill := PanelContainer.new()
	pill.theme_type_variation = &"TheNho"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel", _hop_phim())
	var k := Label.new()
	k.text = phim
	k.add_theme_font_size_override("font_size", 18)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(k)
	hb.add_child(pill)
	var lb := Label.new()
	lb.text = mo_ta
	lb.theme_type_variation = &"ChuNoi" if noi else &""
	lb.add_theme_font_size_override("font_size", 19)
	hb.add_child(lb)
	return hb


static func _hop_phim() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.WHITE
	s.set_border_width_all(3)
	s.border_color = MUC
	s.set_corner_radius_all(10)
	s.shadow_color = MUC
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 1
	s.content_margin_bottom = 3
	return s


## Hộp màu tuỳ ý cùng kiểu sticker (viền mực + bóng cứng).
static func hop(nen: Color, bo := 22, bong := 6, vien := 4, le := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = nen
	s.set_border_width_all(vien)
	s.border_color = MUC
	s.set_corner_radius_all(bo)
	if bong > 0:
		s.shadow_color = MUC
		s.shadow_size = 1
		s.shadow_offset = Vector2(0, bong)
	s.set_content_margin_all(le)
	s.anti_aliasing_size = 1.2
	return s


## Nối phím mũi tên trái/phải giữa các nút trong một hàng (bọc vòng).
static func noi_hang(ds: Array) -> void:
	var n := ds.size()
	for i in n:
		var c: Control = ds[i]
		c.focus_neighbor_left = c.get_path_to(ds[(i - 1 + n) % n])
		c.focus_neighbor_right = c.get_path_to(ds[(i + 1) % n])
