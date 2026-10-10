extends MiniGame3D

## LỞ ĐÁ — leo dốc lên đỉnh, kiểu Fall Guys. Đá rơi từ trời (vòng đỏ báo trước) rồi LĂN xuống
## dốc: đá rơi phía trên mình cũng lăn tới mình. Chạm đá là chết. Mưa thiên thạch dồn từ chân dốc
## lên — ai bị nó đuổi kịp cũng chết. Đá và thiên thạch là hàm của `gio()` + hạt giống: 0 gói tin.
##
## Toạ độ trong sân: `x` ngang dốc, `d` = khoảng NGANG tính từ chân dốc lên (d = −z).

# ─── hình dốc: khớp `san_doc.tscn` ───

const RONG := 14.0
const DAI := 140.0
## 12°.
const DOC := 0.20943951
const BE := 6.0
const DINH := 8.0
const VACH_DICH := DAI + 1.0

# ─── đá ───

## Nhỏ: nhảy một lần là qua. To: nhảy đôi (`so_lan_nhay` 2, đỉnh 2,4 m) vẫn không qua.
const R_NHO := 0.45
const R_TO := 1.3

## Nhanh hơn `Player.speed` 6 — không chạy thoát xuống được, phải né ngang hoặc nhảy.
const V_LAN := 7.5
const CAO_ROI := 22.0
const GIAY_ROI := 0.55

## Lăn quá chỗ này (sau bệ xuất phát) thì xoá.
const D_HET := -BE - 2.0

## Thân người: capsule bán kính 0,4 cao 1,8 → lõi từ 0,4 tới 1,4 trên chân. `MEP` tha sượt nhẹ.
const R_NGUOI := 0.4
const MEP := 0.1

# ─── lịch rơi ───

const T_DAU := 2.0
const NHIP_DAU := 0.9
const NHIP_CUOI := 0.3
const TO_DAU := 0.2
const TO_CUOI := 0.45
const BAO_DAU := 1.4
const BAO_CUOI := 0.9
const GIAY_DAY := 45.0

## Đá rải không rơi sát chân dốc.
const D_MIN := 2.0

## Hàng đá to chắn ngang dốc, chừa một khe.
const HANG_TU := 12.0
const HANG_CACH := 10.0
const HANG_D_MIN := 30.0
const KHE := 3.0
const BAO_HANG := 1.8

## Đá to rải ra không được để khe cho tâm người hẹp hơn chừng này.
const KHE_TAM := 1.0

# ─── mưa thiên thạch dồn từ chân dốc ───

const PHA_BAT_DAU := 5.0
const PHA_D0 := -BE - 2.0
const PHA_TOC_DAU := 1.5
## Luôn chậm hơn người chạy: người không dính đá thì không bao giờ bị đuổi kịp.
const PHA_TOC_CUOI := 4.0
const PHA_TANG_HET := 40.0

## Một viên thiên thạch (chỉ để nhìn) rơi hết chu kỳ này, rơi trong vệt sau tường lửa.
const TT_CHU_KY := 0.7
const TT_VET := 7.0

# ─── camera ───

const CAM_CAO := 9.0
const CAM_LUI := 11.0
const CAM_BAM := 6.0

@export var da_scene: PackedScene = null

var _lich: Array = []

## Chỉ số lịch kế tiếp chưa sinh.
var _ke := 0

## Đá đang có trên sân: {i, n, dap}.
var _dang: Array = []

## Thứ tự về đích (master dùng để xếp hạng).
var _ve_dich: Array = []
var _da_ve := false
var _xep_xong := false
var _cam: Camera3D = null
var _lua: Node3D = null
var _tt: Array[Node] = []


func _ready() -> void:
	super()
	ten = "LỞ ĐÁ"
	luat = "W leo lên đỉnh · né vòng đỏ và đá lăn — chạm là chết · đá nhỏ nhảy qua được · " \
			+ "thiên thạch đuổi sau lưng · chuột trái đánh, chuột phải chưởng"
	giay_van = 60.0


func _dung_san() -> void:
	_cam = san.get_node("Cam") as Camera3D
	_lua = san.get_node("PhaBom/TuongLua") as Node3D
	_tt = san.get_node("PhaBom").find_children("ThienThach*", "", false, false)
	_lich = lich_da(hat_giong)
	_ke = 0
	_dang.clear()
	_ve_dich.clear()
	_da_ve = false
	_xep_xong = false
	_cam.position = Vector3(0.0, CAM_CAO, BE * 0.5 + CAM_LUI)


## Một hàng ngang trên bệ xuất phát.
func _cho_vao(i: int, tong: int) -> Vector3:
	return Vector3(-RONG * 0.5 + (i + 0.5) * RONG / maxi(tong, 1), 0.5, BE * 0.5)


func _luat_moi_nhip() -> void:
	var t := gio()
	_cap_nhat_da(t)
	_cap_nhat_pha(t)
	_cap_nhat_cam()
	var toi := _nguoi(NetManager.local_id())
	if toi != null and con_song(NetManager.local_id()):
		if not _da_ve and d_cua(NetManager.local_id()) >= VACH_DICH:
			_da_ve = true
			Fusion.rpc(_net_ve_dich, NetManager.local_id())
		# Đánh hết choáng sẽ mở khoá — về đích rồi thì giữ khoá mỗi khung.
		if _da_ve:
			toi.khoa_di_chuyen = true
	if NetManager.is_master() and _het_nguoi_leo():
		_chot_ket_qua()


func _toi_thua() -> bool:
	if _da_ve:
		return false
	if super():
		return true
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return false
	var chan := p.global_position - san.global_position
	if -chan.z < pha_d(gio()):
		return true
	var t := gio()
	for e: Dictionary in _dang:
		if cham(_lich[int(e["i"])], t, chan):
			return true
	return false


# ─── đá: hình ───


func _cap_nhat_da(t: float) -> void:
	while _ke < _lich.size() and t >= float(_lich[_ke]["t"]) - float(_lich[_ke]["bao"]):
		var n := da_scene.instantiate() as Node3D
		san.add_child(n)
		_dang.append({"i": _ke, "n": n, "dap": false})
		_ke += 1
	var d_toi := d_cua(NetManager.local_id())
	for k in range(_dang.size() - 1, -1, -1):
		var e: Dictionary = _dang[k]
		var da: Dictionary = _lich[int(e["i"])]
		var n := e["n"] as Node3D
		if d_da(da, t) < D_HET:
			n.queue_free()
			_dang.remove_at(k)
			continue
		var r := float(da["r"])
		var t_roi := float(da["t"])
		var than := n.get_node("Than") as Node3D
		than.visible = t >= t_roi - GIAY_ROI
		if than.visible:
			than.position = vi_tri_da(da, t)
			than.scale = Vector3.ONE * r
			than.rotation.x = maxf(t - t_roi, 0.0) * V_LAN / r
		var vong := n.get_node("Vong") as Node3D
		vong.visible = t < t_roi
		if vong.visible:
			var d := float(da["d"])
			var k_bao := clampf((t - t_roi + float(da["bao"])) / float(da["bao"]), 0.0, 1.0)
			var rv := ban_kinh_chet(r) * lerpf(0.35, 1.0, k_bao)
			vong.scale = Vector3(rv, 1.0, rv)
			vong.position = Vector3(float(da["x"]), mat(d) + 0.04, -d)
			vong.rotation.x = DOC if d > 0.0 and d < DAI else 0.0
		if not bool(e["dap"]) and t >= t_roi:
			e["dap"] = true
			if absf(float(da["d"]) - d_toi) < 35.0:
				(n.get_node("Dap") as AudioStreamPlayer3D).play()


# ─── thiên thạch: chỉ để nhìn, luật là `pha_d` ───


func _cap_nhat_pha(t: float) -> void:
	var dp := pha_d(t)
	var bat := t >= PHA_BAT_DAU
	_lua.visible = bat
	_lua.position = Vector3(0.0, mat(dp) + 3.5, -dp)
	for i in _tt.size():
		var v := _tt[i] as Node3D
		v.visible = bat
		if not bat:
			continue
		var pha := t / TT_CHU_KY + float(i) / _tt.size()
		var vong := floorf(pha)
		var f := pha - vong
		var x := lerpf(-RONG * 0.5, RONG * 0.5, _bam(i * 12.9898 + vong * 78.233))
		var dd := dp - TT_VET * _bam(i * 39.346 + vong * 11.135)
		v.position = Vector3(x, mat(dd) + 0.6 + 18.0 * (1.0 - f) * (1.0 - f), -dd)


## Số giả ngẫu nhiên 0..1 từ một số thực (không đụng RNG — chỉ để nhìn).
static func _bam(a: float) -> float:
	return fposmod(sin(a) * 43758.5453, 1.0)


# ─── camera: bám mình; chết hoặc về đích thì bám người đang leo cao nhất ───


func _cap_nhat_cam() -> void:
	var id := NetManager.local_id()
	if not con_song(id) or _da_ve:
		id = _nguoi_dan_dau()
	var d := clampf(d_cua(id), -BE, DAI + DINH * 0.5)
	var muon := Vector3(0.0, mat(d) + CAM_CAO, -d + CAM_LUI)
	_cam.position = _cam.position.lerp(muon, minf(1.0, CAM_BAM * get_process_delta_time()))


func _nguoi_dan_dau() -> int:
	var ai := NetManager.local_id()
	var xa := -INF
	for k in _song:
		var id := int(k)
		if con_song(id) and not _ve_dich.has(id) and d_cua(id) > xa:
			ai = id
			xa = d_cua(id)
	return ai


func d_cua(id: int) -> float:
	var p := _nguoi(id)
	if p == null or san == null:
		return 0.0
	return san.global_position.z - p.global_position.z


# ─── về đích, chết, xếp hạng ───


@rpc("any_peer", "call_local")
func _net_ve_dich(id: int) -> void:
	if _song.has(id) and not _ve_dich.has(id):
		_ve_dich.append(id)


func _het_nguoi_leo() -> bool:
	for k in _song:
		if con_song(int(k)) and not _ve_dich.has(int(k)):
			return false
	return true


func _khi_ai_do_chet(id: int) -> void:
	var p := _nguoi(id)
	if p == null:
		return
	p.model_root.visible = false
	if id == NetManager.local_id():
		p.khoa_di_chuyen = true


func dung_som() -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		p.model_root.visible = true
	super()


## Về đích (theo thứ tự master nhận) → còn sống, leo cao hơn → chết sau.
## Luật chốt sớm và luật của lớp cha có thể cùng gọi trong một khung — chỉ chạy lần đầu.
func _chot_ket_qua() -> void:
	if _xep_xong:
		return
	_xep_xong = true
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _ve_dich:
		xep.append(int(id))
	var dang_leo: Array = []
	for k in _song:
		if con_song(int(k)) and not xep.has(int(k)):
			dang_leo.append(int(k))
	dang_leo.sort_custom(func(a: int, b: int) -> bool:
		var da := d_cua(a)
		var db := d_cua(b)
		return da > db if not is_equal_approx(da, db) else a < b)
	xep.append_array(dang_leo)
	for i in range(_thu_tu_chet.size() - 1, -1, -1):
		if not xep.has(int(_thu_tu_chet[i])):
			xep.append(int(_thu_tu_chet[i]))
	Fusion.rpc(_net_xep_hang, xep)


func diem_cua(id: int) -> float:
	if not _song.has(id):
		return NAN
	var i := _ve_dich.find(id)
	if i >= 0:
		return 10000.0 - i
	if not con_song(id):
		return -10000.0 + _thu_tu_chet.find(id)
	return d_cua(id)


func chu_diem(id: int) -> String:
	if not _song.has(id):
		return ""
	var i := _ve_dich.find(id)
	if i >= 0:
		return "Đích #%d" % (i + 1)
	if not con_song(id):
		return "Loại"
	return "%.0f m" % maxf(d_cua(id), 0.0)


# ─── luật: hàm thuần (kiem_luat.gd gọi thẳng) ───


## Độ cao mặt sân tại `d`.
static func mat(d: float) -> float:
	return clampf(d, 0.0, DAI) * tan(DOC)


## Tâm người trong vòng này lúc đá chạm đất là chết — vòng đỏ vẽ đúng bán kính này.
static func ban_kinh_chet(r: float) -> float:
	return r + R_NGUOI - MEP


static func d_da(da: Dictionary, t: float) -> float:
	return float(da["d"]) - V_LAN * maxf(t - float(da["t"]), 0.0)


static func vi_tri_da(da: Dictionary, t: float) -> Vector3:
	var d := d_da(da, t)
	var con := maxf(float(da["t"]) - t, 0.0) / GIAY_ROI
	return Vector3(float(da["x"]), mat(d) + float(da["r"]) + CAO_ROI * con * con, -d)


## Đá (đang rơi hoặc lăn) chạm người có chân ở `chan` (toạ độ sân)?
static func cham(da: Dictionary, t: float, chan: Vector3) -> bool:
	if t < float(da["t"]) - GIAY_ROI or d_da(da, t) < D_HET:
		return false
	var c := vi_tri_da(da, t)
	var gan := Vector3(chan.x,
			clampf(c.y, chan.y + R_NGUOI, chan.y + 1.8 - R_NGUOI), chan.z)
	return c.distance_to(gan) < ban_kinh_chet(float(da["r"]))


## Đầu tường thiên thạch: sau `d` này là chết.
static func pha_d(t: float) -> float:
	if t <= PHA_BAT_DAU:
		return PHA_D0
	return minf(PHA_D0 + goc_quay(0.0, t - PHA_BAT_DAU, PHA_TOC_DAU, PHA_TOC_CUOI,
			PHA_TANG_HET), DAI)


## Đá đang lăn nằm trên đường `u = d + V_LAN·t` không đổi — hai đá khác `u` không bao giờ gặp.
static func duong_lan(da: Dictionary) -> float:
	return float(da["d"]) + V_LAN * float(da["t"])


## Lịch cả ván từ hạt giống: mỗi cục {t: lúc chạm đất, x, d, r, bao}, sắp theo lúc hiện vòng.
static func lich_da(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	# Hàng chắn trước, để đá rải tránh khe của chúng.
	var khe: Array = []
	var th := HANG_TU
	while th < 60.0:
		var d_hang := rng.randf_range(HANG_D_MIN, DAI - R_TO)
		var x_khe := rng.randf_range(-RONG * 0.5 + KHE * 0.5, RONG * 0.5 - KHE * 0.5)
		# Mỗi bên rải đều từ mép khe tới tường; không kẹp vào trong — kẹp là lấn vào khe.
		for phia in [-1.0, 1.0]:
			var mep_khe: float = x_khe + phia * KHE * 0.5
			var dai_ben: float = RONG * 0.5 - phia * mep_khe
			if dai_ben < 2.0 * R_NGUOI:
				continue
			var so := ceili(dai_ben / (2.0 * R_TO))
			for j in so:
				var x: float = mep_khe + phia * R_TO
				if so > 1:
					x = lerpf(x, phia * (RONG * 0.5 - R_TO), float(j) / (so - 1))
				ds.append({"t": th, "x": x, "d": d_hang, "r": R_TO, "bao": BAO_HANG})
		khe.append({"u": d_hang + V_LAN * th, "x": x_khe})
		th += HANG_CACH
	var t := T_DAU
	while t < 60.0:
		var k := clampf(t / GIAY_DAY, 0.0, 1.0)
		var r := R_TO if rng.randf() < lerpf(TO_DAU, TO_CUOI, k) else R_NHO
		var da := {"t": t, "x": rng.randf_range(-RONG * 0.5 + r, RONG * 0.5 - r),
				"d": rng.randf_range(D_MIN, DAI - r), "r": r, "bao": lerpf(BAO_DAU, BAO_CUOI, k)}
		var lap_khe := false
		for h: Dictionary in khe:
			if absf(duong_lan(da) - float(h["u"])) < R_TO + r + 1.0 \
					and absf(float(da["x"]) - float(h["x"])) < KHE * 0.5 + r:
				lap_khe = true
		if not lap_khe:
			# Đá to cùng đường lăn với các đá to khác mà chắn kín bề ngang → hạ thành đá nhỏ.
			if r == R_TO and _chan_kin(ds, da):
				da["r"] = R_NHO
			ds.append(da)
		t += lerpf(NHIP_DAU, NHIP_CUOI, k)
	ds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["t"]) - float(a["bao"]) < float(b["t"]) - float(b["bao"]))
	return ds


## Gộp `da` với mọi đá to có đường lăn sát nó (kể cả lúc đang rơi) rồi đo khe còn lại.
## Bảo thủ: coi như tất cả cùng một dải dốc.
static func _chan_kin(ds: Array, da: Dictionary) -> bool:
	var u := duong_lan(da)
	var chan: Array = []
	for o: Dictionary in ds + [da]:
		if float(o["r"]) >= R_TO and absf(duong_lan(o) - u) < 2.0 * R_TO + V_LAN * GIAY_ROI:
			var rc := ban_kinh_chet(float(o["r"]))
			chan.append(Vector2(float(o["x"]) - rc, float(o["x"]) + rc))
	return khe_lon_nhat(chan) < KHE_TAM


## Khe dài nhất cho TÂM người (cách tường `R_NGUOI`) giữa các đoạn `[x_trái, x_phải]` bị chắn.
static func khe_lon_nhat(chan: Array) -> float:
	chan.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var tu := -RONG * 0.5 + R_NGUOI
	var het := RONG * 0.5 - R_NGUOI
	var lon := 0.0
	for c: Vector2 in chan:
		lon = maxf(lon, minf(c.x, het) - tu)
		tu = maxf(tu, c.y)
	return maxf(lon, het - tu)
