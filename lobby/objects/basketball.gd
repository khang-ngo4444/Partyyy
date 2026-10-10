class_name Basketball
extends Pickable

## Quả bóng rổ: nhặt lên, giữ E nạp lực, thả E ném.


func _init() -> void:
	mass = 0.6
	nay = 0.7
	ma_sat = 0.6
	ham_mat_dat = 0.8
	ham_xoay = 0.3
	# Tay phải, dưới màn hình, cách camera ~0.5 m.
	cam_offset = Vector3(0.22, -0.2, -0.43)
	do_tre_xoay = 8.0


func _ready() -> void:
	super()
	add_to_group("basketball")
