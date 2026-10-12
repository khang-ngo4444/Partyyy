class_name OTrangBi
extends PanelContainer

## Một ô thanh dùng nhanh: huy hiệu phím số, icon, tên. Ô trống vẫn vẽ khung mờ.
## Đang chọn = nền vàng viền cam.

@export var danh_muc: DanhMucVatPham = null

@onready var _phim: Label = %Phim
@onready var _hinh: TextureRect = %Hinh
@onready var _ten: Label = %Ten

var _chon_cu := false


func dat(so: int, mon: String, chon: bool, duoc_dung: bool) -> void:
	_phim.text = str(so)
	var trong := mon.is_empty()
	var hinh := danh_muc.tim(mon) if danh_muc != null and not trong else null
	_hinh.texture = hinh.icon if hinh != null else null
	_ten.text = "" if trong else VatPham.ten(mon) + (" · tự động" if mon == "khien" else "")
	var s: StyleBoxFlat
	if trong:
		s = UIKit.hop(Color("F3E3BC"), 16, 0, 3, 6)
		s.border_color = Color(UIKit.MUC, 0.3)
	else:
		s = UIKit.hop(UIKit.VANG if chon else Color.WHITE, 16, 2 if chon else 5, 4, 6)
		if chon:
			s.border_color = UIKit.CAM
			s.set_border_width_all(5)
	add_theme_stylebox_override("panel", s)
	modulate.a = 1.0 if trong or duoc_dung or mon == "khien" else 0.55
	if chon and not _chon_cu:
		UINav.nay(self, 1.15)
	_chon_cu = chon
