extends Control

## Bàn party: banner "LƯỢT CỦA BẠN!" + bảng chọn thuế (giữa màn). Chỉ vẽ.
## Thứ tự lượt / sự kiện / túi đồ / gợi ý nằm ở TrangThaiCaNhan.

signal thue_da_chon(loai: int)

const THUE := [["ĐẤT", "dat", "home"], ["MÁU", "mau", "plus"],
		["TIỀN", "tien", "star"], ["TRANG BỊ", "trang_bi", "shoppingBasket"]]

var _id_luot_cu := -1

@onready var _menu_thue: Control = %MenuThue
@onready var _cac_thue: HBoxContainer = %CacThue
@onready var _banner: Label = %Banner


func _ready() -> void:
	visible = false
	_menu_thue.visible = false
	_banner.visible = false
	for i in THUE.size():
		var b := Button.new()
		var nen: Color = UIKit.MAU_O[THUE[i][1]]
		UIKit.the_nut(b, THUE[i][0], THUE[i][2], &"NutTrang", Vector2(150, 150), 64, 24)
		b.add_theme_stylebox_override("normal", UIKit.hop(nen, 22, 6, 4, 12))
		b.add_theme_stylebox_override("hover", UIKit.hop(nen.lightened(0.2), 22, 8, 4, 12))
		b.add_theme_stylebox_override("pressed", UIKit.hop(nen.darkened(0.1), 22, 2, 4, 12))
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
				"icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			b.add_theme_color_override(k, Color.WHITE)
		b.add_theme_color_override("font_outline_color", UIKit.MUC)
		b.add_theme_constant_override("outline_size", 8)
		b.pressed.connect(_chon_thue.bind(i))
		_cac_thue.add_child(b)
		UIKit.gan_phim(b, str(i + 1))
	UIKit.noi_hang(_cac_thue.get_children())


## ⚠️ Khoá các bảng theo người chơi là chuỗi (gói từ JSON).
func cap_nhat(tt: Dictionary) -> void:
	var thu_tu: Array = tt.get("thu_tu", [])
	if thu_tu.is_empty() or int(tt.get("luot", -1)) < 0:
		visible = false
		return
	visible = true

	var id_luot := int(thu_tu[int(tt["luot"])])
	if id_luot != _id_luot_cu:
		_id_luot_cu = id_luot
		if id_luot == NetManager.local_id():
			_bao("LƯỢT CỦA BẠN!")

	var thue: Dictionary = tt.get("thue", {}) as Dictionary
	var mo_thue := not thue.is_empty() and int(thue.get("chu", -1)) == NetManager.local_id()
	if mo_thue and not _menu_thue.visible:
		_menu_thue.visible = true
		UINav.xuat_hien([%TheThue] + _cac_thue.get_children(), 0.05)
		(_cac_thue.get_child(2) as Control).grab_focus()
	elif not mo_thue:
		_menu_thue.visible = false


func _chon_thue(loai: int) -> void:
	_menu_thue.visible = false
	thue_da_chon.emit(loai)


## Banner đập giữa màn rồi tự tắt.
func _bao(chu: String) -> void:
	_banner.text = chu
	_banner.visible = true
	UINav.dap(_banner)
	get_tree().create_timer(1.4).timeout.connect(func():
		if _banner.text == chu:
			_banner.visible = false)
