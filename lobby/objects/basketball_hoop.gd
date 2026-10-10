class_name BasketballHoop
extends Node3D

## Rổ bóng rổ (bảng quay về +Z, gốc dưới chân). Chỉ master bắt bóng lọt rổ,
## cộng điểm rồi gửi một RPC kèm cả bảng tổng.

## Tâm vành cách mặt bảng.
const VANH_CACH_BANG := 0.38
## Bóng ném từ xa hơn chừng này (tính theo mặt sàn, từ tâm vành) thì được 3 điểm.
const BAN_KINH_3_DIEM := 1.45

## Thấp hơn rổ thật (3.05 m). Đổi thì dời cả `ring`, `StaticSurface_Hoop`, `ScoreZone` trong scene.
@export var rim_height := 2.5
@export var chu_bay_scene: PackedScene

var _diem: Dictionary = {}
var _nghi_den: Dictionary = {}

## Trụ, bảng, bảng điểm, pháo hoa dựng sẵn trong basketball_hoop.tscn.
@onready var _bang_diem: Label3D = $BangDiem
@onready var _no: CPUParticles3D = $No


func _ready() -> void:
	add_to_group("basketball_hoop")
	Fusion.register_broadcast_receiver(self)


func tam_vanh() -> Vector3:
	return to_global(Vector3(0.0, rim_height, VANH_CACH_BANG))


func _khi_bong_vao(body: Node3D) -> void:
	if not NetManager.is_master():
		return
	var bong := body as Basketball
	if bong == null or bong.linear_velocity.y > -0.3:
		return
	# Bóng lăn quanh vành có thể chạm vùng hai lần — chỉ tính một.
	var bay_gio := Time.get_ticks_msec()
	if int(_nghi_den.get(bong.get_instance_id(), 0)) > bay_gio:
		return
	_nghi_den[bong.get_instance_id()] = bay_gio + 1000
	var vanh := tam_vanh()
	var xa := Vector2(bong.cho_nem.x - vanh.x, bong.cho_nem.z - vanh.z).length()
	var cong := 3 if xa > BAN_KINH_3_DIEM else 2
	_diem[bong.nguoi_nem] = int(_diem.get(bong.nguoi_nem, 0)) + cong
	var goi: PackedStringArray = []
	for k in _diem:
		goi.append("%d:%d" % [k, _diem[k]])
	Fusion.rpc(_net_ghi_ban, bong.nguoi_nem, cong, ",".join(goi))


@rpc("any_peer", "call_local")
func _net_ghi_ban(nguoi: int, cong: int, tong: String) -> void:
	var dong: PackedStringArray = ["BONG RO"]
	for cap in tong.split(",", false):
		var ab := cap.split(":")
		if ab.size() == 2:
			dong.append("%s  %s" % [Player.ten_theo_id(get_tree(), int(ab[0])), ab[1]])
	_bang_diem.text = "\n".join(dong)
	_no.restart()
	var chu := chu_bay_scene.instantiate() as ChuBay
	chu.position = Vector3(0, rim_height + 0.5, VANH_CACH_BANG)
	add_child(chu)
	chu.bay("+%d  %s!" % [cong, Player.ten_theo_id(get_tree(), nguoi)], 0.6, 1.3)
