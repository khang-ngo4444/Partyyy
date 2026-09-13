class_name Putter
extends Pickable

## Gay golf. Giu E nap luc, tha E la VUT — gay khong bay di, no danh qua bong nam truoc mat.
## Ghi de `throw()` giong cai bua, nen khong phai them phim moi vao Player.
##
## Luc danh lay tu chinh thanh nap luc san co: nap day (15 m/s) ra bong di ~6.7 m/s.

const DAI := 0.95
## Bong nam trong tam nay truoc mat nguoi cam thi vut trung.
const TAM_VUT := 1.0
## Doi bao lau ke tu luc bat dau vung moi cham bong.
const GIAY_CHAM := 0.12
const GIAY_VUT := 0.35
## Doi luc nem (3..15 m/s) ra luc danh bong.
const HE_SO_LUC := 0.32
const TOC_DO_MIN := 1.0
const TOC_DO_MAX := 5.0
## Goc cam gay luc thuong va goc vung (do).
const GOC_CAM := 35.0
const GOC_VUT := 70.0

var _vut_tu := -1.0


func _init() -> void:
	mass = 0.4
	nay = 0.1
	ma_sat = 0.8
	ham_mat_dat = 1.0
	ham_xoay = 1.0
	# Dung cu: nam dung trong tay, khong lo lung sieu linh.
	sieu_linh = false
	cam_offset = Vector3(0.3, -0.5, -0.35)


func _ready() -> void:
	super()
	add_to_group("putter")
	var hop := BoxShape3D.new()
	hop.size = Vector3(0.1, 0.1, DAI)
	_dat_hinh(hop)


## Ghi de Pickable: gay khong bay, tha E la vut bong.
func throw(_huong: Vector3, toc_do: float) -> void:
	if _vut_tu >= 0.0:
		return
	_vut_tu = _gio()
	var san := get_tree().get_first_node_in_group("mini_golf") as MiniGolf
	var nguoi := _find_player(holder_id)
	if san == null or nguoi == null:
		return
	var mat := nguoi.diem_cam(Vector3.ZERO)
	var huong := -mat.basis.z
	huong.y = 0.0
	huong = huong.normalized()
	var luc: float = clampf(toc_do * HE_SO_LUC, TOC_DO_MIN, TOC_DO_MAX)
	var cho_dung := nguoi.global_position
	await get_tree().create_timer(GIAY_CHAM).timeout
	if is_instance_valid(san):
		san.vut(cho_dung, huong, luc, holder_id)


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


func _theo_tay(delta: float) -> bool:
	if not super(delta):
		return false
	var goc := deg_to_rad(GOC_CAM)
	if _vut_tu >= 0.0:
		var t := (_gio() - _vut_tu) / GIAY_VUT
		if t >= 1.0:
			_vut_tu = -1.0
		else:
			goc -= deg_to_rad(GOC_VUT) * sin(PI * minf(t * 1.4, 1.0))
	global_transform = Transform3D(global_transform.basis.rotated(global_transform.basis.x, goc),
			global_position)
	return true
