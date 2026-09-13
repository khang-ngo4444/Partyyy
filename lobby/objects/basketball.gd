class_name Basketball
extends Pickable

## Qua bong ro. Nhat len, giu E nap luc, tha E nem — bay va nay bang vat ly that.
##
## Hinh bong: node `Model` trong basketball.tscn (glb gop bong + ro, `ring` an, chi hien `Sphere`).
## Bong ro that ~0.24 m duong kinh. Hinh va cham: node `HinhVaCham`.


func _init() -> void:
	mass = 0.6
	nay = 0.7
	ma_sat = 0.6
	ham_mat_dat = 0.8
	ham_xoay = 0.3
	# Tay phai, duoi man hinh, cach camera ~0.5 m. Xoay duoi theo camera — qua bong trong tay.
	cam_offset = Vector3(0.22, -0.2, -0.43)
	do_tre_xoay = 8.0


func _ready() -> void:
	super()
	add_to_group("basketball")
