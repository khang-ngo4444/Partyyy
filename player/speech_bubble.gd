class_name SpeechBubble
extends Node3D

## Bong bóng chat trên đầu nhân vật (mỗi máy tự vẽ). Nền theo màu nhân vật, chữ tự chọn
## đen/trắng. Cả cụm quay theo camera; khung bóng ghép mesh theo cỡ chữ (`SurfaceTool`).

enum Kieu { VUONG, TRON, MAY, GAI }

## Tên kiểu (thứ tự khớp enum).
const TEN_KIEU := ["Vuông", "Tròn", "Đám mây", "Gai"]

## Giữ bao lâu trước khi mờ đi (giây).
const GIU := 6.0
const MO := 0.5
## Độ dày viền tối quanh bóng (mét).
const DAY_VIEN := 0.035
const MAU_VIEN := Color(0.06, 0.06, 0.09)
## Đệm quanh chữ (mét).
const DEM := Vector2(0.15, 0.10)
## Độ dài đuôi nhọn.
const DUOI := 0.18
## Nền sáng hơn ngưỡng này thì chữ đen.
const NGUONG_SANG := 0.5

## Chat đặt theo `Player.bubble_shape` trước khi `noi()`.
var kieu := Kieu.VUONG
## Chat đặt theo màu nhân vật.
var mau := Color("e5e5e5")
var _tween: Tween
## SurfaceTool đang ghép mesh (trong `_ve_hinh`).
var _ghep: SurfaceTool = null

@onready var _chu: Label3D = $Chu
@onready var _nen: MeshInstance3D = $Nen
@onready var _vien: MeshInstance3D = $Vien
@onready var _mat_nen := _nen.material_override as StandardMaterial3D
@onready var _mat_vien := _vien.material_override as StandardMaterial3D


## Chép hướng camera để cả cụm không nghiêng.
func _process(_delta: float) -> void:
	if not visible:
		return
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		global_basis = cam.global_basis


func noi(text: String) -> void:
	_chu.text = text
	visible = false
	if _tween != null:
		_tween.kill()

	# Label3D cập nhật cỡ chữ ở khung sau — chờ một khung rồi mới đo.
	await get_tree().process_frame
	if not is_instance_valid(self) or _chu.text != text:
		return  # có tin mới hơn chen vào

	_dung_nen(_chu.get_aabb().size)
	_ap_mau()
	_dat_alpha(1.0)
	visible = true
	_tween = create_tween()
	_tween.tween_interval(GIU)
	_tween.tween_method(_dat_alpha, 1.0, 0.0, MO)
	_tween.tween_callback(hide)


## Chữ và viền tương phản với nền.
func _ap_mau() -> void:
	var sang := mau.get_luminance() > NGUONG_SANG
	_chu.modulate = Color(0.05, 0.05, 0.07) if sang else Color.WHITE
	_chu.outline_modulate = Color.WHITE if sang else Color(0.04, 0.04, 0.06)
	_mat_nen.albedo_color = mau
	_mat_vien.albedo_color = MAU_VIEN


func _dat_alpha(a: float) -> void:
	_mat_nen.albedo_color = Color(mau, a)
	_mat_vien.albedo_color = Color(MAU_VIEN, a)
	_chu.modulate.a = a
	_chu.outline_modulate.a = a


## Dựng khung ôm hộp chữ `kt`; gốc cụm nằm ở mũi đuôi.
func _dung_nen(kt: Vector3) -> void:
	# Vẽ hai lớp: viền to hơn ở dưới, nền ở trên.
	_vien.mesh = _ve_hinh(kt, DAY_VIEN)
	_nen.mesh = _ve_hinh(kt, 0.0)


func _ve_hinh(kt: Vector3, no: float) -> ArrayMesh:
	_ghep = SurfaceTool.new()
	_ghep.begin(Mesh.PRIMITIVE_TRIANGLES)

	var w := kt.x + DEM.x * 2.0 + no * 2.0
	var h := kt.y + DEM.y * 2.0 + no * 2.0
	var y := DUOI + (kt.y + DEM.y * 2.0) * 0.5
	_chu.position = Vector3(0.0, y, 0.012)

	match kieu:
		Kieu.TRON:
			# Elip đủ to để chứa bốn góc chữ.
			_dia(w * 0.62, h * 0.70, Vector3(0.0, y, 0.0))
			_duoi_nhon(y - h * 0.42)
		Kieu.MAY:
			_quad(Vector2(w * 0.86, h * 0.74), Vector3(0.0, y, 0.0))
			var r := h * 0.36
			var n := maxi(3, int(w / (r * 1.4)))
			for i in n:
				var x := -w * 0.43 + w * 0.86 * i / float(n - 1)
				_dia(r, r, Vector3(x, y + h * 0.35, 0.0))
				_dia(r, r, Vector3(x, y - h * 0.35, 0.0))
			_dia(h * 0.32, h * 0.32, Vector3(-w * 0.44, y, 0.0))
			_dia(h * 0.32, h * 0.32, Vector3(w * 0.44, y, 0.0))
			# Đuôi kiểu "nghĩ": hai bong tròn nhỏ dần.
			_dia(0.055, 0.055, Vector3(0.03, DUOI * 0.7, 0.0))
			_dia(0.032, 0.032, Vector3(-0.01, DUOI * 0.25, 0.0))
		Kieu.GAI:
			_sao(w * 0.74, h * 0.82, Vector3(0.0, y, 0.0))
			_duoi_nhon(y - h * 0.40)
		_:
			_quad(Vector2(w, h), Vector3(0.0, y, 0.0))
			_duoi_nhon(y - h * 0.5)
	return _ghep.commit()


## Đĩa elip: hình trụ dẹt xoay 90° quanh X.
func _dia(rx: float, ry: float, pos: Vector3) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.004
	cm.radial_segments = 24
	cm.rings = 0
	_them(cm, Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(rx, 1.0, ry)),
			pos))


func _quad(co: Vector2, pos: Vector3) -> void:
	var qm := QuadMesh.new()
	qm.size = co
	_them(qm, Transform3D(Basis.IDENTITY, pos))


## Ngôi sao 7 cánh (bóng "hét").
func _sao(rx: float, ry: float, pos: Vector3) -> void:
	var canh := 7
	var diem := PackedVector3Array()
	for i in canh * 2:
		var a := TAU * i / float(canh * 2) + PI * 0.5
		var k := 1.0 if i % 2 == 0 else 0.62
		diem.append(Vector3(cos(a) * rx * k, sin(a) * ry * k, 0.0))
	_da_giac(diem, pos)


## Tam giác từ đáy bóng chụm xuống đỉnh đầu.
func _duoi_nhon(tren: float) -> void:
	_da_giac(PackedVector3Array([
		Vector3(-0.10, tren, 0.0),
		Vector3(0.07, tren, 0.0),
		Vector3(0.0, 0.0, 0.0),
	]), Vector3.ZERO)


## Đa giác lồi phẳng (quạt tam giác từ trọng tâm).
func _da_giac(diem: PackedVector3Array, pos: Vector3) -> void:
	var tam := Vector3.ZERO
	for p in diem:
		tam += p
	tam /= diem.size()

	var dinh := PackedVector3Array()
	for i in diem.size():
		dinh.append(tam)
		dinh.append(diem[i])
		dinh.append(diem[(i + 1) % diem.size()])

	var mang := []
	mang.resize(Mesh.ARRAY_MAX)
	mang[Mesh.ARRAY_VERTEX] = dinh
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mang)
	_them(am, Transform3D(Basis.IDENTITY, pos))


func _them(luoi: Mesh, dat: Transform3D) -> void:
	_ghep.append_from(luoi, 0, dat)
