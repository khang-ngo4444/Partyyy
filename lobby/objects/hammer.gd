class_name Hammer
extends Pickable

## Búa đập chuột: nhặt bằng E, thả E là vung (ghi đè `throw()`).
## Máy người cầm tính trúng/trượt rồi RPC cho master cộng điểm; cú vung không đồng bộ.

## Chiều dài cán búa (trục -Z).
const DAI := 0.5
## Chạm chuột ở giữa cú vung.
const GIAY_CHAM := 0.1
const GIAY_VUNG := 0.32
## Góc vác búa lúc cầm thường, độ.
const GOC_VAC := 45.0
## Góc bổ xuống khi vung, độ.
const GOC_VUNG := 85.0

var _vung_tu := -1.0


func _init() -> void:
	mass = 0.4
	nay = 0.2
	ma_sat = 0.8
	ham_mat_dat = 1.0
	ham_xoay = 1.0
	# Dụng cụ cầm trong tay, không siêu linh.
	sieu_linh = false
	# Tay phải, thấp và gần để đầu búa không che giữa màn hình.
	cam_offset = Vector3(0.32, -0.38, -0.3)
	do_tre_xoay = 0.0


func _ready() -> void:
	super()
	add_to_group("hammer")


## Ghi đè Pickable: không ném, thả E là vung.
func throw(_huong: Vector3, _toc_do: float) -> void:
	if _vung_tu >= 0.0:
		return
	_vung_tu = _gio()
	var may := get_tree().get_first_node_in_group("whack_a_mole") as WhackAMole
	var nguoi := _find_player(holder_id)
	if may == null or nguoi == null:
		return
	# Ngắm bằng tia nhìn, không bằng đầu búa (tay chỉ với ~0.6 m).
	var mat := nguoi.diem_cam(Vector3.ZERO)
	await get_tree().create_timer(GIAY_CHAM).timeout
	if is_instance_valid(may):
		may.thu_dap(mat.origin, -mat.basis.z, holder_id)


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


func _dau_bua() -> Vector3:
	return global_transform * Vector3(0.0, 0.0, -DAI * 0.5)


## Cú vung chỉ là hình: quay búa sau khi `_theo_tay` đặt vào tay.
func _theo_tay(delta: float) -> bool:
	if not super(delta):
		return false
	# Lúc thường vác búa lên cho khỏi che con chuột.
	var goc := deg_to_rad(GOC_VAC)
	if _vung_tu >= 0.0:
		var t := (_gio() - _vung_tu) / GIAY_VUNG
		if t >= 1.0:
			_vung_tu = -1.0
		else:
			# Bổ xuống nhanh rồi kéo lên chậm.
			goc -= deg_to_rad(GOC_VUNG) * sin(PI * minf(t * 1.4, 1.0))
	global_transform = Transform3D(global_transform.basis.rotated(global_transform.basis.x, goc),
			global_position)
	return true
