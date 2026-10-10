extends SceneTree

## Kiểm luật Lở Đá: godot --headless --path . --script minigame/lo_da/kiem_luat.gd
## Gọi thẳng hàm thuần của `lo_da.gd` (lịch rơi, chạm, thiên thạch) — không chép tay, vì kiểm
## một bản chép của bộ sinh lịch là kiểm nhầm thứ. Chỉ số của `Player` là chép tay.
## Dùng `ck()` thay `assert` (assert fail ở --headless --script làm Godot treo).

## Nạp lúc chạy (không preload): lo_da.gd hỏng thì báo FAIL chứ không chạy tiếp như không có gì.
var LoDa: GDScript = null

# player.gd
const SPEED := 6.0
const JUMP_HEIGHT := 1.2
const SO_LAN_NHAY := 2
const GIAY_VAN := 60.0

## Khe nhỏ nhất (cho TÂM người) phải còn giữa các đá to chắn cùng một dải dốc.
const KHE_TAM := 0.6
const SO_GIONG := 200

var _loi := 0


func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)


func _initialize() -> void:
	LoDa = load("res://minigame/lo_da/lo_da.gd")
	if LoDa == null or not LoDa.can_instantiate():
		print("FAIL  lo_da.gd khong bien dich duoc")
		quit(1)
		return
	_kiem_tat_dinh()
	_kiem_lich()
	_kiem_nhay()
	_kiem_thien_thach()
	_kiem_loi_di()
	_do_nguoi_chay_thang()
	print("XONG — %d loi" % _loi)
	quit(1 if _loi > 0 else 0)


func _kiem_tat_dinh() -> void:
	ck(str(LoDa.lich_da(7)) == str(LoDa.lich_da(7)), "cung hat giong phai ra cung lich")
	ck(str(LoDa.lich_da(7)) != str(LoDa.lich_da(8)), "khac hat giong phai ra lich khac")


## Báo đủ lâu, không giết lúc xuất phát, không rơi lên bệ hay đỉnh, không lọt ra ngoài tường.
func _kiem_lich() -> void:
	for g in SO_GIONG:
		for da: Dictionary in LoDa.lich_da(g):
			var r := float(da["r"])
			ck(float(da["bao"]) >= 0.9, "giong %d: bao %.2f < 0.9" % [g, da["bao"]])
			ck(float(da["t"]) - float(da["bao"]) >= 0.5, "giong %d: vong hien truoc giay 0.5" % g)
			ck(float(da["d"]) >= LoDa.D_MIN - 0.001 and float(da["d"]) <= LoDa.DAI - r + 0.001,
					"giong %d: da roi ngoai doc d=%.1f" % [g, da["d"]])
			ck(absf(float(da["x"])) <= LoDa.RONG * 0.5 + r, "giong %d: da ngoai tuong" % g)


## Đá nhỏ: đỉnh nhảy một lần là qua. Đá to: đỉnh nhảy đôi vẫn chạm. Đứng dưới đất thì chạm cả hai.
func _kiem_nhay() -> void:
	var d := 60.0
	var mat = LoDa.mat(d)
	for r in [LoDa.R_NHO, LoDa.R_TO]:
		# t = 1 sau lúc chạm đất: đá đang lăn, tâm ở đúng d.
		var da = {"t": 0.0, "x": 0.0, "d": d + LoDa.V_LAN, "r": r, "bao": 1.0}
		ck(LoDa.cham(da, 1.0, Vector3(0, mat, -d)), "r=%.2f: dung duoi dat phai cham" % r)
		var nhay_mot = LoDa.cham(da, 1.0, Vector3(0, mat + JUMP_HEIGHT, -d))
		var nhay_doi = LoDa.cham(da, 1.0, Vector3(0, mat + JUMP_HEIGHT * SO_LAN_NHAY, -d))
		if r == LoDa.R_NHO:
			ck(not nhay_mot, "da nho: nhay mot lan phai qua")
		else:
			ck(nhay_doi, "da to: nhay doi cung khong duoc qua")
	# Vòng đỏ vẽ đúng vùng chết: mép trong chết, mép ngoài sống.
	var roi = {"t": 5.0, "x": 0.0, "d": d, "r": LoDa.R_TO, "bao": 1.0}
	var rv = LoDa.ban_kinh_chet(LoDa.R_TO)
	ck(LoDa.cham(roi, 5.0, Vector3(rv - 0.05, mat, -d)), "trong vong do phai chet")
	ck(not LoDa.cham(roi, 5.0, Vector3(rv + 0.05, mat, -d)), "ngoai vong do phai song")
	ck(not LoDa.cham(roi, 5.0 - LoDa.GIAY_ROI - 0.01, Vector3(0, mat, -d)),
			"luc moi bao (chua roi) khong duoc chet")


## Thiên thạch luôn chậm hơn người chạy, và chắc chắn kết thúc ván trước khi hết giờ.
func _kiem_thien_thach() -> void:
	ck(LoDa.PHA_TOC_CUOI < SPEED * 0.8, "thien thach duoi kip nguoi chay")
	ck(LoDa.pha_d(GIAY_VAN) >= LoDa.DAI - 0.001,
			"thien thach chua toi dinh luc het gio (d=%.1f)" % LoDa.pha_d(GIAY_VAN))
	# Người chạy thẳng 0,9 × tốc từ bệ xuất phát không bao giờ bị đuổi kịp.
	var t := 0.0
	while t < GIAY_VAN:
		var d_nguoi = -LoDa.BE * 0.5 + SPEED * 0.9 * t
		if d_nguoi >= LoDa.VACH_DICH:
			break
		ck(d_nguoi > LoDa.pha_d(t) + 2.0, "giay %.1f: thien thach duoi kip nguoi chay" % t)
		t += 0.5
	print("thien thach toi dinh luc giay %.1f" % _luc_pha_toi(LoDa.DAI - 0.01))


func _luc_pha_toi(d: float) -> float:
	var t := 0.0
	while LoDa.pha_d(t) < d and t < 200.0:
		t += 0.1
	return t


## Mọi dải dốc dày 1 m, mọi lúc: đá to (đang lăn hoặc sắp chạm đất) phải chừa một khe cho tâm
## người ≥ KHE_TAM. Đá nhỏ không tính — nhảy qua được.
func _kiem_loi_di() -> void:
	var lan_ket := 0
	var mau := ""
	for g in SO_GIONG:
		var lich = LoDa.lich_da(g)
		var t := 0.0
		while t < GIAY_VAN:
			var bang: Dictionary = {}
			for da: Dictionary in lich:
				if float(da["r"]) < LoDa.R_TO or t < float(da["t"]) - LoDa.GIAY_ROI:
					continue
				var dd = LoDa.d_da(da, t)
				if dd < 0.0:
					continue
				var rc = LoDa.ban_kinh_chet(float(da["r"]))
				for b in range(maxi(int(floor(dd - rc)), 0), mini(int(ceil(dd + rc)), int(LoDa.DAI))):
					if not bang.has(b):
						bang[b] = []
					(bang[b] as Array).append(Vector2(float(da["x"]) - rc, float(da["x"]) + rc))
			for b in bang:
				if LoDa.khe_lon_nhat(bang[b]) < KHE_TAM:
					lan_ket += 1
					if mau == "":
						mau = "giong %d giay %.1f d=%d" % [g, t, b]
			t += 0.1
	ck(lan_ket == 0, "%d lan dai doc bi chan kin, vd %s" % [lan_ket, mau])


## Đo (không kiểm): người chạy thẳng giữa dốc, không né, sống được bao lâu.
func _do_nguoi_chay_thang() -> void:
	var tong := 0.0
	var ve := 0
	for g in SO_GIONG:
		var lich = LoDa.lich_da(g)
		var x = -LoDa.RONG * 0.5 + LoDa.RONG * float(g % 8 + 0.5) / 8.0
		var t := 0.0
		var song := true
		while t < GIAY_VAN and song:
			var d = -LoDa.BE * 0.5 + SPEED * 0.95 * t
			if d >= LoDa.VACH_DICH:
				ve += 1
				break
			for da: Dictionary in lich:
				if LoDa.cham(da, t, Vector3(x, LoDa.mat(d), -d)):
					song = false
					break
			t += 0.02
		tong += t
	print("nguoi chay thang khong ne: song TB %.1f s, ve dich %d/%d" % [tong / SO_GIONG, ve, SO_GIONG])
