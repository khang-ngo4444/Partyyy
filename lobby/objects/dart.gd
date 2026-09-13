class_name Dart
extends Pickable

## Phi tieu. Bay bang vat ly that (nhe, trong luc thap), mui luon chui theo huong bay.
## Trung bia thi CAM lai va ghi diem; trung thu khac thi roi xuong, nhat lai duoc.
##
## Dung bang khoi co ban, KHONG dung model "Darts by Jarlan Perez": do ra file do la CA BO
## may cay nam cheo nhau (dai 0.69, rong 0.57 don vi) — moi vat nhat len la mot chum phi tieu,
## va khong co truc mui nao de chia theo huong bay.

const DAI := 0.16
## Cam vao bia sau chung nay.
const CAM_SAU := 0.02
## Bia nam tren lop va cham RIENG (lop 3). Than phi tieu khong va voi lop do — no bay XUYEN
## qua bia ve mat vat ly, con tia quet moi nhip bat diem cham roi cam lai. De va cham that
## thi phi tieu nay khoi bia truoc khi kip cam.
const LOP_BIA := 1 << 2
## Duoi toc do nay thi thoi xoay mui theo huong bay (dang nam tren san).
const TOC_DO_CHUI_MUI := 0.5

var _truoc := Vector3.ZERO


func _init() -> void:
	mass = 0.03
	nay = 0.1
	ma_sat = 0.8
	gravity_scale = 0.5
	ham_mat_dat = 0.5
	ham_xoay = 0.5
	# Dung cu: phi tieu phai nam dung truoc mat de ngam, khong lo lung sieu linh.
	sieu_linh = false
	# Giua man hinh, cach camera 0.3 m, mui khop dung huong nhin — cam phi tieu ngam.
	cam_offset = Vector3(0.0, -0.04, -0.3)
	do_tre_xoay = 0.0


func _ready() -> void:
	super()
	add_to_group("dart")
	_build()


func _khi_bat_dau_bay() -> void:
	_truoc = global_position


func _khi_bay_vat_ly(_delta: float) -> void:
	var v := linear_velocity
	if v.length() > TOC_DO_CHUI_MUI:
		var huong := v.normalized()
		var len := Vector3.UP if absf(huong.y) < 0.98 else Vector3.FORWARD
		global_transform = Transform3D(Basis.looking_at(huong, len), global_position)
		angular_velocity = Vector3.ZERO
		# Quet tu vi tri nhip truoc toi MUI hien tai, chi tren lop bia.
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


## Mui chia ve -Z cua node — cung chieu "phia truoc" cua Godot, nen `looking_at` la du.
func _build() -> void:
	var kim := StandardMaterial3D.new()
	kim.albedo_color = Color("c9ccd2")
	kim.metallic = 0.8
	kim.roughness = 0.3
	var than_mat := StandardMaterial3D.new()
	than_mat.albedo_color = Color("2b2d33")
	var canh := StandardMaterial3D.new()
	canh.albedo_color = Color("e5484d")
	canh.cull_mode = BaseMaterial3D.CULL_DISABLED

	_khoi(_tru(0.0015, 0.0005, 0.035), kim, Vector3(0, 0, -DAI * 0.5 + 0.0175), 90.0)
	_khoi(_tru(0.006, 0.006, 0.045), than_mat, Vector3(0, 0, -DAI * 0.5 + 0.057), 90.0)
	_khoi(_tru(0.0022, 0.0022, 0.06), than_mat, Vector3(0, 0, DAI * 0.5 - 0.045), 90.0)
	for goc in [0.0, 90.0]:
		var q := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.045, 0.001, 0.04)
		q.mesh = bm
		q.material_override = canh
		q.position = Vector3(0, 0, DAI * 0.5 - 0.02)
		q.rotation_degrees.z = goc
		add_child(q)


func _tru(r_tren: float, r_duoi: float, cao: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = r_tren
	cm.bottom_radius = r_duoi
	cm.height = cao
	return cm


func _khoi(m: Mesh, mat: Material, vt: Vector3, xoay_x: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = vt
	mi.rotation_degrees.x = xoay_x
	add_child(mi)
