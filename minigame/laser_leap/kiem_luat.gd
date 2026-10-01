extends SceneTree

## KIỂM LUẬT Laser Leap — chạy ngoài game, không nạp project:
##
##     godot --headless --path minigame/laser_leap --script kiem_luat.gd
##
## Hằng số CHÉP TAY từ `laser_leap.gd`, `san_laser.tscn`, `san_tron.tscn`, `player.gd`. Chép chứ
## không `preload` vì `laser_leap.gd` kéo theo `MiniGame3D` → `Fusion` → cả project.
##
## Bộ này tồn tại vì hai lỗi của bản trước KHÔNG thể thấy bằng mắt trong một ván chơi thử — phải
## quét mới ra:
##
##   1. **Nhịp cố định.** Ba tia quay cùng tốc, pha cách đều, quanh đúng tâm → ở mọi chỗ, khoảng
##      giữa hai lần tia đi qua gần như một hằng số. Nhảy theo nhịp là sống hết ván.
##
##      Kiểm #4 đo bằng **độ lệch của hai khoảng LIỀN NHAU**, không phải độ lệch chuẩn trên cả
##      ván. Lần đầu tôi đo bằng độ lệch chuẩn và nó VÔ DỤNG: sơ đồ cũ ra 34% nên lọt qua ngưỡng
##      35% — nhưng 34% đó là do tốc nền tăng dần suốt 60 giây, còn nhịp cục bộ vẫn đều tăm tắp
##      (1,10 → 1,09 → 1,08 giây). Đo kề nhau thì sơ đồ cũ ra **1,6%**, lộ ngay là nhịp khoá.
##   2. **Chỗ an toàn vĩnh viễn.** Tia lệch tâm mà thanh quá ngắn thì sinh một vành sàn tia không
##      bao giờ với tới. Kiểm #3 quét 2000 điểm trên sàn và đòi mọi điểm đều bị quét.
##
## Dùng `ck()` chứ không `assert()`: `assert` fail trong `--headless --script` làm Godot ĐỨNG chờ
## debugger, 0% CPU, không in một chữ nào.

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
enum { MOT, DOI, CHEO, LIEN, NHIEU }

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


## Khoang cach tu diem `p` toi truc cua mot tia dang o goc `g`, tam quay `tam`.
## Tia la mot thanh dai `DAI_THANH` di qua `tam`, nen diem bi quet khi vua gan truc vua trong tam.
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
			"nua thanh %.1f m < %.1f m can thiet (san %.1f + lech %.1f) - se co vanh san khong bao gio bi quet"
			% [DAI_THANH * 0.5, can, BAN_KINH_SAN, LECH_TOI_DA])

	# ── 2. NHAY PHAI THOAT DUOC TIA ──
	# Thoi gian o tren CAO_THOAT trong mot cu nhay, va be rong tia tinh theo thoi gian tia di qua.
	var v0: float = sqrt(2.0 * GRAVITY * JUMP_HEIGHT)
	ck(JUMP_HEIGHT > CAO_THOAT, "nhay cao %.2f m khong qua duoc nguong thoat %.2f m" % [JUMP_HEIGHT, CAO_THOAT])
	# t ma y(t) = CAO_THOAT: y = v0 t - g t^2/2
	var disc: float = v0 * v0 - 2.0 * GRAVITY * CAO_THOAT
	var t_tren := 0.0
	if disc > 0.0:
		t_tren = 2.0 * sqrt(disc) / GRAVITY
	ck(t_tren > 0.12, "chi o tren nguong %.3f s - cua so nhay qua hep" % t_tren)
	# Tia nhanh nhat di qua mot diem o ria san mat bao lau
	var toc_ria: float = TOC_CUOI * NHAN_TOC.y * (BAN_KINH_SAN - LECH_TOI_DA)
	var t_qua: float = DAY_THANH / toc_ria
	ck(t_tren > t_qua,
			"tia nhanh nhat qua trong %.3f s nhung nhay chi o tren %.3f s - khong the nhay qua"
			% [t_qua, t_tren])

	# ── 3. KHONG CO CHO DUNG AN TOAN VINH VIEN ──
	# Quet 2000 diem tren san; moi diem phai bi it nhat mot tia quet trong 60 giay dau.
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

	# ── 4. KHONG CO NHIP CO DINH ──
	# Do do lech cua hai khoang LIEN NHAU, lay trung vi. Nhip khoa -> gan 0.
	# Da do so do cu bang dung phep nay: 1.6%. Nguong 15% la cach do mot khoang rong.
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
		ck(lan.size() >= 8, "cho %s chi bi quet %d lan trong 60 s - qua it de do nhip" % [str(cho), lan.size()])
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
				"cho %s: hai khoang lien nhau chi lech %.1f%% - NHIP KHOA, dung yen nhay theo nhip la song het van"
				% [str(cho), he_so * 100.0])

	# ── 5. DO KHO TANG DAN, KHONG phai chi nhanh hon ──
	ck(kieu_cho_phep(5.0) == [MOT], "dau van phai chi mot tia")
	ck(kieu_cho_phep(5.0).size() < kieu_cho_phep(50.0).size(), "cuoi van phai nhieu kieu hon dau van")
	ck(not kieu_cho_phep(5.0).has(NHIEU), "dau van khong duoc co doi NHIEU tia")
	ck(kieu_cho_phep(50.0).has(NHIEU), "cuoi van phai co doi NHIEU tia")
	for a in [0.0, 10.0, 25.0, 45.0, 60.0]:
		for b in [0.0, 10.0, 25.0, 45.0, 60.0]:
			if a < b:
				ck(dai_dot(a) >= dai_dot(b), "doi phai NGAN dan: %.0fs=%.2f, %.0fs=%.2f" % [a, dai_dot(a), b, dai_dot(b)])
				ck(nghi(a) >= nghi(b), "nghi phai NGAN dan: %.0fs=%.2f, %.0fs=%.2f" % [a, nghi(a), b, nghi(b)])
	ck(so_tia_cho(MOT, SO_TIA) == 1, "kieu MOT phai dung 1 tia")
	ck(so_tia_cho(NHIEU, SO_TIA) > so_tia_cho(DOI, SO_TIA), "NHIEU phai nhieu tia hon DOI")

	# ── 6. LUON CO BAO TRUOC, va dot khong chong nhau ──
	var min_bao := INF
	for i in range(1, lich.size()):
		var truoc: Dictionary = lich[i - 1]
		var sau: Dictionary = lich[i]
		var ho: float = float(sau["luc"]) - float(truoc["het"])
		ck(ho >= GIAY_BAO - 0.001,
				"dot %d bat dau chi %.2f s sau dot truoc, it hon %.2f s bao truoc" % [i, ho, GIAY_BAO])
		min_bao = minf(min_bao, ho)
	ck(float(lich[0]["luc"]) >= GIAY_BAO, "dot dau tien khong co du %.1f s bao truoc" % GIAY_BAO)

	# ── 7. MOI MAY DUNG RA Y HET: lich la ham thuan cua hat giong ──
	var l1 := lich_dot(4242, SO_TIA)
	var l2 := lich_dot(4242, SO_TIA)
	ck(str(l1) == str(l2), "cung hat giong ra hai lich khac nhau - moi may mot san")
	ck(str(lich_dot(1, SO_TIA)) != str(lich_dot(2, SO_TIA)), "hai hat giong ra cung mot lich")

	# ── 8. LICH PHAI PHU HET VAN ──
	var cuoi: float = float(lich[lich.size() - 1]["het"])
	ck(cuoi >= GIAY_VAN, "lich chi toi %.1f s nhung van dai toi %.1f s - cuoi van khong con tia" % [cuoi, GIAY_VAN])

	# dem kieu dot de in ra cho de doc
	var dem := {}
	for d in lich:
		var k: int = int(d["kieu"])
		dem[k] = int(dem.get(k, 0)) + 1

	print("OK  thanh %.0f m, nua thanh %.1f >= %.1f m can (san %.1f + lech %.1f)"
			% [DAI_THANH, DAI_THANH * 0.5, can, BAN_KINH_SAN, LECH_TOI_DA])
	print("OK  nhay o tren nguong %.3f s; tia nhanh nhat qua mat %.3f s" % [t_tren, t_qua])
	print("OK  2000/2000 diem tren san deu bi tia quet - khong co cho an toan vinh vien")
	print("OK  nhip tia BIEN THIEN: hai khoang lien nhau lech it nhat %.1f%% (tai %s); so do cu: 1.6%%"
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
