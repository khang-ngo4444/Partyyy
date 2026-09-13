class_name GolfBall
extends Pickable

## Bong golf. Nho, nhe, lan xa — gay putter danh vao (xem Putter), khong nem bang tay.

const BAN_KINH := 0.032


func _init() -> void:
	mass = 0.05
	nay = 0.35
	ma_sat = 0.4
	# Lan tren co: ham vua du de bong dung lai sau vai met, khong lan mai.
	ham_mat_dat = 0.55
	ham_xoay = 0.5
	cam_offset = Vector3(0.18, -0.22, -0.35)


func _ready() -> void:
	super()
	add_to_group("golf_ball")
