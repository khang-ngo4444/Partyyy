class_name LiarBar
extends Node3D

## Liar Bar: 2–4 người, 20 lá (6 K, 6 Q, 6 A, 2 Joker thay mọi chất). Mỗi vòng một chất bàn.
## Đánh 1–3 lá úp, nói là chất bàn; người kế tin (đánh tiếp) hoặc tố LIAR.
## Thua thì bắn ổ quay 6 viên (1 viên thật).
## Master cầm luật và phát nguyên trạng thái JSON; ổ quay chỉ master biết.
## ponytail: bài trên tay nằm trong JSON nên máy bị sửa đọc trộm được;
## Fusion Godot chưa gửi riêng cho một người.

enum Pha { CHO, DEM_NGUOC, CHOI, LAT, XONG }

## Chất → chỉ số lá trong card_deck.tres: K bích, Q cơ, A rô; J là joker.
const ANH_BAI := {"K": 51, "Q": 37, "A": 13, "J": -1}
const TEN_BAI := {"K": "KING", "Q": "QUEEN", "A": "ACE", "J": "JOKER"}
const CHAT_BAN := ["K", "Q", "A"]
const SO_GHE := 4
const BAI_TREN_TAY := 5
const SO_O_DAN := 6
## Số lá tối đa mỗi lượt.
const TOI_DA_MOT_LUOT := 3

## Ảnh bài, gán trong liar_bar.tscn.
@export var bo_bai: CardDeck
## Lá bài sinh lúc chạy: lá thường và lá của mình (bấm được).
@export var la_bai_scene: PackedScene
@export var nut_bai_scene: PackedScene
@export var cao_ban := 0.95
@export var ban_kinh := 1.0
@export var co_bai := 0.2
@export var giay_luot := 25.0
@export var giay_dem_nguoc := 3.0
## Giây lật bài cho mọi người đọc trước khi bắn.
@export var giay_lat := 3.5

# ─── trạng thái (máy nào cũng giữ giống nhau) ───
var _pha := Pha.CHO
var _ban := "K"
## id người chơi theo thứ tự ghế, 0 = trống.
var _ghe: Array = [0, 0, 0, 0]
var _song: Dictionary = {}
## id (chuỗi) → mảng chất bài trên tay.
var _tay: Dictionary = {}
var _luot := 0
## Lượt vừa rồi: {"nguoi": id, "bai": [...]}, rỗng nếu đầu vòng.
var _truoc: Dictionary = {}
## id (chuỗi) → số ô đạn đã bắn.
var _da_ban: Dictionary = {}
var _tb := ""
var _moc := 0.0
## Chỉ lộ bài khi đang LẬT.
var _lo_bai := false

# ─── chỉ master ───
## id (chuỗi) → 6 ô đạn, true = viên thật.
var _o_dan: Dictionary = {}

# ─── hiển thị ───
var _cho_bai: Array[Node3D] = []
var _the_bai: Array[Node3D] = []
var _bang_ghe: Array[Label3D] = []
var _o_hien: Array[Node3D] = []
var _giua: Node3D
var _chon: Array[int] = []
var _giay_dem := -1

## Bàn, ghế, ổ quay, nút, bảng dựng sẵn trong liar_bar.tscn.
@onready var _bang: Label3D = $Bang
@onready var _dem: Label3D = $Dem


func _ready() -> void:
	add_to_group("liar_bar")
	Fusion.register_broadcast_receiver(self)
	for i in SO_GHE:
		_bang_ghe.append(get_node("NhanGhe%d" % i) as Label3D)
		for k in SO_O_DAN:
			_o_hien.append(get_node("Vien%d_%d" % [i, k]) as Node3D)
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


# ─── mạng ───

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
		# Bấm lần hai là đứng dậy.
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


## Master bắn một phát vào người xui.
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
	# Vòng mới: chất bàn mới, chia lại bài.
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


## Người còn sống kế tiếp theo thứ tự ghế.
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


# ─── nhịp chơi (master) ───

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
	# Hết giờ: tự đánh một lá bất kỳ.
	var tay: Array = _tay.get(str(_luot), [])
	if tay.is_empty():
		_chia_bai()
		_moc = _gio() + giay_luot
		_tb = "HET BAI — CHIA VONG MOI"
		_phat("danh")
		return
	_net_danh(str(randi() % tay.size()), _luot)


# ─── hiển thị ───

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


## Dựng lại bài trên tay và bài vừa đánh (chỉ là hình, không vật lý).
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
			# Chỉ chủ bài thấy mặt bài ở máy mình.
			var the := _mot_la(la if id == _toi() else "", i, k, tay.size())
			the.set_meta("ghe", i)
			the.set_meta("la", k)
			_the_bai.append(the)
	# Bài vừa đánh úp giữa bàn; tố LIAR thì lật lên.
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
		# Bài của mình là nút: E chọn / bỏ chọn trước khi bấm ĐÁNH.
		var nut := nut_bai_scene.instantiate() as Pressable
		nut.name = "LiarBai%d_%d" % [ghe, k]
		nut.pressed.connect(_bam_bai.bind(k))
		the = nut
	else:
		the = la_bai_scene.instantiate() as Node3D
	_lat(the, la)
	add_child(the)
	the.position = cho + Vector3.UP * (0.04 if _chon.has(k) and cua_toi else 0.0)
	the.rotation.y = goc + PI
	# Nằm gần sát mặt bàn để người đối diện vẫn thấy mặt bài.
	the.rotation.x = deg_to_rad(-22.0)
	return the


func _mot_la_giua(la: String, k: int, tong: int) -> Node3D:
	var the := la_bai_scene.instantiate() as Node3D
	_lat(the, la)
	add_child(the)
	the.position = Vector3((k - (tong - 1) * 0.5) * co_bai * 1.1, cao_ban + 0.01 + k * 0.004, 0.0)
	the.rotation.y = deg_to_rad(8.0 * k)
	return the


## Mặt trước lá: ảnh theo chất, `la` rỗng = úp (mặt lưng có sẵn trong scene).
func _lat(the: Node3D, la: String) -> void:
	if not ANH_BAI.has(la):
		return
	var mat := the.find_child("MatTruoc") as MeshInstance3D
	(mat.material_override as StandardMaterial3D).albedo_texture = bo_bai.anh(ANH_BAI[la])


## Chọn / bỏ chọn lá của mình, chỉ ở máy này.
func _bam_bai(k: int) -> void:
	if _pha != Pha.CHOI or _luot != _toi():
		return
	if _chon.has(k):
		_chon.erase(k)
	elif _chon.size() < TOI_DA_MOT_LUOT:
		_chon.append(k)
	_ve_lai_bai()
	_keu("chon")


## Phát `Tieng/<ten>` (AudioStreamPlayer3D trong scene).
func _keu(ten: String) -> void:
	var loa := get_node_or_null("Tieng/" + ten) as AudioStreamPlayer3D
	if loa != null:
		loa.play()


# ─── dựng hình ───
