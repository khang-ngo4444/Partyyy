class_name MiniGolf
extends Node3D

## Mini golf mot lo. Dua bong vao lo bang it gay nhat; par 3.
##
## San tu dung bang khoi (mat co + thanh chan + mot go doc), lo la CSG khoet that. Chi lay cua
## bo Kenney Minigolf Kit nhung mon ro rang: co, bong, gay.
##
## MASTER cam luat: gay chi GUI mot cu vut len master (xem Putter.throw), master danh bong va
## dem gay cho tung nguoi. Bong la Pickable nen vi tri da co replicator lo, JSON chi mang so gay.
##
## Mot qua bong chung: ai vut cung duoc, moi cu tinh vao so gay cua chinh nguoi do.

const PAR := 3
## Ten ket qua theo so gay so voi par.
const TEN_DIEM := {-2: "EAGLE", -1: "BIRDIE", 0: "PAR", 1: "BOGEY", 2: "DOUBLE BOGEY"}

@export var dai := 5.0
@export var rong := 2.6
@export var co_cao := 0.12
@export var thanh_cao := 0.16
@export var ban_kinh_lo := 0.075
## Vut xa hon chung nay thi khong toi bong.
@export var tam_vut := 1.1

var _gay: Dictionary = {}
var _thong_bao := ""
var _cho_dat_lai := 0.0

var _bang: Label3D
var _no: CPUParticles3D


func _ready() -> void:
	add_to_group("mini_golf")
	Fusion.register_broadcast_receiver(self)
	_dung_san()
	_dung_bang()
	_dung_nut()
	if not NetManager.is_master():
		_xin_trang_thai.call_deferred()


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


func tam_lo() -> Vector3:
	return to_global(Vector3(0.0, co_cao, -dai * 0.5 + 0.8))


# ---------------------------------------------------------------- mang

func _xin_trang_thai() -> void:
	Fusion.rpc(_net_xin_trang_thai)


@rpc("any_peer", "call_local")
func _net_xin_trang_thai() -> void:
	if NetManager.is_master():
		_phat("")


## Putter goi o may nguoi cam gay. `cho_dung` la CHO DUNG CUA NGUOI (duoi chan), khong phai mat:
## do theo tia nhin thi bong nam cach mat 1.6 m theo chieu doc, cu vut nao cung bi tu choi.
func vut(cho_dung: Vector3, huong: Vector3, luc: float, nguoi: int) -> void:
	var bong := _bong()
	if bong == null or bong.holder_id != 0:
		return
	# Bong phai nam trong tam gay va o phia truoc mat nguoi vut.
	var toi := bong.global_position - cho_dung
	toi.y = 0.0
	if toi.length() > tam_vut or toi.normalized().dot(huong) < 0.2:
		return
	Fusion.rpc(_net_vut, huong.x, huong.z, luc, nguoi)


@rpc("any_peer", "call_local")
func _net_vut(hx: float, hz: float, luc: float, nguoi: int) -> void:
	if not NetManager.is_master():
		return
	var bong := _bong()
	if bong == null or bong.holder_id != 0:
		return
	var huong := Vector3(hx, 0.0, hz).normalized()
	bong.nguoi_nem = nguoi
	bong.sleeping = false
	bong.linear_velocity = huong * luc + Vector3.UP * 0.15
	bong.angular_velocity = huong.cross(Vector3.UP) * (luc / GolfBall.BAN_KINH) * -0.3
	_gay[str(nguoi)] = int(_gay.get(str(nguoi), 0)) + 1
	_thong_bao = ""
	_phat("vut")


func _xin_lam_lai() -> void:
	Fusion.rpc(_net_lam_lai)


@rpc("any_peer", "call_local")
func _net_lam_lai() -> void:
	if not NetManager.is_master():
		return
	_gay = {}
	_thong_bao = ""
	_dat_lai_bong()
	_phat("lam_lai")


func _phat(su_kien: String) -> void:
	Fusion.rpc(_net_trang_thai, JSON.stringify({
		"gay": _gay, "tb": _thong_bao, "su_kien": su_kien,
	}))


@rpc("any_peer", "call_local")
func _net_trang_thai(json: String) -> void:
	var g = JSON.parse_string(json)
	if not (g is Dictionary):
		return
	if not NetManager.is_master():
		var t = g.get("gay")
		_gay = t if t is Dictionary else {}
		_thong_bao = str(g.get("tb", ""))
	var su_kien := str(g.get("su_kien", ""))
	_keu(su_kien)
	if su_kien == "vao_lo":
		_no.global_position = tam_lo()
		_no.restart()


# ---------------------------------------------------------------- luat (master)

func _process(_delta: float) -> void:
	_ve_bang()
	if not NetManager.is_master():
		return
	if _cho_dat_lai > 0.0:
		if _gio() >= _cho_dat_lai:
			_cho_dat_lai = 0.0
			_dat_lai_bong()
			_phat("")
		return
	var bong := _bong()
	if bong == null or bong.holder_id != 0:
		return
	var cho := to_local(bong.global_position)
	var lo := to_local(tam_lo())
	if Vector2(cho.x - lo.x, cho.z - lo.z).length() < ban_kinh_lo and cho.y < co_cao - 0.02:
		_vao_lo(bong)
		return
	# Bong ra khoi san (bat qua thanh chan) thi tra ve cho phat.
	if absf(cho.x) > rong * 0.5 + 0.6 or absf(cho.z) > dai * 0.5 + 0.6 or cho.y < -0.5:
		_cho_dat_lai = _gio() + 0.5


func _vao_lo(bong: GolfBall) -> void:
	var nguoi := bong.nguoi_nem
	var so := int(_gay.get(str(nguoi), 0))
	var lech := so - PAR
	var ten: String = TEN_DIEM.get(lech, "+%d" % lech if lech > 0 else str(lech))
	if so == 1:
		ten = "HOLE IN ONE"
	_thong_bao = "%s VAO LO - %d GAY (%s)" % [Player.ten_theo_id(get_tree(), nguoi), so, ten]
	bong.linear_velocity = Vector3.ZERO
	bong.angular_velocity = Vector3.ZERO
	_gay.erase(str(nguoi))
	_cho_dat_lai = _gio() + 3.0
	_phat("vao_lo")


func _dat_lai_bong() -> void:
	var bong := _bong()
	if bong == null:
		return
	bong.linear_velocity = Vector3.ZERO
	bong.angular_velocity = Vector3.ZERO
	bong.nguoi_nem = 0
	# Cho phat = cho bong duoc sinh ra (Placeholder_GolfBall_0 trong mini_golf.tscn).
	bong.global_transform = Transform3D(Basis.IDENTITY, bong.cho_mac_dinh)


func _bong() -> GolfBall:
	return get_tree().get_first_node_in_group("golf_ball") as GolfBall


# ---------------------------------------------------------------- hien thi

func _ve_bang() -> void:
	var dong: PackedStringArray = ["MINI GOLF - PAR %d" % PAR]
	if _thong_bao != "":
		dong.append(_thong_bao)
	elif _gay.is_empty():
		dong.append("CAM GAY, GIU E DE NAP LUC")
	for k in _gay:
		dong.append("%s  %d GAY" % [Player.ten_theo_id(get_tree(), int(k)), int(_gay[k])])
	_bang.text = "\n".join(dong)


## Tiếng sự kiện: node `Tieng/<ten>` (AudioStreamPlayer3D) trong scene — đổi âm thanh trong Inspector,
## không sửa code. Bộ nhiều biến thể dùng AudioStreamRandomizer.
func _keu(ten: String) -> void:
	var loa := get_node_or_null("Tieng/" + ten) as AudioStreamPlayer3D
	if loa != null:
		loa.play()


# ---------------------------------------------------------------- dung hinh


func _dung_san() -> void:
	var co := _mat(Color("3f8f4a"))
	var vien := _mat(Color("6b4a2f"))

	# Mat co khoet lo THAT bang CSG: bong lot xuong duoi mat co thi tinh la vao lo.
	# Va cham mat co (ca lo): node StaticSurface_Green trong mini_golf.tscn, bake tu CSG nay —
	# doi kich thuoc san thi bake lai hinh do.
	var khoi := CSGCombiner3D.new()
	add_child(khoi)
	var mat_co := CSGBox3D.new()
	mat_co.size = Vector3(rong, co_cao, dai)
	mat_co.position.y = co_cao * 0.5
	mat_co.material = co
	khoi.add_child(mat_co)
	var lo := CSGCylinder3D.new()
	lo.radius = ban_kinh_lo
	lo.height = co_cao * 3.0
	lo.sides = 20
	lo.operation = CSGShape3D.OPERATION_SUBTRACTION
	lo.position = Vector3(0.0, co_cao * 0.5, -dai * 0.5 + 0.8)
	khoi.add_child(lo)
	# Day lo: bong roi xuong thi nam lai day, khong xuyen qua san.
	_hop(Vector3(0.0, -0.06, -dai * 0.5 + 0.8), Vector3(0.3, 0.04, 0.3), _mat(Color("14161c")))

	# Thanh chan bon phia.
	for s: float in [-1.0, 1.0]:
		_hop(Vector3(s * (rong + 0.1) * 0.5, co_cao + thanh_cao * 0.5, 0.0),
				Vector3(0.1, thanh_cao, dai + 0.2), vien)
		_hop(Vector3(0.0, co_cao + thanh_cao * 0.5, s * (dai + 0.1) * 0.5),
				Vector3(rong + 0.2, thanh_cao, 0.1), vien)

	# Vat can BEN CANH duong bong, khong nam chan giua: bong golf ban kinh 3 cm khong treo noi
	# mot buc cao 10 cm, dat giua san la khong cach nao vao lo.
	_hop(Vector3(-0.7, co_cao + 0.09, 0.3), Vector3(0.9, 0.18, 0.12), _mat(Color("6b4a2f")))
	_hop(Vector3(0.75, co_cao + 0.09, -0.7), Vector3(0.7, 0.18, 0.12), _mat(Color("6b4a2f")))

	# Vach phat bong.
	var vach := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.5, 0.004, 0.06)
	vach.mesh = vm
	vach.material_override = _mat(Color("f2efe6"))
	vach.position = Vector3(0.0, co_cao + 0.003, dai * 0.5 - 0.6)
	add_child(vach)


func _dung_bang() -> void:
	_bang = Label3D.new()
	_bang.font_size = 40
	_bang.pixel_size = 0.003
	_bang.outline_size = 10
	_bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bang.position = Vector3(0.0, 1.6, -dai * 0.5 - 0.2)
	add_child(_bang)

	_no = CPUParticles3D.new()
	_no.emitting = false
	_no.one_shot = true
	_no.amount = 40
	_no.lifetime = 1.0
	_no.explosiveness = 0.9
	_no.direction = Vector3.UP
	_no.spread = 50.0
	_no.initial_velocity_min = 1.5
	_no.initial_velocity_max = 3.0
	_no.top_level = true
	var hat := SphereMesh.new()
	hat.radius = 0.02
	hat.height = 0.04
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color("f5d90a")
	hm.emission_enabled = true
	hm.emission = Color("f5d90a")
	hm.emission_energy_multiplier = 2.0
	hat.material = hm
	_no.mesh = hat
	add_child(_no)


func _dung_nut() -> void:
	var packed := load("res://lobby/objects/pressable.tscn") as PackedScene
	var b: Pressable = packed.instantiate()
	b.name = "GolfLamLai"
	b.label = "DAT LAI BONG"
	b.color = Color("f76b15")
	b.compact = true
	b.button_scale = 0.6
	b.label_size = 28
	b.press_range = 2.6
	b.position = Vector3(-(rong * 0.5 + 0.4), 0.9, dai * 0.5 - 0.5)
	b.pressed.connect(_xin_lam_lai)
	add_child(b)
	_hop(Vector3(-(rong * 0.5 + 0.4), 0.45, dai * 0.5 - 0.5), Vector3(0.4, 0.9, 0.5),
			_mat(Color("3d4150")))


func _hop(vt: Vector3, kt: Vector3, mat: Material) -> void:
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
