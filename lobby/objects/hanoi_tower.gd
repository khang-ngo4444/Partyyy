class_name HanoiTower
extends Node3D

## Thap Ha Noi: 3 coc, 6-8 dia. Chuyen het dia tu coc A sang coc C, it buoc nhat la thang.
##
## KHONG vat ly, KHONG replicator. Dia chi la hinh ve suy ra tu trang thai `_coc`. Master giu
## luat: bam E vao coc -> RPC xin -> master kiem tra -> phat NGUYEN trang thai (JSON) cho moi
## may. May nao cung giu du trang thai, nen master roi phong thi master moi choi tiep duoc.
##
## Coc la Pressable: co san vo sang khi ngam va phim E ben Player, khong phai sua Player.
##
## Mot thap cho ca phong. Ai bam BAT DAU thi van do la cua nguoi do; nguoi khac xem. Nguoi
## choi bo di `giay_bo_di` giay khong bam coc thi ai cung LAM LAI duoc.

enum Pha { CHO, DEM_NGUOC, CHOI, XONG }
enum Lenh { COC, BAT_DAU, LAM_LAI, SO_DIA }

const MAU_DIA: Array[Color] = [
	Color("e5484d"), Color("f76b15"), Color("f5d90a"), Color("46a758"),
	Color("00b8d9"), Color("3e63dd"), Color("8e4ec6"), Color("d6409f"),
]
const MAU_DUNG := Color("46a758")
const MAU_SAI := Color("e5484d")
const MAU_DANG_CAM := Color("f5d90a")
const MAU_DE_COC := Color("5a3a26")
const DAI_BAN := 1.8
const SAU_BAN := 0.7
const DE_DAY := 0.06
## Lo giua dia. Lon hon than coc mot chut.
const LO_DIA := 0.024
## Dia dang cam: truoc mat nguoi cam, hoi thap (he toa do camera, xem Player.diem_cam).
const CHO_CAM := Vector3(0.0, -0.22, -0.55)

@export_range(6, 8) var so_dia := 6
@export var ban_cao := 0.9
@export var khoang_coc := 0.5
@export var coc_cao := 0.42
@export var ban_kinh_nho := 0.07
@export var ban_kinh_lon := 0.2
@export var day_dia := 0.045
@export var giay_dem_nguoc := 3.0
## Nguoi dang choi khong bam coc chung nay giay thi nguoi khac duoc LAM LAI / BAT DAU.
@export var giay_bo_di := 30.0

# ---- trang thai: MOI may giu giong nhau, master la nguon
var _pha := Pha.CHO
## Moi coc la mang co dia, tu DUOI len. Dia k: 0 nho nhat.
var _coc: Array = [[], [], []]
var _nguoi := 0
## Coc co dia dang bi nhac len, -1 = khong. Dia van nam trong mang cua coc do toi khi dat.
var _cam_tu := -1
var _buoc := 0
## Giay theo dong ho MAY NAY: DEM_NGUOC = luc het dem, CHOI = luc bat dau tinh gio.
var _moc := 0.0
var _giay_xong := 0.0
## "so dia" -> [buoc, ms, ten]. Ten luu san: nguoi giu ky luc roi phong van con ten.
var _ky_luc: Dictionary = {}
## Lan cuoi nguoi choi bam coc. Moi may tu ghi, de doi master van co so.
var _lan_cuoi := 0.0

var _dia: Array[MeshInstance3D] = []
var _coc_nut: Array[Pressable] = []
var _coc_de: Array[StandardMaterial3D] = []
var _nut_so_dia: Pressable
var _bang: Label3D
var _dem: Label3D
var _no: CPUParticles3D
var _giay_dem := -1
var _kiem_nguoi := 0.0


func _ready() -> void:
	add_to_group("hanoi_tower")
	Fusion.register_broadcast_receiver(self)
	_dung_ban()
	_dung_coc()
	_dung_bang()
	_dung_nut()
	_dat_coc_ban_dau()
	_dung_dia()
	# Nguoi vao muon: lobby cua ho dung SAU luc master phat trang thai, nen tu xin lai.
	if not NetManager.is_master():
		_xin_trang_thai.call_deferred()


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


func _mat_de() -> float:
	return ban_cao + DE_DAY


func _x_coc(i: int) -> float:
	return (i - 1) * khoang_coc


# ---------------------------------------------------------------- mang

func _xin(lenh: int, coc := -1) -> void:
	Fusion.rpc(_net_xin, lenh, coc, NetManager.local_id())


func _xin_trang_thai() -> void:
	Fusion.rpc(_net_xin_trang_thai)


@rpc("any_peer", "call_local")
func _net_xin_trang_thai() -> void:
	if NetManager.is_master():
		_phat("")


@rpc("any_peer", "call_local")
func _net_xin(lenh: int, coc: int, nguoi: int) -> void:
	if not NetManager.is_master():
		return
	var su_kien := ""
	match lenh:
		Lenh.COC:
			su_kien = _bam_coc(coc, nguoi)
		Lenh.BAT_DAU:
			if _duoc_dieu_khien(nguoi):
				_bat_dau(nguoi)
				su_kien = "dem"
		Lenh.LAM_LAI:
			if _duoc_dieu_khien(nguoi):
				_ve_cho()
				su_kien = "lam_lai"
		Lenh.SO_DIA:
			if _pha == Pha.CHO or _pha == Pha.XONG:
				so_dia = 6 if so_dia >= 8 else so_dia + 1
				_ve_cho()
				_dung_dia()
				su_kien = "lam_lai"
	if su_kien != "":
		_phat(su_kien)


func _phat(su_kien: String) -> void:
	var ms := 0
	match _pha:
		Pha.DEM_NGUOC:
			ms = roundi(maxf(0.0, _moc - _gio()) * 1000.0)
		Pha.CHOI:
			ms = roundi((_gio() - _moc) * 1000.0)
		Pha.XONG:
			ms = roundi(_giay_xong * 1000.0)
	var goi := {
		"pha": _pha, "so_dia": so_dia, "coc": _coc, "nguoi": _nguoi, "cam": _cam_tu,
		"buoc": _buoc, "ms": ms, "ky_luc": _ky_luc, "su_kien": su_kien,
	}
	Fusion.rpc(_net_trang_thai, JSON.stringify(goi))


@rpc("any_peer", "call_local")
func _net_trang_thai(json: String) -> void:
	var g = JSON.parse_string(json)
	if not (g is Dictionary):
		return
	# Master da co san trang thai nay — chi can hieu ung.
	if not NetManager.is_master():
		_ap_dung(g)
	_hieu_ung(str(g.get("su_kien", "")))


func _ap_dung(g: Dictionary) -> void:
	var coc = g.get("coc")
	if not (coc is Array) or coc.size() != 3:
		return
	var moi: Array = [[], [], []]
	for i in 3:
		if not (coc[i] is Array):
			return
		for v in coc[i]:
			moi[i].append(int(v))
	_coc = moi
	_pha = clampi(int(g.get("pha", 0)), Pha.CHO, Pha.XONG) as Pha
	_nguoi = int(g.get("nguoi", 0))
	_cam_tu = int(g.get("cam", -1))
	_buoc = int(g.get("buoc", 0))
	var ky = g.get("ky_luc")
	_ky_luc = ky if ky is Dictionary else {}
	# Doi so mili-giay master gui ra moc gio CUA MAY NAY, tru nua RTT (goi tin mat chung ay
	# moi toi). Khong gui moc gio cua master: dong ho moi may dem tu luc may do mo game.
	var giay := float(g.get("ms", 0)) / 1000.0
	var tre := NetManager.rtt_ms() / 2000.0
	match _pha:
		Pha.DEM_NGUOC:
			_moc = _gio() + giay - tre
		Pha.CHOI:
			_moc = _gio() - giay - tre
		Pha.XONG:
			_giay_xong = giay
	_lan_cuoi = _gio()
	var n := clampi(int(g.get("so_dia", 6)), 6, 8)
	if n != so_dia or _dia.size() != so_dia:
		so_dia = n
		_dung_dia()


# ---------------------------------------------------------------- luat (chi master)

func _duoc_dieu_khien(nguoi: int) -> bool:
	if _pha == Pha.CHO or _pha == Pha.XONG or nguoi == _nguoi:
		return true
	return _gio() - _lan_cuoi > giay_bo_di


func _bam_coc(i: int, nguoi: int) -> String:
	if _pha != Pha.CHOI or nguoi != _nguoi or i < 0 or i > 2:
		return ""
	_lan_cuoi = _gio()
	if _cam_tu < 0:
		if _coc[i].is_empty():
			return ""
		_cam_tu = i
		return "nhat"
	var dia: int = _coc[_cam_tu].back()
	var tu := _cam_tu
	_cam_tu = -1
	if i == tu:
		return "dat"
	# Sai luat: dia chua roi coc cu nen tha ra la no tu ve cho.
	if not _coc[i].is_empty() and int(_coc[i].back()) < dia:
		return "sai"
	_coc[tu].pop_back()
	_coc[i].append(dia)
	_buoc += 1
	if _coc[2].size() == so_dia:
		_xong()
		return "thang"
	return "dat"


func _bat_dau(nguoi: int) -> void:
	_ve_cho()
	_nguoi = nguoi
	_pha = Pha.DEM_NGUOC
	_moc = _gio() + giay_dem_nguoc
	_lan_cuoi = _gio()


func _ve_cho() -> void:
	_pha = Pha.CHO
	_nguoi = 0
	_buoc = 0
	_cam_tu = -1
	_dat_coc_ban_dau()


func _xong() -> void:
	_pha = Pha.XONG
	_giay_xong = _gio() - _moc
	var ms := roundi(_giay_xong * 1000.0)
	var cu = _ky_luc.get(str(so_dia))
	if cu == null or _buoc < int(cu[0]) or (_buoc == int(cu[0]) and ms < int(cu[1])):
		_ky_luc[str(so_dia)] = [_buoc, ms, Player.ten_theo_id(get_tree(), _nguoi)]


func _dat_coc_ban_dau() -> void:
	_coc = [[], [], []]
	for k in range(so_dia - 1, -1, -1):
		_coc[0].append(k)


func _process(delta: float) -> void:
	var t := 1.0 - exp(-delta * 14.0)
	for k in _dia.size():
		_dia[k].position = _dia[k].position.lerp(_dich_dia(k), t)
	_ve_bang()
	_to_coc()
	_tich_tac()
	if NetManager.is_master():
		_master_theo_doi(delta)


func _master_theo_doi(delta: float) -> void:
	if _pha == Pha.DEM_NGUOC and _gio() >= _moc:
		_pha = Pha.CHOI
		_moc = _gio()
		_lan_cuoi = _gio()
		_phat("bat_dau")
	# Nguoi choi roi phong thi tra thap ve cho, khong de van treo mai.
	_kiem_nguoi += delta
	if _kiem_nguoi < 0.5:
		return
	_kiem_nguoi = 0.0
	if (_pha == Pha.DEM_NGUOC or _pha == Pha.CHOI) and _nguoi_node(_nguoi) == null:
		_ve_cho()
		_phat("lam_lai")


# ---------------------------------------------------------------- hien thi (moi may)

func _nguoi_node(id: int) -> Player:
	if id == 0:
		return null
	for n in get_tree().get_nodes_in_group("players"):
		if n is Player and n.player_id() == id:
			return n
	return null


## Cho dia k can toi (toa do cua thap).
func _dich_dia(k: int) -> Vector3:
	for i in 3:
		var tang: int = _coc[i].find(k)
		if tang < 0:
			continue
		if i == _cam_tu and tang == _coc[i].size() - 1:
			var p := _nguoi_node(_nguoi)
			if p != null:
				return to_local(p.diem_cam(CHO_CAM).origin)
			return Vector3(_x_coc(i), _mat_de() + coc_cao + 0.12, 0.0)
		return Vector3(_x_coc(i), _mat_de() + day_dia * (tang + 0.5), 0.0)
	return Vector3.ZERO


func _giay_da_choi() -> float:
	match _pha:
		Pha.CHOI:
			return _gio() - _moc
		Pha.XONG:
			return _giay_xong
	return 0.0


func _dong_ho(giay: float) -> String:
	var g := int(giay)
	@warning_ignore("integer_division")
	return "%d:%02d" % [g / 60, g % 60]


func _ve_bang() -> void:
	var ten := Player.ten_theo_id(get_tree(), _nguoi)
	var dong: PackedStringArray = ["THAP HA NOI - %d DIA" % so_dia]
	match _pha:
		Pha.CHO:
			dong.append("BAM BAT DAU DE CHOI")
		Pha.DEM_NGUOC:
			dong.append("%s CHUAN BI" % ten)
		Pha.CHOI:
			dong.append("%s DANG CHOI" % ten)
		Pha.XONG:
			dong.append("%s XONG!" % ten)
	if _pha != Pha.CHO:
		dong.append("BUOC %d   (IT NHAT %d)" % [_buoc, (1 << so_dia) - 1])
		dong.append("THOI GIAN " + _dong_ho(_giay_da_choi()))
	var kl = _ky_luc.get(str(so_dia))
	if kl is Array and kl.size() == 3:
		dong.append("KY LUC: %s  %d BUOC  %s" % [kl[2], int(kl[0]), _dong_ho(int(kl[1]) / 1000.0)])
	else:
		dong.append("KY LUC: CHUA CO")
	_bang.text = "\n".join(dong)
	_nut_so_dia.set_label("%d DIA" % so_dia)
	_dem.visible = _pha == Pha.DEM_NGUOC
	if _dem.visible:
		_dem.text = str(maxi(1, ceili(_moc - _gio())))


## Dang cam dia: coc dat duoc to xanh, coc sai luat to do, coc vua nhac len to vang.
func _to_coc() -> void:
	var dia := -1
	if _cam_tu >= 0 and _cam_tu < 3 and not _coc[_cam_tu].is_empty():
		dia = _coc[_cam_tu].back()
	for i in 3:
		var mau := Color.WHITE
		var de := MAU_DE_COC
		if dia >= 0:
			if i == _cam_tu:
				mau = MAU_DANG_CAM
			elif _coc[i].is_empty() or int(_coc[i].back()) > dia:
				mau = MAU_DUNG
			else:
				mau = MAU_SAI
			de = mau.darkened(0.35)
		_coc_nut[i].text.modulate = mau
		_coc_de[i].albedo_color = de


## Moi giay dem nguoc mot tieng tich — moi may tu dem theo `_moc`, khong RPC.
func _tich_tac() -> void:
	if _pha != Pha.DEM_NGUOC:
		_giay_dem = -1
		return
	var g := ceili(_moc - _gio())
	if g != _giay_dem and g > 0:
		_giay_dem = g
		_keu("dem")


func _hieu_ung(su_kien: String) -> void:
	match su_kien:
		"nhat", "dat", "sai", "bat_dau", "lam_lai":
			_keu(su_kien)
		"thang":
			_keu("thang")
			_no.restart()
			var bat := Label3D.new()
			bat.text = "%s XONG!\n%d BUOC - %s" % [Player.ten_theo_id(get_tree(), _nguoi), _buoc,
					_dong_ho(_giay_xong)]
			bat.font_size = 64
			bat.pixel_size = 0.004
			bat.outline_size = 14
			bat.modulate = MAU_DANG_CAM
			bat.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			# Thap hon bang trang thai va nhich ra truoc: bay len ngang bang la hai chu de nhau.
			bat.position = Vector3(0.0, _mat_de() + 0.2, 0.3)
			add_child(bat)
			var tw := bat.create_tween()
			tw.tween_property(bat, "position:y", bat.position.y + 0.2, 2.5)
			tw.parallel().tween_property(bat, "modulate:a", 0.0, 1.0).set_delay(1.5)
			tw.tween_callback(bat.queue_free)


## Tiếng sự kiện: node `Tieng/<ten>` (AudioStreamPlayer3D) trong scene — đổi âm thanh trong Inspector,
## không sửa code. Bộ nhiều biến thể dùng AudioStreamRandomizer.
func _keu(ten: String) -> void:
	var loa := get_node_or_null("Tieng/" + ten) as AudioStreamPlayer3D
	if loa != null:
		loa.play()


# ---------------------------------------------------------------- dung hinh


func _dung_ban() -> void:
	var go := _mat(Color("8a5a3b"))
	var go_toi := _mat(Color("4a3020"))
	_hop(Vector3(0.0, ban_cao - 0.03, 0.0), Vector3(DAI_BAN, 0.06, SAU_BAN), go, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_hop(Vector3(sx * (DAI_BAN * 0.5 - 0.06), (ban_cao - 0.06) * 0.5, sz * (SAU_BAN * 0.5 - 0.06)),
					Vector3(0.06, ban_cao - 0.06, 0.06), go_toi, false)
	# Khoi va cham lap day gam ban: nguoi khong chui duoc qua.
	_hop_va_cham(Vector3(0.0, ban_cao * 0.5, 0.0), Vector3(DAI_BAN, ban_cao, SAU_BAN))
	# De go dai giu ba coc.
	_hop(Vector3(0.0, ban_cao + DE_DAY * 0.5, 0.0),
			Vector3(khoang_coc * 2.0 + ban_kinh_lon * 2.0 + 0.12, DE_DAY, ban_kinh_lon * 2.0 + 0.1),
			_mat(Color("c08a5b")), false)



func _dung_coc() -> void:
	for i in 3:
		var c := Pressable.new()
		c.name = "HanoiCoc%d" % i
		c.label = "ABC"[i]
		c.label_size = 48
		c.press_range = 2.8
		c.color = Color.WHITE
		# Pressable doi con ten "Mesh" (khoi rung khi bam, cho ngam) va "Label".
		var than := MeshInstance3D.new()
		than.name = "Mesh"
		var cm := CylinderMesh.new()
		cm.top_radius = 0.016
		cm.bottom_radius = 0.016
		cm.height = coc_cao
		than.mesh = cm
		than.position.y = _mat_de() + coc_cao * 0.5
		c.add_child(than)
		# Dia tron duoi chan coc: to mau goi y dat duoc / sai, va lam vo sang khi ngam to ro.
		var de := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = ban_kinh_lon + 0.02
		dm.bottom_radius = ban_kinh_lon + 0.02
		dm.height = 0.008
		de.mesh = dm
		de.position.y = _mat_de() + 0.004
		c.add_child(de)
		var chu := Label3D.new()
		chu.name = "Label"
		chu.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		chu.pixel_size = 0.004
		chu.outline_size = 12
		chu.position.y = _mat_de() + coc_cao + 0.12
		c.add_child(chu)
		c.position.x = _x_coc(i)
		c.pressed.connect(_xin.bind(Lenh.COC, i))
		add_child(c)
		# Pressable._ready da to than coc bang `color` phat sang — tra ve mau go.
		than.material_override = _mat(Color("e8d9b8"))
		var dmat := _mat(MAU_DE_COC)
		de.material_override = dmat
		_coc_nut.append(c)
		_coc_de.append(dmat)


func _dung_bang() -> void:
	_bang = Label3D.new()
	_bang.font_size = 40
	_bang.pixel_size = 0.003
	_bang.outline_size = 10
	_bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bang.position = Vector3(0.0, _mat_de() + coc_cao + 0.7, 0.0)
	add_child(_bang)

	_dem = Label3D.new()
	_dem.font_size = 120
	_dem.pixel_size = 0.004
	_dem.outline_size = 20
	_dem.modulate = MAU_DANG_CAM
	_dem.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dem.position = Vector3(0.0, _mat_de() + coc_cao * 0.6, 0.25)
	_dem.visible = false
	add_child(_dem)

	_no = CPUParticles3D.new()
	_no.emitting = false
	_no.one_shot = true
	_no.amount = 60
	_no.lifetime = 1.2
	_no.explosiveness = 0.9
	_no.direction = Vector3.UP
	_no.spread = 60.0
	_no.initial_velocity_min = 1.5
	_no.initial_velocity_max = 3.0
	var hat := BoxMesh.new()
	hat.size = Vector3(0.03, 0.03, 0.005)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = MAU_DANG_CAM
	hm.emission_enabled = true
	hm.emission = MAU_DANG_CAM
	hm.emission_energy_multiplier = 2.0
	hat.material = hm
	_no.mesh = hat
	_no.position = Vector3(_x_coc(2), _mat_de() + coc_cao, 0.0)
	add_child(_no)


## Nut o bang dieu khien BEN PHAI ban, cach coc C gan 1 m — ngam coc khong trung nut.
func _dung_nut() -> void:
	var x_tu := DAI_BAN * 0.5 + 0.68
	_hop(Vector3(x_tu, 0.5, 0.0), Vector3(1.05, 1.0, 0.45), _mat(Color("3d4150")), false)
	_hop_va_cham(Vector3(x_tu, 0.5, 0.0), Vector3(1.05, 1.0, 0.45))
	var packed := load("res://lobby/objects/pressable.tscn") as PackedScene
	var nut := [
		["HanoiBatDau", "BAT DAU", Color("46a758"), Lenh.BAT_DAU],
		["HanoiSoDia", "6 DIA", Color("3e63dd"), Lenh.SO_DIA],
		["HanoiLamLai", "LAM LAI", Color("f76b15"), Lenh.LAM_LAI],
	]
	for j in nut.size():
		var b: Pressable = packed.instantiate()
		b.name = nut[j][0]
		b.label = nut[j][1]
		b.color = nut[j][2]
		b.compact = true
		b.button_scale = 0.6
		# Chu "BAT DAU" co 36 rong ~0.28 m, nut cach nhau 0.3 m thi chu ba nut dinh vao nhau.
		b.label_size = 30
		b.press_range = 2.6
		b.position = Vector3(x_tu + (j - 1) * 0.34, 1.0, 0.0)
		b.pressed.connect(_xin.bind(nut[j][3]))
		add_child(b)
		if nut[j][3] == Lenh.SO_DIA:
			_nut_so_dia = b


func _dung_dia() -> void:
	for d in _dia:
		d.queue_free()
	_dia.clear()
	for k in so_dia:
		var r := lerpf(ban_kinh_nho, ban_kinh_lon, float(k) / (so_dia - 1))
		# Vong xuyen ep det: dia co lo giua va mep bo tron, khong can model.
		var tm := TorusMesh.new()
		tm.inner_radius = LO_DIA
		tm.outer_radius = r
		tm.rings = 32
		tm.ring_segments = 12
		var mat := StandardMaterial3D.new()
		mat.albedo_color = MAU_DIA[k % MAU_DIA.size()]
		mat.roughness = 0.35
		var mi := MeshInstance3D.new()
		mi.mesh = tm
		mi.material_override = mat
		mi.scale = Vector3(1.0, day_dia / (r - LO_DIA), 1.0)
		add_child(mi)
		_dia.append(mi)
	for k in _dia.size():
		_dia[k].position = _dich_dia(k)


func _hop(vt: Vector3, kt: Vector3, mat: Material, va_cham: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = kt
	mi.mesh = bm
	mi.material_override = mat
	mi.position = vt
	add_child(mi)
	if va_cham:
		_hop_va_cham(vt, kt)


func _hop_va_cham(vt: Vector3, kt: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = kt
	cs.shape = bs
	body.position = vt
	body.add_child(cs)
	add_child(body)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m
