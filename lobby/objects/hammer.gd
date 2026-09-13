class_name Hammer
extends Pickable

## Bua dap chuot. Nhat bang E nhu moi vat khac, nhung THA E LA VUNG BUA chu khong nem di —
## ghi de `throw()` nen khong phai them phim moi vao Player.
##
## Chi may cua NGUOI DANG CAM tinh trung/truot (may do moi biet bua dang o dau theo camera cua
## ho), roi gui RPC cho master cong diem. Cu vung la mot SU KIEN, khong phai trang thai, nen
## khong dong bo goc quay cua cu vung — may khac van thay bua di theo tay.

## Can bua dai bao nhieu (theo truc -Z, dung huong nhin).
const DAI := 0.5
## Cham chuot o giua cu vung, khong phai luc vua bam.
const GIAY_CHAM := 0.1
const GIAY_VUNG := 0.32
## Goc vac bua luc cam thuong (do, duong = dau bua chech len).
const GOC_VAC := 45.0
## Goc bo tu vai xuong khi vung (do).
const GOC_VUNG := 85.0

var _vung_tu := -1.0


func _init() -> void:
	mass = 0.4
	nay = 0.2
	ma_sat = 0.8
	ham_mat_dat = 1.0
	ham_xoay = 1.0
	# Dung cu: nam dung trong tay, khong lo lung sieu linh — cu vung can bua o dung cho.
	sieu_linh = false
	# Tay phai, thap va gan hon: bua vac len nen dau bua khong che mat giua man hinh.
	cam_offset = Vector3(0.32, -0.38, -0.3)
	do_tre_xoay = 0.0


func _ready() -> void:
	super()
	add_to_group("hammer")
	_build()
	var hop := BoxShape3D.new()
	hop.size = Vector3(0.14, 0.14, DAI)
	_dat_hinh(hop)


## Ghi de Pickable: bua khong bay di, tha E la vung.
func throw(_huong: Vector3, _toc_do: float) -> void:
	if _vung_tu >= 0.0:
		return
	_vung_tu = _gio()
	var may := get_tree().get_first_node_in_group("whack_a_mole") as WhackAMole
	var nguoi := _find_player(holder_id)
	if may == null or nguoi == null:
		return
	# Ngam bang tia nhin cua nguoi cam, khong phai vi tri dau bua: tay chi voi toi ~0.6 m.
	var mat := nguoi.diem_cam(Vector3.ZERO)
	await get_tree().create_timer(GIAY_CHAM).timeout
	if is_instance_valid(may):
		may.thu_dap(mat.origin, -mat.basis.z, holder_id)


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


func _dau_bua() -> Vector3:
	return global_transform * Vector3(0.0, 0.0, -DAI * 0.5)


## Cu vung chi la hinh: quay bua quanh chinh no ngay sau khi `_theo_tay` dat bua vao tay.
func _theo_tay(delta: float) -> bool:
	if not super(delta):
		return false
	# Luc thuong: VAC bua len — de nguyen theo huong nhin thi dau bua nam chinh giua man hinh,
	# che mat con chuot dang ngam.
	var goc := deg_to_rad(GOC_VAC)
	if _vung_tu >= 0.0:
		var t := (_gio() - _vung_tu) / GIAY_VUNG
		if t >= 1.0:
			_vung_tu = -1.0
		else:
			# Bo xuong nhanh roi keo len cham.
			goc -= deg_to_rad(GOC_VUNG) * sin(PI * minf(t * 1.4, 1.0))
	global_transform = Transform3D(global_transform.basis.rotated(global_transform.basis.x, goc),
			global_position)
	return true


func _build() -> void:
	var go := StandardMaterial3D.new()
	go.albedo_color = Color("8a5a3b")
	var dau := StandardMaterial3D.new()
	dau.albedo_color = Color("e5484d")
	var vanh := StandardMaterial3D.new()
	vanh.albedo_color = Color("f2efe6")

	var can := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.022
	cm.bottom_radius = 0.026
	cm.height = DAI * 0.78
	can.mesh = cm
	can.material_override = go
	can.rotation_degrees.x = 90.0
	can.position.z = DAI * 0.5 - cm.height * 0.5
	add_child(can)

	var bua := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.075
	bm.bottom_radius = 0.075
	bm.height = 0.2
	bua.mesh = bm
	bua.material_override = dau
	bua.rotation_degrees.z = 90.0
	bua.position.z = -DAI * 0.5 + 0.05
	add_child(bua)

	for s in [-1.0, 1.0]:
		var nap := MeshInstance3D.new()
		var nm := CylinderMesh.new()
		nm.top_radius = 0.078
		nm.bottom_radius = 0.078
		nm.height = 0.02
		nap.mesh = nm
		nap.material_override = vanh
		nap.rotation_degrees.z = 90.0
		nap.position = Vector3(s * 0.1, 0.0, -DAI * 0.5 + 0.05)
		add_child(nap)
