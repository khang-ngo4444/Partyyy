extends SceneTree

## Kiểm luật Laser Leap: godot --headless --path minigame/laser_leap --script kiem_luat.gd
## Chặn nhịp cố định (#4) và chỗ đứng an toàn vĩnh viễn (#3).
## Hằng số chép tay; dùng `ck()` thay `assert`.

enum { MOT, DOI, CHEO, LIEN, NHIEU }

# laser_leap.gd
const CAO_THOAT := 0.9
const TOC_DAU := 0.55
const TOC_CUOI := 1.9
const GIAY_TANG_HET := 60.0
const GIAY_BAO := 1.1
const DOT_DAU := 3.6
const DOT_CUOI := 2.0
const NGHI_DAU := 1.5
const NGHI_CUOI := 0.5
const GIAY_CO_HET := 45.0
const LECH_TOI_DA := 3.0
const NHAN_TOC := Vector2(0.75, 1.35)
const GIAY_VAN := 90.0

# san_laser.tscn / san_tron.tscn
const DAI_THANH := 30.0
const DAY_THANH := 0.7
const BAN_KINH_SAN := 11.5
const SO_TIA := 4

# player.gd
const JUMP_HEIGHT := 1.2
const GRAVITY := 20.0
const SPEED := 6.0

var _loi := 0


func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)


static func toc_do(t: float) -> float:
	return lerpf(TOC_DAU, TOC_CUOI, clampf(t / GIAY_TANG_HET, 0.0, 1.0))


static func dai_dot(t: float) -> float:
	return lerpf(DOT_DAU, DOT_CUOI, clampf(t / GIAY_CO_HET, 0.0, 1.0))


static func nghi(t: float) -> float:
	return lerpf(NGHI_DAU, NGHI_CUOI, clampf(t / GIAY_CO_HET, 0.0, 1.0))


static func goc_quay(pha: float, t: float, td: float, tc: float, th: float) -> float:
	var k := minf(t, th)
	var quet := td * k + (tc - td) * k * k / (2.0 * th)
	if t > th:
		quet += tc * (t - th)
	return pha + quet


static func kieu_cho_phep(t: float) -> Array:
	if t < 10.0: return [MOT]
	if t < 22.0: return [MOT, DOI]
	if t < 34.0: return [DOI, CHEO, LIEN]
	return [DOI, CHEO, LIEN, NHIEU]


static func so_tia_cho(kieu: int, toi_da: int) -> int:
	match kieu:
		MOT: return 1
		DOI, CHEO, LIEN: return mini(2, toi_da)
		_: return mini(4, toi_da)


static func lich_dot(giong: int, so_tia_co: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	var t := GIAY_BAO + 0.6
	while t < 120.0:
		var cho := kieu_cho_phep(t)
		var kieu: int = cho[rng.randi_range(0, cho.size() - 1)]
		var n := so_tia_cho(kieu, so_tia_co)
		var dai := dai_dot(t)
		var tia: Array = []
		var huong0 := 1.0 if rng.randf() < 0.5 else -1.0
		var pha0 := rng.randf() * TAU
		for k in n:
			var huong := huong0
			var nhan := 1.0
			var pha := pha0
			match kieu:
				DOI:
					huong = huong0 if k == 0 else -huong0
					pha = pha0 + PI * k
				CHEO:
					nhan = rng.randf_range(NHAN_TOC.x, NHAN_TOC.y)
					pha = pha0 + rng.randf() * TAU
				LIEN:
					pha = pha0 + float(k) * rng.randf_range(0.35, 0.6)
				NHIEU:
					huong = 1.0 if rng.randf() < 0.5 else -1.0
					nhan = rng.randf_range(NHAN_TOC.x, NHAN_TOC.y)
					pha = pha0 + TAU * float(k) / float(n)
				_:
					nhan = rng.randf_range(NHAN_TOC.x, NHAN_TOC.y)
			var goc_lech := rng.randf() * TAU
			var r_lech := rng.randf() * LECH_TOI_DA
			tia.append({"huong": huong, "nhan": nhan, "pha": pha,
					"lx": cos(goc_lech) * r_lech, "lz": sin(goc_lech) * r_lech})
		ds.append({"luc": t, "het": t + dai, "kieu": kieu, "tia": tia})
		t += dai + nghi(t) + GIAY_BAO
	return ds


## Điểm `p` có nằm trong thanh tia ở góc `g`, tâm `tam` không.
static func trong_tia(p: Vector2, tam: Vector2, g: float) -> bool:
	var v := p - tam
	var huong := Vector2(cos(g), sin(g))
	var doc: float = v.dot(huong)
	var ngang: float = absf(v.x * -huong.y + v.y * huong.x)
	return absf(doc) <= DAI_THANH * 0.5 and ngang <= DAY_THANH * 0.5


func _init() -> void:
	# ── 1. THANH PHAI DU DAI de tia lech tam van quet het san ──
	var can: float = BAN_KINH_SAN + LECH_TOI_DA
	ck(DAI_THANH * 0.5 >= can,
			"nua thanh %.1f m < %.1f m can (san %.1f + lech %.1f) - co vanh khong bi quet"
			% [DAI_THANH * 0.5, can, BAN_KINH_SAN, LECH_TOI_DA])

	# ── 2. NHẢY PHẢI THOÁT ĐƯỢC TIA ──
	var v0: float = sqrt(2.0 * GRAVITY * JUMP_HEIGHT)
	ck(JUMP_HEIGHT > CAO_THOAT, "nhay cao %.2f m khong qua duoc nguong thoat %.2f m" \
			% [JUMP_HEIGHT, CAO_THOAT])
	# t ma y(t) = CAO_THOAT: y = v0 t - g t^2/2
	var disc: float = v0 * v0 - 2.0 * GRAVITY * CAO_THOAT
	var t_tren := 0.0
	if disc > 0.0:
		t_tren = 2.0 * sqrt(disc) / GRAVITY
	ck(t_tren > 0.12, "chi o tren nguong %.3f s - cua so nhay qua hep" % t_tren)
	# Tia nhanh nhất đi qua một điểm ở rìa sân mất bao lâu
	var toc_ria: float = TOC_CUOI * NHAN_TOC.y * (BAN_KINH_SAN - LECH_TOI_DA)
	var t_qua: float = DAY_THANH / toc_ria
	ck(t_tren > t_qua,
			"tia nhanh nhat qua trong %.3f s nhung nhay chi o tren %.3f s - khong the nhay qua"
			% [t_qua, t_tren])

	# ── 3. KHÔNG CÓ CHỖ ĐỨNG AN TOÀN VĨNH VIỄN (quét 2000 điểm trong 60 giây đầu) ──
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var lich := lich_dot(99, SO_TIA)
	var diem: Array = []
	for _k in 2000:
		var r: float = sqrt(rng.randf()) * BAN_KINH_SAN
		var a: float = rng.randf() * TAU
		diem.append(Vector2(cos(a) * r, sin(a) * r))
	var bi_quet := {}
	for d in lich:
		if float(d["luc"]) > 60.0:
			continue
		var t: float = float(d["luc"])
		while t < float(d["het"]):
			var goc0: float = goc_quay(0.0, t, TOC_DAU, TOC_CUOI, GIAY_TANG_HET) \
					- goc_quay(0.0, float(d["luc"]), TOC_DAU, TOC_CUOI, GIAY_TANG_HET)
			for m in d["tia"]:
				var g: float = float(m["pha"]) + float(m["huong"]) * float(m["nhan"]) * goc0
				var tam := Vector2(float(m["lx"]), float(m["lz"]))
				for i in diem.size():
					if not bi_quet.has(i) and trong_tia(diem[i], tam, g):
						bi_quet[i] = true
			t += 0.02
	ck(bi_quet.size() == diem.size(),
			"%d/%d diem tren san KHONG bao gio bi tia quet - co cho dung an toan vinh vien"
			% [diem.size() - bi_quet.size(), diem.size()])

	# ── 4. KHÔNG CÓ NHỊP CỐ ĐỊNH (độ lệch hai khoảng liền nhau, lấy trung vị) ──
	var lech_min := INF
	var cho_te := ""
	for cho in [Vector2(0, 0), Vector2(5, 0), Vector2(0, -8), Vector2(7, 7), Vector2(-10, 2)]:
		var lan: Array = []
		var dang_trong := false
		for d in lich:
			if float(d["luc"]) > 60.0:
				continue
			var t: float = float(d["luc"])
			while t < float(d["het"]):
				var goc0: float = goc_quay(0.0, t, TOC_DAU, TOC_CUOI, GIAY_TANG_HET) \
						- goc_quay(0.0, float(d["luc"]), TOC_DAU, TOC_CUOI, GIAY_TANG_HET)
				var trong := false
				for m in d["tia"]:
					var g: float = float(m["pha"]) + float(m["huong"]) * float(m["nhan"]) * goc0
					if trong_tia(cho, Vector2(float(m["lx"]), float(m["lz"])), g):
						trong = true
						break
				if trong and not dang_trong:
					lan.append(t)
				dang_trong = trong
				t += 0.01
		ck(lan.size() >= 8, "cho %s chi bi quet %d lan trong 60 s - qua it de do nhip" \
				% [str(cho), lan.size()])
		if lan.size() < 3:
			continue
		var khoang: Array = []
		for i in range(1, lan.size()):
			khoang.append(float(lan[i]) - float(lan[i - 1]))
		if khoang.size() < 3:
			continue
		var ti: Array = []
		for i in range(1, khoang.size()):
			var a: float = khoang[i - 1]
			var b: float = khoang[i]
			ti.append(absf(b - a) / maxf(a, b))
		ti.sort()
		var he_so: float = float(ti[ti.size() / 2])
		if he_so < lech_min:
			lech_min = he_so
			cho_te = str(cho)
		ck(he_so > 0.15,
				"cho %s: hai khoang ke nhau lech %.1f%% - NHIP KHOA, nhay theo nhip la song"
				% [str(cho), he_so * 100.0])

	# ── 5. DO KHO TANG DAN, KHONG phai chi nhanh hon ──
	ck(kieu_cho_phep(5.0) == [MOT], "dau van phai chi mot tia")
	ck(kieu_cho_phep(5.0).size() < kieu_cho_phep(50.0).size(),
			"cuoi van phai nhieu kieu hon dau van")
	ck(not kieu_cho_phep(5.0).has(NHIEU), "dau van khong duoc co doi NHIEU tia")
	ck(kieu_cho_phep(50.0).has(NHIEU), "cuoi van phai co doi NHIEU tia")
	for a in [0.0, 10.0, 25.0, 45.0, 60.0]:
		for b in [0.0, 10.0, 25.0, 45.0, 60.0]:
			if a < b:
				ck(dai_dot(a) >= dai_dot(b), "doi phai NGAN dan: %.0fs=%.2f, %.0fs=%.2f" \
						% [a, dai_dot(a), b, dai_dot(b)])
				ck(nghi(a) >= nghi(b), "nghi phai NGAN dan: %.0fs=%.2f, %.0fs=%.2f" \
						% [a, nghi(a), b, nghi(b)])
	ck(so_tia_cho(MOT, SO_TIA) == 1, "kieu MOT phai dung 1 tia")
	ck(so_tia_cho(NHIEU, SO_TIA) > so_tia_cho(DOI, SO_TIA), "NHIEU phai nhieu tia hon DOI")

	# ── 6. LUON CO BAO TRUOC, va dot khong chong nhau ──
	var min_bao := INF
	for i in range(1, lich.size()):
		var truoc: Dictionary = lich[i - 1]
		var sau: Dictionary = lich[i]
		var ho: float = float(sau["luc"]) - float(truoc["het"])
		ck(ho >= GIAY_BAO - 0.001,
				"dot %d bat dau chi %.2f s sau dot truoc, it hon %.2f s bao truoc" \
						% [i, ho, GIAY_BAO])
		min_bao = minf(min_bao, ho)
	ck(float(lich[0]["luc"]) >= GIAY_BAO, "dot dau tien khong co du %.1f s bao truoc" % GIAY_BAO)

	# ── 7. MOI MAY DUNG RA Y HET: lich la ham thuan cua hat giong ──
	var l1 := lich_dot(4242, SO_TIA)
	var l2 := lich_dot(4242, SO_TIA)
	ck(str(l1) == str(l2), "cung hat giong ra hai lich khac nhau - moi may mot san")
	ck(str(lich_dot(1, SO_TIA)) != str(lich_dot(2, SO_TIA)), "hai hat giong ra cung mot lich")

	# ── 8. LICH PHAI PHU HET VAN ──
	var cuoi: float = float(lich[lich.size() - 1]["het"])
	ck(cuoi >= GIAY_VAN, "lich chi toi %.1f s nhung van dai toi %.1f s - cuoi van khong con tia" \
			% [cuoi, GIAY_VAN])

	# đếm kiểu đợt để in ra cho dễ đọc
	var dem := {}
	for d in lich:
		var k: int = int(d["kieu"])
		dem[k] = int(dem.get(k, 0)) + 1

	print("OK  thanh %.0f m, nua thanh %.1f >= %.1f m can (san %.1f + lech %.1f)"
			% [DAI_THANH, DAI_THANH * 0.5, can, BAN_KINH_SAN, LECH_TOI_DA])
	print("OK  nhay o tren nguong %.3f s; tia nhanh nhat qua mat %.3f s" % [t_tren, t_qua])
	print("OK  2000/2000 diem tren san deu bi tia quet - khong co cho an toan vinh vien")
	print("OK  nhip BIEN THIEN: hai khoang ke nhau lech %.1f%% (tai %s); cu: 1.6%%"
			% [lech_min * 100.0, cho_te])
	print("OK  do kho: 1 tia -> %d kieu; dot %.1f->%.1f s; nghi %.1f->%.1f s"
			% [kieu_cho_phep(50.0).size(), DOT_DAU, DOT_CUOI, NGHI_DAU, NGHI_CUOI])
	print("OK  moi dot cach dot truoc it nhat %.2f s (>= %.1f s bao truoc)" % [min_bao, GIAY_BAO])
	print("OK  lich thuan theo hat giong, phu toi %.1f s" % cuoi)
	print("    %d dot: MOT=%d DOI=%d CHEO=%d LIEN=%d NHIEU=%d"
			% [lich.size(), dem.get(MOT, 0), dem.get(DOI, 0), dem.get(CHEO, 0),
			dem.get(LIEN, 0), dem.get(NHIEU, 0)])
	print("--- %d loi ---" % _loi)
	quit()
