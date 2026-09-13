class_name BasketballCourt
extends Node3D

## NỬA sân bóng rổ 3 × 2 m, có rổ ở đường biên cuối, có va chạm để đứng.
##
## Dựng bằng khối cơ bản thay cho model sân nguyên: model đó là sân ĐẦY ĐỦ tỉ lệ 28 × 15 —
## cắt đôi ra vẫn không thành 3 × 2, và nó to 10 m chiếm cả lối đi giữa hai bàn bài.
##
## Gốc node ở GIỮA đường biên cuối. Sân trải về +Z (x từ −1.5 tới 1.5, z từ 0 tới 2), rổ đứng
## trên đường biên quay mặt vào sân.

@export var rong := 3.0
@export var sau := 2.0

const MAU_SAN := Color("c68b4e")
const MAU_KE := Color("3e63dd")
const MAU_VACH := Color("f2efe6")
const DAY_VACH := 0.04
## Chân bảng rổ cách đường biên cuối.
const RO_CACH_BIEN := 0.1  # phải khớp vị trí node Hoop trong basketball_court.tscn

## Rổ: node `Hoop` trong basketball_court.tscn.
@onready var ro: BasketballHoop = $Hoop


func _ready() -> void:
	_build()


## Chỗ để sẵn quả bóng thứ i: trên sân, gần đầu sân phía xa rổ.
func cho_bong(i: int) -> Vector3:
	return to_global(Vector3(-0.4 + 0.8 * i, 0.01 + Basketball.TARGET_DIAMETER * 0.5, sau - 0.3))


func _build() -> void:
	# Mặt sân nhô 1 cm khỏi sàn phòng — trùng mặt sàn thì hai mặt giành nhau từng pixel.
	var nen := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(rong, 0.02, sau)
	nen.mesh = nm
	nen.material_override = _mat(MAU_SAN)
	nen.position = Vector3(0, 0.0, sau * 0.5)
	add_child(nen)

	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(rong, 0.02, sau)
	cs.shape = bs
	cs.position = nen.position
	body.add_child(cs)
	add_child(body)

	# Khu cấm địa sơn xanh.
	_vach(Vector3(0.9, 0.003, 1.2), Vector3(0, 0.011, 0.6), MAU_KE)
	# Viền sân.
	_vach(Vector3(rong, 0.004, DAY_VACH), Vector3(0, 0.012, DAY_VACH * 0.5), MAU_VACH)
	_vach(Vector3(rong, 0.004, DAY_VACH), Vector3(0, 0.012, sau - DAY_VACH * 0.5), MAU_VACH)
	_vach(Vector3(DAY_VACH, 0.004, sau), Vector3(-rong * 0.5 + DAY_VACH * 0.5, 0.012, sau * 0.5), MAU_VACH)
	_vach(Vector3(DAY_VACH, 0.004, sau), Vector3(rong * 0.5 - DAY_VACH * 0.5, 0.012, sau * 0.5), MAU_VACH)
	_vong_3_diem()


## Vạch 3 điểm: nửa vòng tròn tâm vành rổ, cộng hai đoạn thẳng xuống đường biên.
func _vong_3_diem() -> void:
	var tam_z := RO_CACH_BIEN + BasketballHoop.VANH_CACH_BANG
	var r := BasketballHoop.BAN_KINH_3_DIEM
	var trong := r - DAY_VACH * 0.5
	var ngoai := r + DAY_VACH * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	for i in n:
		var a0 := PI * i / n
		var a1 := PI * (i + 1) / n
		var p := [
			Vector3(cos(a0) * trong, 0, tam_z + sin(a0) * trong),
			Vector3(cos(a0) * ngoai, 0, tam_z + sin(a0) * ngoai),
			Vector3(cos(a1) * ngoai, 0, tam_z + sin(a1) * ngoai),
			Vector3(cos(a1) * trong, 0, tam_z + sin(a1) * trong),
		]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.add_vertex(p[k])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := _mat(MAU_VACH)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position.y = 0.013
	add_child(mi)
	for x in [-r, r]:
		_vach(Vector3(DAY_VACH, 0.004, tam_z), Vector3(x, 0.012, tam_z * 0.5), MAU_VACH)


func _vach(kt: Vector3, vt: Vector3, mau: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = kt
	mi.mesh = bm
	mi.material_override = _mat(mau)
	mi.position = vt
	add_child(mi)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m
