class_name DongMau
extends PanelContainer

## Một dòng bảng máu: chấm màu nhân vật, tên, thanh máu, vàng, Cúp.
## Dòng của mình nền vàng; người đang tới lượt viền cam + mũi tên.

var _vang_cu := -1
var _coc_cu := -1

@onready var _mau_nv: Panel = %MauNhanVat
@onready var _ten: Label = %Ten
@onready var _thanh: ProgressBar = %Thanh
@onready var _so: Label = %So
@onready var _vang: Label = %Vang
@onready var _coc: Label = %SoCoc


func dat(ten: String, mau: Color, hien_tai: int, toi_da: int, vang: int, coc: int,
		la_toi: bool, dang_luot: bool) -> void:
	_mau_nv.add_theme_stylebox_override("panel", UIKit.hop(mau, 999, 0, 3, 0))
	_ten.text = ("▶ " if dang_luot else "") + ten + (" (bạn)" if la_toi else "")
	_thanh.max_value = maxi(toi_da, 1)
	_thanh.value = hien_tai
	_so.text = "%d/%d" % [hien_tai, toi_da]
	_vang.text = str(vang)
	_coc.text = str(coc)
	# Số đổi thì nảy cho dễ thấy.
	if _vang_cu >= 0 and vang != _vang_cu:
		UINav.nay(_vang.get_parent(), 1.3)
	if _coc_cu >= 0 and coc != _coc_cu:
		UINav.nay(_coc.get_parent(), 1.4)
	_vang_cu = vang
	_coc_cu = coc
	var nen := Color("FFF1B8") if la_toi else Color.WHITE
	var s := UIKit.hop(nen, 14, 3 if dang_luot else 0, 3, 6)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.border_color = UIKit.CAM if dang_luot else Color(UIKit.MUC, 0.25)
	if dang_luot:
		s.set_border_width_all(4)
	add_theme_stylebox_override("panel", s)
