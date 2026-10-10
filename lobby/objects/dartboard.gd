class_name Dartboard
extends Node3D

## Bia phi tiêu trên giá (mặt +Z, gốc dưới chân), vạch ném 2.37 m, tính điểm theo cỡ bia thật.
## ponytail: vòng sơn trên model có thể lệch tỉ lệ thật — sửa bán kính trong `diem_tai`.

const DUONG_KINH := 0.45
const TAM_CAO := 1.5
## Số trên bia theo chiều kim đồng hồ, từ ô trên cùng.
const SO := [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

var _tong: Dictionary = {}

## Giá, vạch ném, bảng điểm dựng sẵn trong dartboard.tscn.
@onready var _bang: Label3D = $Bang


func _ready() -> void:
	add_to_group("dartboard")
	Fusion.register_broadcast_receiver(self)


## Điểm tại một điểm chạm (toạ độ thế giới): [điểm, tên ô].
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
	_bang.text = "\n".join(dong)
