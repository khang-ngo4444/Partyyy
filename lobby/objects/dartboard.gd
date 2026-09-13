class_name Dartboard
extends Node3D

## Bia phi tiêu trên giá đứng, có vạch ném 2.37 m và bảng điểm.
##
## Mặt bia quay về +Z. Gốc node dưới chân giá.
##
## Tính điểm theo KÍCH THƯỚC BIA THẬT (đường kính 45 cm, vòng tính điểm 34 cm): tâm 50, vòng
## ngoài tâm 25, vòng ba nhân 3, vòng ngoài cùng nhân 2, 20 ô số theo đúng thứ tự bia thật.
## ponytail: vòng sơn trên model có thể không trùng tuyệt đối tỉ lệ bia thật — chỗ nào lệch
## thì sửa bán kính trong `diem_tai`, không phải sửa model.

const DUONG_KINH := 0.45
const TAM_CAO := 1.5
const VACH_NEM := 2.37
## Thứ tự số trên bia, theo chiều kim đồng hồ, bắt đầu từ ô thẳng đứng phía trên.
const SO := [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

var _tong: Dictionary = {}
var _bang: Label3D


func _ready() -> void:
	add_to_group("dartboard")
	Fusion.register_broadcast_receiver(self)
	_build()


## Điểm tại một điểm chạm (toạ độ thế giới). Trả [điểm, tên ô].
func diem_tai(diem_cham: Vector3) -> Array:
	var p := to_local(diem_cham)
	var dx := p.x
	var dy := p.y - TAM_CAO
	var r := sqrt(dx * dx + dy * dy)
	if r <= 0.00635:
		return [50, "TAM 50"]
	if r <= 0.0159:
		return [25, "25"]
	if r > 0.170:
		return [0, "NGOAI BIA"]
	var goc := fposmod(rad_to_deg(atan2(dx, dy)) + 9.0, 360.0)
	var so: int = SO[int(goc / 18.0) % 20]
	if r >= 0.099 and r <= 0.107:
		return [so * 3, "T%d = %d" % [so, so * 3]]
	if r >= 0.162:
		return [so * 2, "D%d = %d" % [so, so * 2]]
	return [so, "%d" % so]


## Master gọi khi một cây phi tiêu cắm vào bia.
func ghi_diem(nguoi: int, diem_cham: Vector3) -> void:
	if not NetManager.is_master():
		return
	var kq := diem_tai(diem_cham)
	_tong[nguoi] = int(_tong.get(nguoi, 0)) + int(kq[0])
	var goi: PackedStringArray = []
	for k in _tong:
		goi.append("%d:%d" % [k, _tong[k]])
	Fusion.rpc(_net_phi_tieu, nguoi, String(kq[1]), ",".join(goi))


@rpc("any_peer", "call_local")
func _net_phi_tieu(nguoi: int, o: String, tong: String) -> void:
	var dong: PackedStringArray = ["PHI TIEU", "%s: %s" % [Player.ten_theo_id(get_tree(), nguoi), o]]
	for cap in tong.split(",", false):
		var ab := cap.split(":")
		if ab.size() == 2:
			dong.append("%s  %s" % [Player.ten_theo_id(get_tree(), int(ab[0])), ab[1]])
	_bang.text = "
".join(dong)


func _build() -> void:
	var go := StandardMaterial3D.new()
	go.albedo_color = Color("6b4a2f")
	go.roughness = 0.85
	# Giá đứng: đế + trụ sau bia. Có va chạm thường (lớp 1) để người không đi xuyên.
	# Va chạm giá: node StaticSurface_Stand trong dartboard.tscn.
	_hop(Vector3(0.6, 0.04, 0.45), Vector3(0, 0.02, -0.1), go)
	_hop(Vector3(0.08, TAM_CAO + 0.25, 0.08), Vector3(0, (TAM_CAO + 0.25) * 0.5, -0.08), go)
	_hop(Vector3(0.52, 0.52, 0.03), Vector3(0, TAM_CAO, -0.035), go)

	# Mặt bia để phi tiêu cắm: node StaticSurface_Target (CHỈ lớp 3 = Dart.LOP_BIA, mask 0) trong scene.

	# Vạch ném trên sàn.
	var vach := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.9, 0.006, 0.05)
	vach.mesh = vm
	var trang := StandardMaterial3D.new()
	trang.albedo_color = Color("f2efe6")
	vach.material_override = trang
	vach.position = Vector3(0, 0.003, VACH_NEM)
	add_child(vach)
	var chu := Label3D.new()
	chu.text = "VACH NEM"
	chu.font_size = 28
	chu.pixel_size = 0.002
	chu.outline_size = 8
	chu.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	chu.position = Vector3(0, 0.25, VACH_NEM)
	add_child(chu)

	_bang = Label3D.new()
	_bang.text = "PHI TIEU
đứng sau vạch, giữ E rồi thả để ném"
	_bang.font_size = 36
	_bang.pixel_size = 0.0028
	_bang.outline_size = 10
	_bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bang.position = Vector3(0, TAM_CAO + 0.65, 0)
	add_child(_bang)


func _hop(kt: Vector3, vt: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = kt
	mi.mesh = bm
	mi.material_override = mat
	mi.position = vt
	add_child(mi)
