class_name BasketballHoop
extends Node3D

## Rổ bóng rổ: trụ, bảng, vành có va chạm, và vùng bắt bóng lọt rổ để ghi điểm.
##
## Mặt bảng quay về +Z (phía sân). Gốc node đặt dưới chân bảng.
##
## Ghi điểm: CHỈ MASTER bắt bóng lọt rổ (chỉ máy đó có bóng vật lý). Master cộng điểm rồi gửi
## MỘT RPC kèm cả bảng tổng — máy nào nhận cũng vẽ đúng bảng, kể cả khi lỡ các lần trước.

const TARGET_RING_DIAMETER := 0.46
## Tâm vành cách mặt bảng.
const VANH_CACH_BANG := 0.38
## Bóng ném từ xa hơn chừng này (tính theo mặt sàn, từ tâm vành) thì được 3 điểm.
const BAN_KINH_3_DIEM := 1.45

## Thấp hơn rổ thật (3.05 m) để dễ ném trong game.
## Đổi số này thì dời cả vành `Model/RootNode/ring`, `StaticSurface_Hoop` và `ScoreZone` trong
## basketball_hoop.tscn cho khớp.
@export var rim_height := 2.5
@export var pole_radius := 0.06

var _diem: Dictionary = {}
var _nghi_den: Dictionary = {}
var _bang_diem: Label3D
var _no: CPUParticles3D


func _ready() -> void:
	add_to_group("basketball_hoop")
	Fusion.register_broadcast_receiver(self)
	_build()


func tam_vanh() -> Vector3:
	return to_global(Vector3(0.0, rim_height, VANH_CACH_BANG))


func _build() -> void:
	var trang := _mat(Color("f2efe6"))
	var xam := _mat(Color("3a3a3f"))
	# Va chạm trụ, tay đòn, bảng, 16 viên cầu vành: node StaticSurface_Hoop trong basketball_hoop.tscn.

	# Trụ phía sau bảng + tay đòn chìa ra đỡ bảng.
	var cao_tru := rim_height + 0.6
	_hop(Vector3(pole_radius * 2, cao_tru, pole_radius * 2), Vector3(0, cao_tru * 0.5, -0.45), xam)
	_hop(Vector3(0.08, 0.08, 0.45), Vector3(0, rim_height + 0.35, -0.225), xam)
	# Bảng: đáy bảng thấp hơn vành 0.15 m như bảng thật.
	_hop(Vector3(1.2, 0.8, 0.04), Vector3(0, rim_height + 0.25, 0.0), trang)
	# Ô vuông đỏ trên bảng, ngay trên vành.
	var o := MeshInstance3D.new()
	var om := BoxMesh.new()
	om.size = Vector3(0.46, 0.34, 0.005)
	o.mesh = om
	o.material_override = _mat(Color("e5484d"))
	o.position = Vector3(0, rim_height + 0.15, 0.022)
	add_child(o)

	var r_vanh := TARGET_RING_DIAMETER * 0.5
	# Thanh nối vành vào bảng (chỉ hình, không va chạm).
	_hop(Vector3(0.03, 0.02, VANH_CACH_BANG - r_vanh), Vector3(0, rim_height, (VANH_CACH_BANG - r_vanh) * 0.5), xam)

	# Vùng bắt bóng (dưới vành, chỉ bắt lớp vật nhặt được): node ScoreZone trong scene.
	$ScoreZone.body_entered.connect(_khi_bong_vao)

	_bang_diem = Label3D.new()
	_bang_diem.text = "BONG RO\nvao ro: 2 diem, ngoai vach: 3 diem"
	_bang_diem.font_size = 40
	_bang_diem.pixel_size = 0.003
	_bang_diem.outline_size = 10
	_bang_diem.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bang_diem.position = Vector3(0, rim_height + 1.0, 0)
	add_child(_bang_diem)

	_no = CPUParticles3D.new()
	_no.emitting = false
	_no.one_shot = true
	_no.amount = 40
	_no.lifetime = 0.9
	_no.explosiveness = 0.9
	_no.direction = Vector3.UP
	_no.spread = 70.0
	_no.initial_velocity_min = 1.5
	_no.initial_velocity_max = 3.0
	var hat := SphereMesh.new()
	hat.radius = 0.025
	hat.height = 0.05
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color("f76b15")
	hm.emission_enabled = true
	hm.emission = Color("f76b15")
	hm.emission_energy_multiplier = 2.0
	hat.material = hm
	_no.mesh = hat
	_no.position = Vector3(0, rim_height, VANH_CACH_BANG)
	add_child(_no)


func _khi_bong_vao(body: Node3D) -> void:
	if not NetManager.is_master():
		return
	var bong := body as Basketball
	if bong == null or bong.linear_velocity.y > -0.3:
		return
	# Một quả lọt rổ có thể chạm vùng hai lần liền (lăn quanh vành) — chỉ tính một.
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
	var bat := Label3D.new()
	bat.text = "+%d  %s!" % [cong, Player.ten_theo_id(get_tree(), nguoi)]
	bat.font_size = 64
	bat.pixel_size = 0.004
	bat.outline_size = 14
	bat.modulate = Color("f5d90a")
	bat.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bat.position = Vector3(0, rim_height + 0.5, VANH_CACH_BANG)
	add_child(bat)
	var tw := bat.create_tween()
	tw.tween_property(bat, "position:y", rim_height + 1.1, 1.3)
	tw.parallel().tween_property(bat, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tw.tween_callback(bat.queue_free)


func _hop(kt: Vector3, vt: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = kt
	mi.mesh = bm
	mi.material_override = mat
	mi.position = vt
	add_child(mi)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m
