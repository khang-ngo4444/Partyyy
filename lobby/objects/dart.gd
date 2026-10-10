class_name Dart
extends Pickable

## Phi tiêu: bay bằng vật lý thật, mũi chúc theo hướng bay.
## Trúng bia thì cắm và ghi điểm; trúng thứ khác thì rơi.

const DAI := 0.16
## Độ sâu cắm vào bia.
const CAM_SAU := 0.02
## Lớp va chạm riêng của bia; thân phi tiêu bay xuyên, tia quét mỗi nhịp bắt điểm chạm rồi cắm.
const LOP_BIA := 1 << 2
## Dưới tốc độ này thì thôi xoay mũi theo hướng bay.
const TOC_DO_CHUI_MUI := 0.5

var _truoc := Vector3.ZERO


func _init() -> void:
	mass = 0.03
	nay = 0.1
	ma_sat = 0.8
	gravity_scale = 0.5
	ham_mat_dat = 0.5
	ham_xoay = 0.5
	# Dụng cụ cầm trong tay để ngắm.
	sieu_linh = false
	# Giữa màn hình, cách camera 0.3 m, mũi theo hướng nhìn.
	cam_offset = Vector3(0.0, -0.04, -0.3)
	do_tre_xoay = 0.0


func _ready() -> void:
	super()
	add_to_group("dart")


func _khi_bat_dau_bay() -> void:
	_truoc = global_position


func _khi_bay_vat_ly(_delta: float) -> void:
	var v := linear_velocity
	if v.length() > TOC_DO_CHUI_MUI:
		var huong := v.normalized()
		var len := Vector3.UP if absf(huong.y) < 0.98 else Vector3.FORWARD
		global_transform = Transform3D(Basis.looking_at(huong, len), global_position)
		angular_velocity = Vector3.ZERO
		# Quét từ vị trí nhịp trước tới mũi hiện tại, chỉ trên lớp bia.
		var mui := global_position + huong * DAI * 0.5
		var q := PhysicsRayQueryParameters3D.create(_truoc, mui, LOP_BIA)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			_cam(hit, huong)
			return
	_truoc = global_position


func _cam(hit: Dictionary, huong: Vector3) -> void:
	dinh_co_dinh = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	var tam: Vector3 = hit["position"] - huong * (DAI * 0.5 - CAM_SAU)
	global_transform = Transform3D(global_transform.basis, tam)
	var bia := (hit["collider"] as Node).get_parent() as Dartboard
	if bia != null:
		bia.ghi_diem(nguoi_nem, hit["position"])
