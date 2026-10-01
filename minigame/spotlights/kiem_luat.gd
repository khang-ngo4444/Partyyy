extends SceneTree

## KIỂM LUẬT Searing Spotlights — chạy ngoài game, không nạp project:
##
##     godot --headless --path minigame/spotlights --script kiem_luat.gd
##
## Hằng số CHÉP TAY từ `spotlights.gd`, `san_spot.tscn`, `san_tron.tscn`, `player.gd`. Chép chứ
## không `preload` vì `spotlights.gd` kéo theo `MiniGame3D` → `Fusion` → cả project.
##
## Hai thứ bộ này tồn tại để chặn, cả hai đều KHÔNG thấy được trong một ván chơi thử:
##
##   1. **Sáng phủ kín sàn.** Nón đèn cũ 18° rọi vệt bán kính 3,9 m; 8 đèn là ~92% sàn. Chơi thử
##      3 đèn thì thấy thoải mái, tới chu kỳ 6 mới hết chỗ đi — mà lúc đó không ai còn đang test.
##      Kiểm #5 quét sàn ở 600 mốc thời gian và đo phần sàn bị sáng.
##   2. **Chuyển sáng tắt phụp.** `do_sang()` phải LIÊN TỤC; một bậc nhảy là tối đột ngột, đúng
##      cái mục 4 của spec cấm. Kiểm #2 đo bước nhảy lớn nhất giữa hai khung hình.
##
## Dùng `ck()` chứ không `assert()`: `assert` fail trong `--headless --script` làm Godot ĐỨNG chờ
## debugger, 0% CPU, không in một chữ nào.

# spotlights.gd
const MAU_TOI_DA := 100.0
const MAT_MAU_MOI_GIAY := 40.0
const TAM_QUET := 6.2
const GIAY_SANG := 4.0
const GIAY_MO := 1.6
const GIAY_TOI := 6.5
const GIAY_SANG_LAI := 1.4
const CHU_KY := GIAY_SANG + GIAY_MO + GIAY_TOI + GIAY_SANG_LAI
const DEN_DAU := 3
const DEN_TOI_DA := 8
const BAN_KINH_GIU := 11.0
const GIAY_VAN := 75.0

# san_spot.tscn / san_tron.tscn
const SO_DEN_CO := 8
const BAN_KINH_DEN := 2.66
const BAN_KINH_SAN := 11.5
const NHIP_TU := 0.28
const NHIP_DEN := 0.52

# player.gd
const SPEED := 6.0

var _loi := 0

func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)

static func cho_den(pha: float, nhip: float, t: float) -> Vector2:
	return Vector2(sin(t * nhip + pha) * TAM_QUET,
			sin(t * nhip * 1.37 + pha * 2.0) * TAM_QUET)

static func chu_ky_thu(t: float) -> int:
	return int(t / CHU_KY)

static func so_den(t: float) -> int:
	return mini(DEN_DAU + chu_ky_thu(t), DEN_TOI_DA)

static func do_sang(t: float) -> float:
	var u := fposmod(t, CHU_KY)
	if u < GIAY_SANG:
		return 1.0
	u -= GIAY_SANG
	if u < GIAY_MO:
		return 1.0 - u / GIAY_MO
	u -= GIAY_MO
	if u < GIAY_TOI:
		return 0.0
	return (u - GIAY_TOI) / GIAY_SANG_LAI


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261001
	# Pha va nhip cua 8 den, dung nhu `_dung_san()` gieo
	var pha := PackedFloat32Array()
	var nhip := PackedFloat32Array()
	for _i in SO_DEN_CO:
		pha.append(rng.randf() * TAU)
		nhip.append(rng.randf_range(NHIP_TU, NHIP_DEN))

	# ── 1. CHU KY: bon chang phai co that va du dai ──
	ck(is_equal_approx(CHU_KY, GIAY_SANG + GIAY_MO + GIAY_TOI + GIAY_SANG_LAI),
			"CHU_KY khong bang tong bon chang")
	ck(GIAY_SANG >= 3.0, "chang SANG chi %.1f s - khong du de nhin va nho cho minh" % GIAY_SANG)
	ck(GIAY_TOI >= 4.0, "chang TOI chi %.1f s - khong du de di trong toi" % GIAY_TOI)
	ck(GIAY_MO >= 1.0, "toi dan chi %.1f s - gan nhu tat phut" % GIAY_MO)
	ck(GIAY_SANG_LAI >= 1.0, "sang lai chi %.1f s - gan nhu bat phut" % GIAY_SANG_LAI)
	# Toi phai dai hon sang: phan choi that la luc toi
	ck(GIAY_TOI > GIAY_SANG, "toi (%.1f s) phai dai hon sang (%.1f s)" % [GIAY_TOI, GIAY_SANG])

	# ── 2. CHUYEN SANG PHAI LIEN TUC, khong tat phut ──
	var buoc_lon := 0.0
	var tai := 0.0
	var d := 1.0 / 60.0
	var t := 0.0
	while t < CHU_KY * 3.0:
		var b: float = absf(do_sang(t + d) - do_sang(t))
		if b > buoc_lon:
			buoc_lon = b
			tai = fposmod(t, CHU_KY)
		t += d
	# Doc dan nhanh nhat: 1.0 / (GIAY_SANG_LAI * 60) moi khung hinh
	var cho_phep: float = 1.0 / (minf(GIAY_MO, GIAY_SANG_LAI) * 60.0) * 1.5
	ck(buoc_lon <= cho_phep,
			"do sang nhay %.4f trong mot khung hinh (tai u=%.2f s), cho phep %.4f - TAT PHUT"
			% [buoc_lon, tai, cho_phep])

	# ── 3. DO SANG PHAI CHAY HET TAM 0..1 ──
	var min_s := INF
	var max_s := -INF
	var giay_sang_han := 0.0
	var giay_toi_han := 0.0
	t = 0.0
	while t < CHU_KY:
		var s := do_sang(t)
		min_s = minf(min_s, s)
		max_s = maxf(max_s, s)
		if s >= 0.999: giay_sang_han += d
		if s <= 0.001: giay_toi_han += d
		t += d
	ck(min_s <= 0.001, "khong bao gio toi han: thap nhat %.3f" % min_s)
	ck(max_s >= 0.999, "khong bao gio sang han: cao nhat %.3f" % max_s)
	ck(giay_sang_han > 3.0, "chi sang han %.2f s moi chu ky" % giay_sang_han)
	ck(giay_toi_han > 4.0, "chi toi han %.2f s moi chu ky" % giay_toi_han)

	# ── 4. PROGRESSION: 3 den tang dan tung chu ky, khong vuot so node co that ──
	ck(so_den(0.0) == DEN_DAU, "chu ky 1 phai %d den, dang %d" % [DEN_DAU, so_den(0.0)])
	var truoc := 0
	var moc: Array = []
	for c in 8:
		var tt: float = c * CHU_KY + 1.0
		var n := so_den(tt)
		moc.append(n)
		ck(n >= truoc, "so den TUT o chu ky %d: %d -> %d" % [c + 1, truoc, n])
		ck(n <= SO_DEN_CO, "chu ky %d doi %d den nhung san chi co %d node" % [c + 1, n, SO_DEN_CO])
		truoc = n
	for c in 5:
		var a := so_den(c * CHU_KY + 1.0)
		var b := so_den((c + 1) * CHU_KY + 1.0)
		ck(b == a + 1, "chu ky %d -> %d phai tang dung 1 den, dang %d -> %d" % [c + 1, c + 2, a, b])
	var ck_cuoi := chu_ky_thu(GIAY_VAN - 0.01)
	ck(so_den(GIAY_VAN - 0.01) == DEN_TOI_DA,
			"het van (%.0f s = chu ky %d) moi %d den, chua dat tran %d - progression cham"
			% [GIAY_VAN, ck_cuoi + 1, so_den(GIAY_VAN - 0.01), DEN_TOI_DA])

	# ── 5. SAN KHONG BAO GIO BI SANG PHU KIN ──
	# Quet luoi diem tren san, do phan bi den chieu, o 600 moc thoi gian trai ca van.
	var diem: Array = []
	var b := -BAN_KINH_SAN
	while b <= BAN_KINH_SAN:
		var z := -BAN_KINH_SAN
		while z <= BAN_KINH_SAN:
			if Vector2(b, z).length() <= BAN_KINH_GIU:
				diem.append(Vector2(b, z))
			z += 0.5
		b += 0.5
	var phu_max := 0.0
	var phu_tong := 0.0
	var phu_dem := 0
	var phu_tai := 0.0
	var buoc_t: float = GIAY_VAN / 600.0
	t = 0.0
	while t < GIAY_VAN:
		var n := so_den(t)
		var tam: Array = []
		for i in n:
			tam.append(cho_den(pha[i], nhip[i], t))
		var trong := 0
		for p in diem:
			for c in tam:
				if (p - c).length() <= BAN_KINH_DEN:
					trong += 1
					break
		var ti: float = float(trong) / float(diem.size())
		if ti > phu_max:
			phu_max = ti
			phu_tai = t
		phu_tong += ti
		phu_dem += 1
		t += buoc_t
	var phu_tb: float = phu_tong / float(phu_dem)
	ck(phu_max < 0.60,
			"co luc %.0f%% san bi sang (giay %.1f, %d den) - gan nhu khong con cho de di"
			% [phu_max * 100.0, phu_tai, so_den(phu_tai)])
	ck(phu_tb < 0.35, "trung binh %.0f%% san bi sang ca van - qua chat" % [phu_tb * 100.0])
	# Nhung cung phai CO nguy hiem that
	ck(phu_tb > 0.05, "trung binh chi %.1f%% san bi sang - den khong ep duoc ai" % [phu_tb * 100.0])

	# ── 6. DEN PHAI NAM TRONG SAN, khong chay ra ngoai ──
	var xa_nhat := 0.0
	t = 0.0
	while t < GIAY_VAN:
		for i in SO_DEN_CO:
			xa_nhat = maxf(xa_nhat, cho_den(pha[i], nhip[i], t).length())
		t += 0.05
	ck(xa_nhat + BAN_KINH_DEN <= BAN_KINH_SAN + 0.5,
			"tam den ra toi %.2f m, cong vet %.2f m la %.2f m > san %.2f m - den roi ra ngoai san"
			% [xa_nhat, BAN_KINH_DEN, xa_nhat + BAN_KINH_DEN, BAN_KINH_SAN])

	# ── 7. CHAY RA DUOC: nguoi phai nhanh hon den ──
	var toc_den_max := 0.0
	t = 0.0
	while t < GIAY_VAN:
		for i in SO_DEN_CO:
			var v: float = (cho_den(pha[i], nhip[i], t + 0.02)
					- cho_den(pha[i], nhip[i], t)).length() / 0.02
			toc_den_max = maxf(toc_den_max, v)
		t += 0.05
	ck(SPEED > toc_den_max,
			"den chay toi %.2f m/s, nguoi chi %.2f m/s - khong chay ra khoi den duoc"
			% [toc_den_max, SPEED])
	# Thoat khoi vung sang mat bao lau, so voi thoi gian chet.
	#
	# Mo phong that chu khong lay `BAN_KINH_DEN / (SPEED - toc_den)`: cong thuc do gia dinh nguoi
	# chay dua CUNG HUONG voi den, va khi den gan nhanh bang nguoi thi no ra 266 giay - vo nghia.
	# Nguoi that thoat bang cach di VUONG GOC voi huong den dang chay.
	var giay_chet: float = MAU_TOI_DA / MAT_MAU_MOI_GIAY
	var thoat_lau_nhat := 0.0
	var thoat_tai := 0.0
	t = 0.0
	while t < GIAY_VAN:
		for i in SO_DEN_CO:
			var c0 := cho_den(pha[i], nhip[i], t)
			var v := (cho_den(pha[i], nhip[i], t + 0.02) - c0) / 0.02
			if v.length() < 0.01:
				continue
			# nguoi dung giua vung sang, chay vuong goc voi huong den
			var ra := Vector2(-v.y, v.x).normalized()
			var p := c0
			var tt := 0.0
			while tt < giay_chet * 2.0:
				p += ra * SPEED * 0.02
				tt += 0.02
				if (p - cho_den(pha[i], nhip[i], t + tt)).length() > BAN_KINH_DEN:
					break
			if tt > thoat_lau_nhat:
				thoat_lau_nhat = tt
				thoat_tai = t
			t += 0.0
		t += 0.37
	ck(thoat_lau_nhat < giay_chet,
			"xau nhat thoat den %.2f s (giay %.1f) > chet sau %.2f s - vao den la chet"
			% [thoat_lau_nhat, thoat_tai, giay_chet])

	# ── 8. DUONG DI DEN KHONG LAP LAI trong mot van (nho duong di la vo ich) ──
	# So vi tri den 0 o thoi diem t voi t + chu ky, tren ca van.
	var lap := 0
	var mau_t := 0
	t = 0.0
	while t + CHU_KY < GIAY_VAN:
		var a := cho_den(pha[0], nhip[0], t)
		var bb := cho_den(pha[0], nhip[0], t + CHU_KY)
		if (a - bb).length() < 0.5:
			lap += 1
		mau_t += 1
		t += 0.1
	var ti_lap: float = float(lap) / float(maxi(mau_t, 1))
	ck(ti_lap < 0.2,
			"%.0f%% thoi diem den ve dung cho cu sau mot chu ky - duong di lap, nho duoc"
			% [ti_lap * 100.0])

	# ── 9. KEP NGUOI TRONG SAN ──
	ck(BAN_KINH_GIU < BAN_KINH_SAN, "kep %.1f m >= san %.1f m - nguoi ra duoc ngoai bo" \
			% [BAN_KINH_GIU, BAN_KINH_SAN])
	ck(BAN_KINH_SAN - BAN_KINH_GIU >= 0.4, "kep sat bo qua (%.2f m) - than lo ra ngoai" \
			% (BAN_KINH_SAN - BAN_KINH_GIU))

	print("OK  chu ky %.1f s = sang %.1f + mo %.1f + toi %.1f + sang lai %.1f"
			% [CHU_KY, GIAY_SANG, GIAY_MO, GIAY_TOI, GIAY_SANG_LAI])
	print("OK  chuyen sang LIEN TUC: buoc lon nhat %.4f/khung (cho phep %.4f)" \
			% [buoc_lon, cho_phep])
	print("OK  moi chu ky: sang han %.1f s, toi han %.1f s" % [giay_sang_han, giay_toi_han])
	print("OK  progression %s den qua %d chu ky, tran %d khi het van" \
			% [str(moc.slice(0, 6)), 6, DEN_TOI_DA])
	print("OK  san bi sang: trung binh %.0f%%, cao nhat %.0f%% (giay %.1f, %d den)"
			% [phu_tb * 100.0, phu_max * 100.0, phu_tai, so_den(phu_tai)])
	print("OK  den xa nhat %.2f m + vet %.2f m = %.2f m, trong san %.1f m" \
			% [xa_nhat, BAN_KINH_DEN, xa_nhat + BAN_KINH_DEN, BAN_KINH_SAN])
	print("OK  den %.2f m/s < nguoi %.1f m/s; thoat (vuong goc) xau nhat %.2f s < chet %.2f s"
			% [toc_den_max, SPEED, thoat_lau_nhat, giay_chet])
	print("OK  duong di den khong lap: %.0f%% thoi diem trung cho cu" % [ti_lap * 100.0])
	print("--- %d loi ---" % _loi)
	quit()
