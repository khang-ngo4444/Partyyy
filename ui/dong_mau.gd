class_name DongMau
extends HBoxContainer

## Một dòng bảng máu: màu nhân vật, tên, máu, vàng, Cúp.

@onready var _mau_nv: ColorRect = $MauNhanVat
@onready var _ten: Label = $Ten
@onready var _thanh: ProgressBar = $Thanh
@onready var _so: Label = $So
@onready var _vang: Label = $Vang
@onready var _coc: Label = $SoCoc


func dat(ten: String, mau: Color, hien_tai: int, toi_da: int, vang: int, coc: int,
		la_toi: bool, dang_luot: bool) -> void:
	_mau_nv.color = mau
	_ten.text = ("▶ " if dang_luot else "") + ten + (" (bạn)" if la_toi else "")
	_thanh.max_value = maxi(toi_da, 1)
	_thanh.value = hien_tai
	_so.text = "%d/%d" % [hien_tai, toi_da]
	_vang.text = str(vang)
	_coc.text = str(coc)
