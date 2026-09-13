class_name LiarBar
extends Node3D

## Liar Bar (Liar's Bar). 2-4 nguoi, bo 20 la: 6 K, 6 Q, 6 A, 2 Joker (Joker thay duoc bat ky
## chat nao tren ban). Moi nguoi 5 la, moi vong chon mot CHAT BAN (K / Q / A).
##
## Den luot: chon 1-3 la roi bam DANH — la up mat xuong, mieng noi la dung chat ban. Nguoi ke
## tiep hoac danh tiep (coi nhu tin), hoac bam LIAR.
##   - Bat duoc noi doi  -> ke noi doi ban mot phat sung.
##   - To nham           -> nguoi to bam co mot phat.
## O quay 6 vien: 1 vien that, 5 vien rong, ban lan luot. Trung vien that thi chet. Con mot
## nguoi song thi thang.
##
## MASTER cam luat va phat NGUYEN trang thai JSON. O quay CHI master biet (gui di la lo bai
## ai sap chet); may khac chi thay DA BAN MAY PHAT.
##
## Bai tren tay: gui trong JSON nen may bi sua co the doc trom, y het bai up cua poker o bay
## gio. Fusion Godot khong gui rieng cho mot nguoi duoc (xem muc 1ba) — da ghi nhan.

enum Pha { CHO, DEM_NGUOC, CHOI, LAT, XONG }

const DIR_BAI := "res://asset/kenney_playing-cards/PNG/Cards (medium)/"
const AM_VA := "res://asset/kenney_impact-sounds/Audio/"
const AM_GIAO_DIEN := "res://asset/kenney_interface-sounds/Audio/"
const ANH_BAI := {
	"K": "card_spades_K.png", "Q": "card_hearts_Q.png", "A": "card_diamonds_A.png",
	"J": "card_joker_red.png",
}
const TEN_BAI := {"K": "KING", "Q": "QUEEN", "A": "ACE", "J": "JOKER"}
const CHAT_BAN := ["K", "Q", "A"]
const SO_GHE := 4
const BAI_TREN_TAY := 5
const SO_O_DAN := 6
## Moi luot danh toi da may la.
const TOI_DA_MOT_LUOT := 3

@export var cao_ban := 0.95
@export var ban_kinh := 1.0
@export var co_bai := 0.2
@export var giay_luot := 25.0
@export var giay_dem_nguoc := 3.0
## Lat bai cho moi nguoi doc xong roi moi ban sung.
@export var giay_lat := 3.5

# ---- trang thai (may nao cung giu giong nhau)
var _pha := Pha.CHO
var _ban := "K"
## id nguoi choi theo thu tu ghe, 0 = ghe trong.
var _ghe: Array = [0, 0, 0, 0]
var _song: Dictionary = {}
## id (chuoi) -> mang chat bai tren tay.
var _tay: Dictionary = {}
var _luot := 0
## Luot danh vua roi: {"nguoi": id, "bai": [...]}, rong neu dau vong.
var _truoc: Dictionary = {}
## id (chuoi) -> so o dan da ban.
var _da_ban: Dictionary = {}
var _tb := ""
var _moc := 0.0
## Chi khi dang LAT moi lo bai ra.
var _lo_bai := false

# ---- chi master
## id (chuoi) -> mang 6 o dan, true = vien that.
var _o_dan: Dictionary = {}

# ---- hien thi
var _cho_bai: Array[Node3D] = []
var _the_bai: Array[Node3D] = []
var _bang: Label3D
var _bang_ghe: Array[Label3D] = []
var _o_hien: Array[Node3D] = []
var _dem: Label3D
var _giua: Node3D
var _loa: AudioStreamPlayer3D
var _tieng: Dictionary = {}
var _chon: Array[int] = []
var _giay_dem := -1


func _ready() -> void:
	add_to_group("liar_bar")
	Fusion.register_broadcast_receiver(self)
	_nap_tieng()
	_dung_ban()
	_dung_nut()
	_dung_bang()
	_ve_lai_bai()
	if not NetManager.is_master():
		_xin_trang_thai.call_deferred()


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


func _toi() -> int:
	return NetManager.local_id()


func _ghe_cua(id: int) -> int:
	return _ghe.find(id)


func _goc_ghe(i: int) -> float:
	return TAU * i / SO_GHE


func _cho_ghe(i: int) -> Vector3:
	var g := _goc_ghe(i)
	return Vector3(sin(g) * ban_kinh, cao_ban, cos(g) * ban_kinh)


# ---------------------------------------------------------------- mang

func _xin_trang_thai() -> void:
	Fusion.rpc(_net_xin_trang_thai)


@rpc("any_peer", "call_local")
func _net_xin_trang_thai() -> void:
	if NetManager.is_master():
		_phat("")


func _xin_ngoi() -> void:
	Fusion.rpc(_net_ngoi, _toi())


func _xin_bat_dau() -> void:
	Fusion.rpc(_net_bat_dau, _toi())


func _xin_lam_lai() -> void:
	Fusion.rpc(_net_lam_lai)


func _xin_danh() -> void:
	if _chon.is_empty():
		return
	var ds := _chon.duplicate()
	ds.sort()
	var chuoi: PackedStringArray = []
	for i in ds:
		chuoi.append(str(i))
	_chon.clear()
	Fusion.rpc(_net_danh, ",".join(chuoi), _toi())


func _xin_liar() -> void:
	Fusion.rpc(_net_liar, _toi())


@rpc("any_peer", "call_local")
func _net_ngoi(nguoi: int) -> void:
	if not NetManager.is_master() or _pha == Pha.CHOI or _pha == Pha.LAT:
		return
	if _ghe_cua(nguoi) >= 0:
		# Bam lan hai la dung day.
		_ghe[_ghe_cua(nguoi)] = 0
	else:
		var cho := _ghe.find(0)
		if cho < 0:
			return
		_ghe[cho] = nguoi
	_phat("ngoi")


@rpc("any_peer", "call_local")
func _net_bat_dau(nguoi: int) -> void:
	if not NetManager.is_master() or _ghe_cua(nguoi) < 0:
		return
	if _pha != Pha.CHO and _pha != Pha.XONG:
		return
	var nguoi_choi := _ai_o_ban()
	if nguoi_choi.size() < 2:
		_tb = "CAN IT NHAT 2 NGUOI"
		_phat("")
		return
	_song = {}
	_da_ban = {}
	_o_dan = {}
	for id in nguoi_choi:
		_song[str(id)] = true
		_da_ban[str(id)] = 0
		_o_dan[str(id)] = _nap_o_quay()
	_pha = Pha.DEM_NGUOC
	_moc = _gio() + giay_dem_nguoc
	_tb = ""
	_phat("dem")


@rpc("any_peer", "call_local")
func _net_lam_lai() -> void:
	if not NetManager.is_master():
		return
	_pha = Pha.CHO
	_tay = {}
	_truoc = {}
	_luot = 0
	_song = {}
	_da_ban = {}
	_o_dan = {}
	_lo_bai = false
	_tb = ""
	_phat("lam_lai")


@rpc("any_peer", "call_local")
func _net_danh(chi_so: String, nguoi: int) -> void:
	if not NetManager.is_master() or _pha != Pha.CHOI or nguoi != _luot:
		return
	var tay: Array = _tay.get(str(nguoi), [])
	var ds: Array[int] = []
	for s in chi_so.split(",", false):
		var i := int(s)
		if i < 0 or i >= tay.size() or ds.has(i):
			return
		ds.append(i)
	if ds.is_empty() or ds.size() > TOI_DA_MOT_LUOT:
		return
	ds.sort()
	ds.reverse()
	var danh: Array = []
	for i in ds:
		danh.push_front(tay[i])
		tay.remove_at(i)
	_tay[str(nguoi)] = tay
	_truoc = {"nguoi": nguoi, "bai": danh}
	_luot = _nguoi_ke(nguoi)
	_moc = _gio() + giay_luot
	_tb = ""
	_phat("danh")


@rpc("any_peer", "call_local")
func _net_liar(nguoi: int) -> void:
	if not NetManager.is_master() or _pha != Pha.CHOI or nguoi != _luot or _truoc.is_empty():
		return
	var bi_to: int = int(_truoc.get("nguoi", 0))
	var noi_doi := false
	for la in _truoc.get("bai", []):
		if str(la) != _ban and str(la) != "J":
			noi_doi = true
	var xui := bi_to if noi_doi else nguoi
	_tb = "%s TO LIAR! %s" % [Player.ten_theo_id(get_tree(), nguoi),
			("NOI DOI THAT" if noi_doi else "BAI THAT — TO NHAM")]
	_lo_bai = true
	_pha = Pha.LAT
	_moc = _gio() + giay_lat
	_phat("liar")
	await get_tree().create_timer(giay_lat).timeout
	if NetManager.is_master():
		_ban_sung(xui)


## Ban mot phat vao nguoi xui. Chay o master.
func _ban_sung(nguoi: int) -> void:
	var o: Array = _o_dan.get(str(nguoi), [])
	var chet := false
	if not o.is_empty():
		chet = bool(o.pop_front())
		_o_dan[str(nguoi)] = o
	_da_ban[str(nguoi)] = int(_da_ban.get(str(nguoi), 0)) + 1
	var ten := Player.ten_theo_id(get_tree(), nguoi)
	_lo_bai = false
	_truoc = {}
	if chet:
		_song[str(nguoi)] = false
		_tb = "%s DINH DAN THAT — BI LOAI" % ten
	else:
		_tb = "%s BAN HUT — SONG" % ten
	var con: Array = _ai_con_song()
	if con.size() <= 1:
		_pha = Pha.XONG
		if con.size() == 1:
			_tb = "%s THANG!" % Player.ten_theo_id(get_tree(), int(con[0]))
		_phat("chet" if chet else "hut")
		return
	# Vong moi: chat ban moi, chia lai bai.
	_chia_bai()
	_luot = int(con[0]) if not _song.get(str(nguoi), false) else nguoi
	_pha = Pha.CHOI
	_moc = _gio() + giay_luot
	_phat("chet" if chet else "hut")


func _chia_bai() -> void:
	var bo: Array = []
	for i in 6:
		bo.append("K")
		bo.append("Q")
		bo.append("A")
	bo.append("J")
	bo.append("J")
	bo.shuffle()
	_ban = CHAT_BAN.pick_random()
	_tay = {}
	for id in _ai_con_song():
		var tay: Array = []
		for i in BAI_TREN_TAY:
			if not bo.is_empty():
				tay.append(bo.pop_back())
		_tay[str(id)] = tay
	_truoc = {}


func _nap_o_quay() -> Array:
	var o: Array = []
	for i in SO_O_DAN:
		o.append(i == 0)
	o.shuffle()
	return o


func _ai_o_ban() -> Array:
	var ds: Array = []
	for id in _ghe:
		if int(id) != 0:
			ds.append(int(id))
	return ds


func _ai_con_song() -> Array:
	var ds: Array = []
	for id in _ai_o_ban():
		if bool(_song.get(str(id), false)):
			ds.append(id)
	return ds


## Nguoi con song ke tiep theo chieu nguoc kim dong ho (theo thu tu ghe).
func _nguoi_ke(nguoi: int) -> int:
	var ghe := _ghe_cua(nguoi)
	if ghe < 0:
		var con := _ai_con_song()
		return int(con[0]) if not con.is_empty() else 0
	for b in range(1, SO_GHE + 1):
		var i := (ghe + b) % SO_GHE
		var id := int(_ghe[i])
		if id != 0 and bool(_song.get(str(id), false)):
			return id
	return nguoi


func _phat(su_kien: String) -> void:
	var ms := 0
	if _pha == Pha.DEM_NGUOC or _pha == Pha.CHOI or _pha == Pha.LAT:
		ms = roundi(maxf(0.0, _moc - _gio()) * 1000.0)
	Fusion.rpc(_net_trang_thai, JSON.stringify({
		"pha": _pha, "ban": _ban, "ghe": _ghe, "song": _song, "tay": _tay, "luot": _luot,
		"truoc": _truoc, "da_ban": _da_ban, "tb": _tb, "lo": _lo_bai, "ms": ms,
		"su_kien": su_kien,
	}))


@rpc("any_peer", "call_local")
func _net_trang_thai(json: String) -> void:
	var g = JSON.parse_string(json)
	if not (g is Dictionary):
		return
	if not NetManager.is_master():
		_pha = clampi(int(g.get("pha", 0)), Pha.CHO, Pha.XONG) as Pha
		_ban = str(g.get("ban", "K"))
		var ghe = g.get("ghe")
		if ghe is Array and ghe.size() == SO_GHE:
			_ghe = []
			for v in ghe:
				_ghe.append(int(v))
		var s = g.get("song")
		_song = s if s is Dictionary else {}
		var t = g.get("tay")
		_tay = t if t is Dictionary else {}
		_luot = int(g.get("luot", 0))
		var tr = g.get("truoc")
		_truoc = tr if tr is Dictionary else {}
		var db = g.get("da_ban")
		_da_ban = db if db is Dictionary else {}
		_tb = str(g.get("tb", ""))
		_lo_bai = bool(g.get("lo", false))
		var giay := float(g.get("ms", 0)) / 1000.0
		var tre := NetManager.rtt_ms() / 2000.0
		if _pha == Pha.DEM_NGUOC or _pha == Pha.CHOI or _pha == Pha.LAT:
			_moc = _gio() + giay - tre
	_chon.clear()
	_ve_lai_bai()
	_keu(str(g.get("su_kien", "")))


# ---------------------------------------------------------------- nhip choi (master)

func _process(_delta: float) -> void:
	_ve_bang()
	_tich_tac()
	if not NetManager.is_master():
		return
	if _pha == Pha.DEM_NGUOC and _gio() >= _moc:
		_chia_bai()
		var con := _ai_con_song()
		_luot = int(con[0]) if not con.is_empty() else 0
		_pha = Pha.CHOI
		_moc = _gio() + giay_luot
		_phat("bat_dau")
		return
	if _pha != Pha.CHOI or _gio() < _moc:
		return
	# Het gio: tu danh mot la bat ky cho van khong dung.
	var tay: Array = _tay.get(str(_luot), [])
	if tay.is_empty():
		_chia_bai()
		_moc = _gio() + giay_luot
		_tb = "HET BAI — CHIA VONG MOI"
		_phat("danh")
		return
	_net_danh(str(randi() % tay.size()), _luot)


# ---------------------------------------------------------------- hien thi

func _ve_bang() -> void:
	var dong: PackedStringArray = ["LIAR BAR"]
	match _pha:
		Pha.CHO:
			dong.append("BAM VAO BAN DE NGOI (2-4 NGUOI)")
		Pha.DEM_NGUOC:
			dong.append("CHIA BAI...")
		Pha.CHOI, Pha.LAT:
			dong.append("BAI TREN BAN: %s" % TEN_BAI.get(_ban, _ban))
			if _pha == Pha.CHOI:
				dong.append("LUOT: %s  (%d giay)" % [Player.ten_theo_id(get_tree(), _luot),
						maxi(0, ceili(_moc - _gio()))])
		Pha.XONG:
			dong.append("XONG")
	if _tb != "":
		dong.append(_tb)
	_bang.text = "\n".join(dong)
	_dem.visible = _pha == Pha.DEM_NGUOC
	if _dem.visible:
		_dem.text = str(maxi(1, ceili(_moc - _gio())))

	for i in SO_GHE:
		var id := int(_ghe[i])
		var nhan := _bang_ghe[i]
		if id == 0:
			nhan.text = "GHE TRONG"
			nhan.modulate = Color("9aa0aa")
		else:
			var song := bool(_song.get(str(id), true))
			var so_bai: int = (_tay.get(str(id), []) as Array).size()
			nhan.text = "%s\n%s" % [Player.ten_theo_id(get_tree(), id),
					("%d la  |  ban %d/%d" % [so_bai, int(_da_ban.get(str(id), 0)), SO_O_DAN]
					if song else "DA BI LOAI")]
			nhan.modulate = Color("f5d90a") if id == _luot and _pha == Pha.CHOI \
					else (Color("f2efe6") if song else Color("e5484d"))
		for k in SO_O_DAN:
			var vien := _o_hien[i * SO_O_DAN + k] as MeshInstance3D
			var mat := vien.material_override as StandardMaterial3D
			mat.albedo_color = Color("6b2d3a") if k < int(_da_ban.get(str(id), 0)) \
					else Color("c9ccd2")


func _tich_tac() -> void:
	if _pha != Pha.DEM_NGUOC:
		_giay_dem = -1
		return
	var g := ceili(_moc - _gio())
	if g != _giay_dem and g > 0:
		_giay_dem = g
		_keu("dem")


## Dung lai toan bo bai tren tay va bai vua danh. Bai chi la hinh, khong phai vat ly.
func _ve_lai_bai() -> void:
	for n in _the_bai:
		n.queue_free()
	_the_bai.clear()
	for i in SO_GHE:
		var id := int(_ghe[i])
		if id == 0:
			continue
		var tay: Array = _tay.get(str(id), [])
		for k in tay.size():
			var la := str(tay[k])
			# Chi CHU BAI thay mat bai o may cua minh. Nguoi khac thay lung bai.
			var the := _mot_la(la if id == _toi() else "", i, k, tay.size())
			the.set_meta("ghe", i)
			the.set_meta("la", k)
			_the_bai.append(the)
	# Bai vua danh nam giua ban, up mat; luc to LIAR thi lat len cho moi nguoi doc.
	var bai: Array = _truoc.get("bai", [])
	for k in bai.size():
		var the := _mot_la_giua(str(bai[k]) if _lo_bai else "", k, bai.size())
		_the_bai.append(the)


func _mot_la(la: String, ghe: int, k: int, tong: int) -> Node3D:
	var goc := _goc_ghe(ghe)
	var huong := Vector3(sin(goc), 0.0, cos(goc))
	var ngang := Vector3(cos(goc), 0.0, -sin(goc))
	var cho := huong * (ban_kinh - 0.12) + ngang * ((k - (tong - 1) * 0.5) * (co_bai * 0.85))
	cho.y = cao_ban + 0.02
	var cua_toi := int(_ghe[ghe]) == _toi()
	var the: Node3D
	if cua_toi and _pha == Pha.CHOI:
		# Bai cua chinh minh la NUT bam duoc: bam E de chon / bo chon truoc khi bam DANH.
		var nut := Pressable.new()
		nut.name = "LiarBai%d_%d" % [ghe, k]
		nut.label = ""
		nut.press_range = 2.6
		nut.color = Color.WHITE
		_than_bai(nut, la)
		var chu := Label3D.new()
		chu.name = "Label"
		chu.pixel_size = 0.002
		chu.position.y = 0.12
		nut.add_child(chu)
		nut.pressed.connect(_bam_bai.bind(k))
		the = nut
	else:
		the = Node3D.new()
		_than_bai(the, la)
	add_child(the)
	the.position = cho + Vector3.UP * (0.04 if _chon.has(k) and cua_toi else 0.0)
	the.rotation.y = goc + PI
	# Nam gan sat mat ban (khong dung 55 do nhu ban dau): dung do thi nhin tu ghe doi dien
	# chi thay mot vach trang mong dinh.
	the.rotation.x = deg_to_rad(-22.0)
	return the


func _mot_la_giua(la: String, k: int, tong: int) -> Node3D:
	var the := Node3D.new()
	_than_bai(the, la)
	add_child(the)
	the.position = Vector3((k - (tong - 1) * 0.5) * co_bai * 1.1, cao_ban + 0.01 + k * 0.004, 0.0)
	the.rotation.y = deg_to_rad(8.0 * k)
	return the


## Than mot la bai: hop mong + hai mat dan anh. `la` rong = up mat (chi thay lung bai).
func _than_bai(goc: Node3D, la: String) -> void:
	var than := MeshInstance3D.new()
	than.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(co_bai * 0.72, 0.004, co_bai)
	than.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("f4f1ea")
	than.material_override = mat
	goc.add_child(than)
	_mot_mat(than, DIR_BAI + (ANH_BAI.get(la, "card_back.png") if la != "" else "card_back.png"),
			0.0025, -90.0, Vector2(co_bai * 0.72, co_bai))
	_mot_mat(than, DIR_BAI + "card_back.png", -0.0025, 90.0, Vector2(co_bai * 0.72, co_bai))


func _mot_mat(goc: Node3D, duong: String, y: float, xoay: float, co: Vector2) -> void:
	var tex := load(duong) as Texture2D
	if tex == null:
		return
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = co
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position.y = y
	m.rotation_degrees.x = xoay
	goc.add_child(m)


## Chon / bo chon mot la cua chinh minh. CHI O MAY NAY — khong ai can biet minh dang can nhac.
func _bam_bai(k: int) -> void:
	if _pha != Pha.CHOI or _luot != _toi():
		return
	if _chon.has(k):
		_chon.erase(k)
	elif _chon.size() < TOI_DA_MOT_LUOT:
		_chon.append(k)
	_ve_lai_bai()
	_keu("chon")


func _keu(su_kien: String) -> void:
	var ds: Array = _tieng.get(su_kien, [])
	if ds.is_empty():
		return
	_loa.stream = ds.pick_random()
	_loa.play()


# ---------------------------------------------------------------- dung hinh

func _nap_tieng() -> void:
	var danh: Array = []
	for i in 5:
		danh.append(load(AM_VA + "impactPlate_light_%03d.ogg" % i))
	_tieng = {
		"danh": danh,
		"chon": [load(AM_GIAO_DIEN + "click_001.ogg")],
		"ngoi": [load(AM_GIAO_DIEN + "select_001.ogg")],
		"liar": [load(AM_GIAO_DIEN + "error_004.ogg")],
		"chet": [load(AM_VA + "impactMetal_heavy_000.ogg")],
		"hut": [load(AM_VA + "impactMetal_light_000.ogg")],
		"dem": [load(AM_GIAO_DIEN + "tick_001.ogg")],
		"bat_dau": [load(AM_GIAO_DIEN + "bong_001.ogg")],
		"lam_lai": [load(AM_GIAO_DIEN + "drop_002.ogg")],
	}
	_loa = AudioStreamPlayer3D.new()
	_loa.position.y = cao_ban
	add_child(_loa)


func _dung_ban() -> void:
	var go := _mat(Color("4a2c22"))
	var da := _mat(Color("1f3b2c"))
	# Mat ban tron + chan tru.
	var mat_ban := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = ban_kinh + 0.25
	cm.bottom_radius = ban_kinh + 0.25
	cm.height = 0.08
	mat_ban.mesh = cm
	mat_ban.material_override = da
	mat_ban.position.y = cao_ban - 0.04
	add_child(mat_ban)
	var vanh := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = ban_kinh + 0.22
	tm.outer_radius = ban_kinh + 0.3
	tm.rings = 32
	vanh.mesh = tm
	vanh.material_override = go
	vanh.scale.y = 0.5
	vanh.position.y = cao_ban - 0.02
	add_child(vanh)
	var chan := MeshInstance3D.new()
	var ccm := CylinderMesh.new()
	ccm.top_radius = 0.16
	ccm.bottom_radius = 0.35
	ccm.height = cao_ban - 0.08
	chan.mesh = ccm
	chan.material_override = go
	chan.position.y = (cao_ban - 0.08) * 0.5
	add_child(chan)
	var than := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = ban_kinh + 0.25
	cyl.height = cao_ban
	cs.shape = cyl
	cs.position.y = cao_ban * 0.5
	than.add_child(cs)
	add_child(than)

	for i in SO_GHE:
		var goc := _goc_ghe(i)
		var huong := Vector3(sin(goc), 0.0, cos(goc))
		# Ghe dau: chi de nhin cho ra quan bar, khong ngoi duoc.
		var ghe := MeshInstance3D.new()
		var gm := CylinderMesh.new()
		gm.top_radius = 0.17
		gm.bottom_radius = 0.14
		gm.height = 0.1
		ghe.mesh = gm
		ghe.material_override = _mat(Color("6b2d3a"))
		ghe.position = huong * (ban_kinh + 0.85) + Vector3.UP * 0.65
		add_child(ghe)
		var cot := MeshInstance3D.new()
		var km := CylinderMesh.new()
		km.top_radius = 0.05
		km.bottom_radius = 0.09
		km.height = 0.65
		cot.mesh = km
		cot.material_override = _mat(Color("3d4150"))
		cot.position = huong * (ban_kinh + 0.85) + Vector3.UP * 0.32
		add_child(cot)

		var nhan := Label3D.new()
		nhan.font_size = 26
		nhan.pixel_size = 0.002
		nhan.outline_size = 8
		nhan.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		# Treo tren ghe, KHONG treo tren mat ban: de gan tam ban thi chu de len bai cua chinh
		# minh (anh test: "5 la | ban 0/6" nam de kin ca bo bai).
		nhan.position = huong * (ban_kinh + 0.85) + Vector3.UP * (cao_ban + 0.55)
		add_child(nhan)
		_bang_ghe.append(nhan)

		# O quay: 6 vien tron canh cho ngoi, do = da ban.
		for k in SO_O_DAN:
			var vien := MeshInstance3D.new()
			var vm := CylinderMesh.new()
			vm.top_radius = 0.022
			vm.bottom_radius = 0.022
			vm.height = 0.01
			vien.mesh = vm
			vien.material_override = _mat(Color("c9ccd2"))
			var ngang := Vector3(cos(goc), 0.0, -sin(goc))
			vien.position = huong * (ban_kinh + 0.16) + ngang * ((k - 2.5) * 0.055) \
					+ Vector3.UP * (cao_ban + 0.01)
			add_child(vien)
			_o_hien.append(vien)


func _dung_nut() -> void:
	var packed := load("res://lobby/objects/pressable.tscn") as PackedScene
	var nut := [
		["LiarNgoi", "VAO BAN", Color("3e63dd"), _xin_ngoi],
		["LiarBatDau", "BAT DAU", Color("46a758"), _xin_bat_dau],
		["LiarDanh", "DANH", Color("f5d90a"), _xin_danh],
		["LiarLiar", "LIAR!", Color("e5484d"), _xin_liar],
		["LiarLamLai", "LAM LAI", Color("f76b15"), _xin_lam_lai],
	]
	# Bang dieu khien dat LECH mot ben, khong gan cho ngoi: bam nut khong lo cham vao bai.
	var goc := _goc_ghe(0) + TAU * 0.125
	var huong := Vector3(sin(goc), 0.0, cos(goc))
	var ngang := Vector3(cos(goc), 0.0, -sin(goc))
	var tam := huong * (ban_kinh + 1.35)
	_hop(tam + Vector3.UP * 0.45, Vector3(1.5, 0.9, 0.5), _mat(Color("3d4150")), goc)
	for j in nut.size():
		var b: Pressable = packed.instantiate()
		b.name = nut[j][0]
		b.label = nut[j][1]
		b.color = nut[j][2]
		b.compact = true
		b.button_scale = 0.5
		b.label_size = 26
		b.press_range = 2.6
		b.position = tam + ngang * ((j - 2) * 0.28) + Vector3.UP * 0.9
		b.pressed.connect(nut[j][3])
		add_child(b)


func _dung_bang() -> void:
	_bang = Label3D.new()
	_bang.font_size = 40
	_bang.pixel_size = 0.003
	_bang.outline_size = 10
	_bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bang.position = Vector3(0.0, cao_ban + 1.25, 0.0)
	add_child(_bang)

	_dem = Label3D.new()
	_dem.font_size = 120
	_dem.pixel_size = 0.004
	_dem.outline_size = 20
	_dem.modulate = Color("f5d90a")
	_dem.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dem.position = Vector3(0.0, cao_ban + 0.6, 0.0)
	_dem.visible = false
	add_child(_dem)


func _hop(vt: Vector3, kt: Vector3, mat: Material, xoay: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = kt
	mi.mesh = bm
	mi.material_override = mat
	mi.position = vt
	mi.rotation.y = xoay
	add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = kt
	cs.shape = bs
	body.position = vt
	body.rotation.y = xoay
	body.add_child(cs)
	add_child(body)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m
