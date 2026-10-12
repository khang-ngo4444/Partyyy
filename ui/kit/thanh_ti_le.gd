class_name ThanhTiLe
extends Control

## Thanh ngang chia 4 đoạn màu theo tỉ lệ loại ô (Đất/Máu/Tiền/Trang bị).
## Tổng ≠ 100 thì phần thiếu để trống sọc, phần dư cắt và viền đỏ.

var gia_tri: Array[int] = [40, 20, 25, 15]
var mau: Array[Color] = [UIKit.MAU_O["dat"], UIKit.MAU_O["mau"],
		UIKit.MAU_O["tien"], UIKit.MAU_O["trang_bi"]]


func _init() -> void:
	custom_minimum_size = Vector2(0, 46)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func dat(ds: Array) -> void:
	for i in mini(ds.size(), 4):
		gia_tri[i] = int(ds[i])
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(0, 0), size - Vector2(0, 5))
	var tong := 0
	for v in gia_tri:
		tong += v
	# bóng cứng
	draw_style_box(UIKit.hop(UIKit.MUC, 999, 0, 0, 0), Rect2(r.position + Vector2(0, 5), r.size))
	draw_style_box(UIKit.hop(Color("F3E3BC"), 999, 0, 0, 0), r)
	var x := r.position.x
	var font := get_theme_default_font()
	for i in 4:
		var w := r.size.x * float(gia_tri[i]) / 100.0
		w = minf(w, r.end.x - x)
		if w <= 0.5:
			continue
		var doan := Rect2(x, r.position.y, w, r.size.y)
		var s := StyleBoxFlat.new()
		s.bg_color = mau[i]
		var bo := int(r.size.y / 2)
		s.corner_radius_top_left = bo if i == 0 or x <= r.position.x + 1 else 0
		s.corner_radius_bottom_left = s.corner_radius_top_left
		var cuoi := x + w >= r.end.x - 1
		s.corner_radius_top_right = bo if cuoi else 0
		s.corner_radius_bottom_right = s.corner_radius_top_right
		draw_style_box(s, doan)
		if w > 44:
			var chu := "%d%%" % gia_tri[i]
			var co := 20
			var tw := font.get_string_size(chu, HORIZONTAL_ALIGNMENT_LEFT, -1, co).x
			var p := Vector2(x + (w - tw) / 2.0, r.position.y + r.size.y / 2.0 + co * 0.36)
			draw_string_outline(font, p, chu, HORIZONTAL_ALIGNMENT_LEFT, -1, co, 6, UIKit.MUC)
			draw_string(font, p, chu, HORIZONTAL_ALIGNMENT_LEFT, -1, co, Color.WHITE)
		x += w
		if not cuoi:
			draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), UIKit.MUC, 4.0)
	var vien := UIKit.hop(Color.TRANSPARENT, 999, 0, 4, 0)
	vien.draw_center = false
	vien.border_color = UIKit.MUC if tong == 100 else UIKit.DO
	draw_style_box(vien, r)
