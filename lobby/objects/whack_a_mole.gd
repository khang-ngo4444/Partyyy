class_name WhackAMole
extends Node3D

## Dap chuot chui. Choi TREN CHINH MODEL MAY ARCADE "Whack em All": chuot nho len tu nam cai lo
## co san tren mat may, khong dung ban tu dung nua.
##
## Mat may la mat BAC THANG nen khong the doan cho lo. Nam vi tri trong `LO_MAY` do bang tia
## quet trong Godot: ban tia tu tren xuong khap mat may, gom cac diem lom 2-20 cm so voi xung
## quanh, roi gom cum. Ket qua: hai lo o bac thap, ba lo o bac cao.
##
## Master gieo lo nao nho len va cham diem; moi may nhan NGUYEN trang thai (JSON) nen vao muon
## hay doi master deu khong lech. Chuot chi la hinh ve: khong vat ly, khong replicator.

enum Pha { CHO, DEM_NGUOC, CHOI, XONG }
enum Lenh { BAT_DAU, LAM_LAI }

const AM_VA := "res://asset/kenney_impact-sounds/Audio/"
const AM_GIAO_DIEN := "res://asset/kenney_interface-sounds/Audio/"

## Cho nam cai lo tren mat may, do luc may cao CAO_DO met. Doi model la phai do lai.
const LO_MAY := [
	Vector3(-0.125, 0.534, -0.968),
	Vector3(-0.125, 0.534, -0.693),
	Vector3(-0.369, 0.660, -1.038),
	Vector3(-0.369, 0.660, -0.826),
	Vector3(-0.369, 0.660, -0.610),
]
const SO_LO := 5
const CAO_DO := 1.6
## Ban kinh mieng lo do duoc o CAO_DO.
const BAN_KINH_LO := 0.045
## Doan trong clip goc: dung yen ngo nghieng / bi dap (giay, clip dai 9.42 s).
const DOAN_DUNG := [0.9, 3.4]
const DOAN_DAP := [8.3, 8.8]

## May cao bao nhieu met. Moi thu khac (lo, chuot, nut, bang diem) deu tinh theo so nay.
## Scale lai node `May` trong scene thi sua ca so nay — lo, nut, bang deu do theo no.
@export var may_cao := 2.0
## Hiep dai bao lau.
@export var giay_hiep := 45.0
@export var giay_dem_nguoc := 3.0
## Chuot nam tren mat may bao lau roi tu thut xuong. De lau cho de dap.
@export var chuot_len_min := 1.8
@export var chuot_len_max := 3.2
## Khoang cach giua hai lan nho len cua CUNG mot lo.
@export var nghi_min := 0.7
@export var nghi_max := 1.8
## Vung bua khi dang NGAM vao chuot thi trung: tia nhin di qua dinh chuot trong ban kinh nay.
##
## Khong do khoang cach tu dau bua toi chuot: tay nguoi choi chi voi toi ~0.6 m, ma cac lo chi
## cach nhau khoang 0.3 m — ban kinh du lon de bat duoc se dap trung ca lo ben canh.
@export var ban_kinh_ngam := 0.3
## Xa hon chung nay thi khong voi toi.
@export var tam_voi := 3.0

var _pha := Pha.CHO
## Bit thu i = lo i dang co chuot.
var _len := 0
var _diem: Dictionary = {}
var _moc := 0.0
## "id,id:diem" cua nguoi thang, rong = chua ai dap trung.
var _thang := ""

## Master: giay (dong ho may master) toi luc lo i doi trang thai.
var _han: Array[float] = []
var _than: Array[Node3D] = []
var _anim: Array[AnimationPlayer] = []
var _bang: Label3D
var _dem: Label3D
var _no: CPUParticles3D
var _loa: AudioStreamPlayer3D
var _tieng: Dictionary = {}
var _giay_dem := -1
## Xoay va dich cua model may — de doi toa do lo do duoc sang toa do node nay.
var _goc_may := Basis.IDENTITY
var _dich_may := Vector3.ZERO


func _ready() -> void:
	add_to_group("whack_a_mole")
	Fusion.register_broadcast_receiver(self)
	_nap_tieng()
	_dung_may()        # phai chay truoc: cho dat chuot, nut, bang deu bam theo may
	_dung_chuot()
	_dung_bang()
	_dung_nut()
	for i in SO_LO:
		_han.append(0.0)
	if not NetManager.is_master():
		_xin_trang_thai.call_deferred()


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


## Cho dat bua thu i, main.gd goi luc spawn. Bua roi xuong san truoc may.
func cho_bua(i: int) -> Vector3:
	return to_global(Vector3(-0.45 + 0.9 * i, 0.4, 0.95))


## Ti le giua may that va luc do toa do lo.
func _ti() -> float:
	return may_cao / CAO_DO


## Do cao mat choi (mieng lo thap nhat).
func _mat_choi() -> float:
	return LO_MAY[0].y * _ti()


## Con chuot cao bao nhieu: vua long mieng lo.
func _cao_chuot() -> float:
	return BAN_KINH_LO * 3.6 * _ti()


## Chuot nho len cao hon MIENG LO chung nay. Toa do lo do duoc la DAY hom lom, khong phai mat
## may: dat chuot ngang do thi no dung thut trong hom, chi tho mot mau long len.
func _len_cao() -> float:
	return _cao_chuot() * 0.6


## Cho cua lo thu i trong toa do node nay (da tinh ca xoay va dich cua may).
func _cho_lo(i: int) -> Vector3:
	return _goc_may * (LO_MAY[i] * _ti()) + _dich_may


# ---------------------------------------------------------------- mang

func _xin(lenh: int) -> void:
	Fusion.rpc(_net_xin, lenh, NetManager.local_id())


func _xin_trang_thai() -> void:
	Fusion.rpc(_net_xin_trang_thai)


@rpc("any_peer", "call_local")
func _net_xin_trang_thai() -> void:
	if NetManager.is_master():
		_phat("")


@rpc("any_peer", "call_local")
func _net_xin(lenh: int, _nguoi: int) -> void:
	if not NetManager.is_master():
		return
	match lenh:
		Lenh.BAT_DAU:
			if _pha == Pha.CHO or _pha == Pha.XONG:
				_diem = {}
				_len = 0
				_thang = ""
				_pha = Pha.DEM_NGUOC
				_moc = _gio() + giay_dem_nguoc
				_phat("dem")
		Lenh.LAM_LAI:
			if _pha != Pha.CHOI:
				_diem = {}
				_len = 0
				_thang = ""
				_pha = Pha.CHO
				_phat("lam_lai")


## May cua nguoi vung bua goi: tia nhin cua ho co di qua con chuot nao dang len khong.
func thu_dap(goc: Vector3, huong: Vector3, nguoi: int) -> void:
	if _pha != Pha.CHOI:
		return
	var trung := -1
	var gan_nhat := ban_kinh_ngam
	for i in SO_LO:
		if _len & (1 << i) == 0:
			continue
		var toi := _dinh_chuot(i) - goc
		var xa := toi.dot(huong)
		if xa < 0.0 or xa > tam_voi:
			continue
		var lech := (toi - huong * xa).length()
		if lech < gan_nhat:
			gan_nhat = lech
			trung = i
	if trung >= 0:
		Fusion.rpc(_net_dap, trung, nguoi)


@rpc("any_peer", "call_local")
func _net_dap(lo: int, nguoi: int) -> void:
	if not NetManager.is_master():
		return
	if _pha != Pha.CHOI or lo < 0 or lo >= SO_LO or _len & (1 << lo) == 0:
		return
	var truoc := _len
	_len &= ~(1 << lo)
	_han[lo] = _gio() + randf_range(nghi_min, nghi_max)
	_diem[str(nguoi)] = int(_diem.get(str(nguoi), 0)) + 1
	_cap_nhat_chuot(truoc)
	_phat("dap:%d" % lo)


func _phat(su_kien: String) -> void:
	var ms := 0
	if _pha == Pha.DEM_NGUOC or _pha == Pha.CHOI:
		ms = roundi(maxf(0.0, _moc - _gio()) * 1000.0)
	Fusion.rpc(_net_trang_thai, JSON.stringify({
		"pha": _pha, "len": _len, "diem": _diem, "ms": ms, "thang": _thang, "su_kien": su_kien,
	}))


@rpc("any_peer", "call_local")
func _net_trang_thai(json: String) -> void:
	var g = JSON.parse_string(json)
	if not (g is Dictionary):
		return
	if not NetManager.is_master():
		var truoc := _len
		_pha = clampi(int(g.get("pha", 0)), Pha.CHO, Pha.XONG) as Pha
		_len = int(g.get("len", 0))
		var d = g.get("diem")
		_diem = d if d is Dictionary else {}
		_thang = str(g.get("thang", ""))
		var giay := float(g.get("ms", 0)) / 1000.0
		var tre := NetManager.rtt_ms() / 2000.0
		if _pha == Pha.DEM_NGUOC or _pha == Pha.CHOI:
			_moc = _gio() + giay - tre
		if truoc != _len:
			_cap_nhat_chuot(truoc)
	_hieu_ung(str(g.get("su_kien", "")))


# ---------------------------------------------------------------- luat (master)

func _process(_delta: float) -> void:
	_ve_bang()
	_tich_tac()
	if not NetManager.is_master():
		return
	if _pha == Pha.DEM_NGUOC and _gio() >= _moc:
		_pha = Pha.CHOI
		_moc = _gio() + giay_hiep
		for i in SO_LO:
			_han[i] = _gio() + randf_range(0.2, 1.2)
		_phat("bat_dau")
		return
	if _pha != Pha.CHOI:
		return
	if _gio() >= _moc:
		_pha = Pha.XONG
		var truoc := _len
		_len = 0
		_thang = _ai_thang()
		_cap_nhat_chuot(truoc)
		_phat("thang")
		return
	var doi := false
	var cu := _len
	for i in SO_LO:
		if _gio() < _han[i]:
			continue
		if _len & (1 << i) != 0:
			_len &= ~(1 << i)
			_han[i] = _gio() + randf_range(nghi_min, nghi_max)
		else:
			_len |= 1 << i
			_han[i] = _gio() + randf_range(chuot_len_min, chuot_len_max)
		doi = true
	if doi:
		_cap_nhat_chuot(cu)
		_phat("chuot")


## Tra ve "id,id:diem" chu KHONG phai cau tieng Viet: ten nguoi do MAY NHAN doi ra, khong phai
## master. Master gui cau san thi may khac in ra ten cua thoi diem master tinh (da gap: bang
## bao "#1 THANG" vi luc do master chua kip co ten nguoi do).
func _ai_thang() -> String:
	var cao := 0
	var ids: PackedStringArray = []
	for k in _diem:
		var v := int(_diem[k])
		if v > cao:
			cao = v
			ids = [str(k)]
		elif v == cao and v > 0:
			ids.append(str(k))
	if cao == 0:
		return ""
	return "%s:%d" % [",".join(ids), cao]


## Doi "id,id:diem" ra cau de hien len bang.
func _cau_thang() -> String:
	if _thang == "":
		return "KHONG AI DAP TRUNG CON NAO"
	var doi := _thang.split(":")
	if doi.size() != 2:
		return _thang
	var ten: PackedStringArray = []
	for id in doi[0].split(",", false):
		ten.append(Player.ten_theo_id(get_tree(), int(id)))
	return "%s THANG - %s CHUOT" % [" & ".join(ten), doi[1]]


# ---------------------------------------------------------------- hien thi

func _dinh_chuot(i: int) -> Vector3:
	return to_global(_cho_lo(i) + Vector3.UP * (_len_cao() + _cao_chuot() * 0.5))


func _cap_nhat_chuot(truoc: int) -> void:
	for i in SO_LO:
		if i >= _than.size():
			return
		var gio_len := _len & (1 << i) != 0
		if gio_len == (truoc & (1 << i) != 0):
			continue
		var than := _than[i]
		var tw := than.create_tween()
		tw.tween_property(than, "position:y", _len_cao() if gio_len else -_cao_chuot(), 0.3) \
				.set_trans(Tween.TRANS_BACK if gio_len else Tween.TRANS_QUAD)
		if gio_len:
			than.visible = true
			_dien(i, DOAN_DUNG, true)
		else:
			# Lo tren may chi lom vai xang-ti-met, dung tren cao van nhin thay — an han cho chac.
			tw.tween_callback(func(): than.visible = false)


## Chay mot doan cua clip goc. File chi co MOT animation 9.42 s gom ca nho len, ngo nghieng va
## bi dap — cat doan bang play_section chu khong sua file.
func _dien(i: int, doan: Array, lap: bool) -> void:
	if i >= _anim.size():
		return
	var ap := _anim[i]
	if ap == null:
		return
	var ten: String = ap.get_animation_list()[0]
	ap.get_animation(ten).loop_mode = Animation.LOOP_LINEAR if lap else Animation.LOOP_NONE
	if ap.has_method("play_section"):
		ap.play_section(ten, doan[0], doan[1], -1.0, 1.0)
	else:
		ap.play(ten)
		ap.seek(doan[0], true)


func _ve_bang() -> void:
	var dong: PackedStringArray = ["DAP CHUOT CHUI"]
	match _pha:
		Pha.CHO:
			dong.append("BAM BAT DAU")
		Pha.DEM_NGUOC:
			dong.append("CHUAN BI...")
		Pha.CHOI:
			dong.append("CON %d GIAY" % maxi(0, ceili(_moc - _gio())))
		Pha.XONG:
			dong.append(_cau_thang())
	var ds: Array = []
	for k in _diem:
		ds.append([int(_diem[k]), int(k)])
	ds.sort_custom(func(a, b): return a[0] > b[0])
	for c in ds:
		dong.append("%s  %d" % [Player.ten_theo_id(get_tree(), c[1]), c[0]])
	_bang.text = "\n".join(dong)
	_dem.visible = _pha == Pha.DEM_NGUOC
	if _dem.visible:
		_dem.text = str(maxi(1, ceili(_moc - _gio())))


func _tich_tac() -> void:
	if _pha != Pha.DEM_NGUOC:
		_giay_dem = -1
		return
	var g := ceili(_moc - _gio())
	if g != _giay_dem and g > 0:
		_giay_dem = g
		_keu("dem")


func _hieu_ung(su_kien: String) -> void:
	if su_kien.begins_with("dap:"):
		var lo := int(su_kien.substr(4))
		_keu("dap")
		_dien(lo, DOAN_DAP, false)
		_no.global_position = _dinh_chuot(lo)
		_no.restart()
		return
	match su_kien:
		"chuot":
			_keu("chuot")
		"dem", "bat_dau", "lam_lai":
			_keu(su_kien)
		"thang":
			_keu("thang")
			_no.global_position = to_global(Vector3(0.0, may_cao * 0.7, 0.4))
			_no.restart()


func _keu(ten: String) -> void:
	var ds: Array = _tieng.get(ten, [])
	if ds.is_empty():
		return
	_loa.stream = ds.pick_random()
	_loa.play()


# ---------------------------------------------------------------- dung hinh

func _nap_tieng() -> void:
	var dap: Array = []
	for i in 5:
		dap.append(load(AM_VA + "impactPunch_medium_%03d.ogg" % i))
	_tieng = {
		"chuot": [load(AM_GIAO_DIEN + "pluck_001.ogg"), load(AM_GIAO_DIEN + "pluck_002.ogg")],
		"dap": dap,
		"dem": [load(AM_GIAO_DIEN + "tick_001.ogg")],
		"bat_dau": [load(AM_GIAO_DIEN + "bong_001.ogg")],
		"lam_lai": [load(AM_GIAO_DIEN + "drop_002.ogg")],
		"thang": [load(AM_GIAO_DIEN + "confirmation_002.ogg")],
	}
	_loa = AudioStreamPlayer3D.new()
	_loa.position.y = 1.0
	add_child(_loa)


## May arcade: node `May` trong whack_a_mole.tscn, mat choi huong ve +Z. Lo, chuot, nut, bang
## deu bam theo xoay/dich cua node do.
func _dung_may() -> void:
	var may := $May as Node3D
	_goc_may = Basis(Vector3.UP, may.rotation.y)
	_dich_may = may.position
	# Va cham theo dung hinh may (826 tam giac) — nguoi khong di xuyen qua, bua co cho cham.
	for m: MeshInstance3D in may.find_children("*", "MeshInstance3D", true, false):
		m.create_trimesh_collision()


## Chuot: `Lo0`..`Lo4` / `Than` / `Chuot` trong whack_a_mole.tscn. `Than` an san, truot len xuong khi choi.
func _dung_chuot() -> void:
	for i in SO_LO:
		var than := get_node("Lo%d/Than" % i) as Node3D
		_than.append(than)
		var ap := than.find_child("AnimationPlayer", true, false) as AnimationPlayer
		_anim.append(ap)
		if ap != null:
			_dien(i, DOAN_DUNG, true)


func _dung_bang() -> void:
	_bang = Label3D.new()
	_bang.font_size = 40
	_bang.pixel_size = 0.003
	_bang.outline_size = 10
	_bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bang.position = Vector3(0.0, may_cao + 0.35, 0.4)
	add_child(_bang)

	_dem = Label3D.new()
	_dem.font_size = 120
	_dem.pixel_size = 0.004
	_dem.outline_size = 20
	_dem.modulate = Color("f5d90a")
	_dem.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dem.position = Vector3(0.0, may_cao * 0.6, 0.8)
	_dem.visible = false
	add_child(_dem)

	_no = CPUParticles3D.new()
	_no.emitting = false
	_no.one_shot = true
	_no.amount = 30
	_no.lifetime = 0.7
	_no.explosiveness = 0.9
	_no.direction = Vector3.UP
	_no.spread = 60.0
	_no.initial_velocity_min = 1.2
	_no.initial_velocity_max = 2.5
	_no.top_level = true
	var hat := SphereMesh.new()
	hat.radius = 0.018
	hat.height = 0.036
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
	var x := 0.85
	for cap in [["WhackBatDau", "BAT DAU", Color("46a758"), Lenh.BAT_DAU, 0.22],
			["WhackLamLai", "LAM LAI", Color("f76b15"), Lenh.LAM_LAI, -0.22]]:
		var b: Pressable = packed.instantiate()
		b.name = cap[0]
		b.label = cap[1]
		b.color = cap[2]
		b.compact = true
		b.button_scale = 0.6
		b.label_size = 30
		b.press_range = 2.6
		b.position = Vector3(x, _mat_choi(), cap[4])
		b.pressed.connect(_xin.bind(cap[3]))
		add_child(b)
	_hop(Vector3(x, (_mat_choi() - 0.05) * 0.5, 0.0),
			Vector3(0.45, _mat_choi() - 0.05, 0.8), _mat(Color("3d4150")))
	_hop_va_cham(Vector3(x, _mat_choi() * 0.5, 0.0), Vector3(0.45, _mat_choi(), 0.8))


func _hop(vt: Vector3, kt: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = kt
	mi.mesh = bm
	mi.material_override = mat
	mi.position = vt
	add_child(mi)


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
