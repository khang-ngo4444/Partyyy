class_name OTrangBi
extends PanelContainer

## Một ô thanh trang bị: phím số, icon, tên.

@export var danh_muc: DanhMucVatPham = null

var _vien: StyleBoxFlat = null

@onready var _phim: Label = $Cot/Phim
@onready var _hinh: TextureRect = $Cot/Hinh
@onready var _ten: Label = $Cot/Ten


func dat(so: int, mon: String, chon: bool, duoc_dung: bool) -> void:
	if _vien == null:
		_vien = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
		add_theme_stylebox_override("panel", _vien)
	_phim.text = str(so)
	var hinh := danh_muc.tim(mon) if danh_muc != null else null
	_hinh.texture = hinh.icon if hinh != null else null
	_ten.text = VatPham.ten(mon) + (" · tự động" if mon == "khien" else "")
	_vien.border_color = Color(1.0, 0.85, 0.3) if chon else Color(0.25, 0.78, 0.91, 0.5)
	_vien.set_border_width_all(3 if chon else 1)
	modulate.a = 1.0 if duoc_dung or mon == "khien" else 0.6
