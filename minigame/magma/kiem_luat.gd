extends SceneTree

## Kiểm luật Magma & Mages: godot --headless --path minigame/magma --script kiem_luat.gd
## Chặn vành cảnh báo mỏng tới mức không thấy (#3). Hằng số chép tay; dùng `ck()` thay `assert`.

# magma.gd
const SO_CHANG := 5
const CO_CON := 0.40
const CHO_TRUOC_KHI_CO := 10.0
const GIAY_MOI_CHANG := 11.0
const GIAY_BAO := 4.0
const MAU_TOI_DA := 100.0
const MAT_MAU_MOI_GIAY := 22.0
const DAY_NGANG := 11.0
const GIAY_VAN := 75.0
const NGHI_BAN := 0.7

# san_tron.tscn / cau_lua.gd / player.gd
const BAN_KINH_SAN := 11.5
const TOC_CAU := 16.0
const SONG_CAU := 1.6
const SPEED := 6.0

var _loi := 0

func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)

static func chang(t: float) -> int:
	if t < CHO_TRUOC_KHI_CO:
		return 0
	return mini(1 + int((t - CHO_TRUOC_KHI_CO) / GIAY_MOI_CHANG), SO_CHANG)

static func luc_co_ke_tiep(t: float) -> float:
	var c := chang(t)
	if c >= SO_CHANG:
		return INF
	return CHO_TRUOC_KHI_CO + float(c) * GIAY_MOI_CHANG

static func ti_le_san(t: float) -> float:
	return lerpf(1.0, CO_CON, float(chang(t)) / float(SO_CHANG))

static func ti_le_bao(t: float) -> float:
	var ke := luc_co_ke_tiep(t)
	if ke == INF or t < ke - GIAY_BAO:
		return ti_le_san(t)
	return lerpf(1.0, CO_CON, float(chang(t) + 1) / float(SO_CHANG))

static func dang_bao(t: float) -> bool:
	return not is_equal_approx(ti_le_bao(t), ti_le_san(t))

static func ban_kinh(t: float) -> float:
	return ti_le_san(t) * BAN_KINH_SAN

static func dien_tich(t: float) -> float:
	return PI * ban_kinh(t) * ban_kinh(t)


func _init() -> void:
	var d := 1.0 / 60.0

	# ── 1. VUNG AN TOAN CO DAN, khong bao gio to ra lai ──
	var truoc := INF
	var so_lan_co := 0
	var moc: Array = []
	var t := 0.0
	while t < GIAY_VAN:
		var r := ban_kinh(t)
		ck(r <= truoc + 0.0001, "vung an toan TO RA o giay %.2f: %.2f -> %.2f" % [t, truoc, r])
		if r < truoc - 0.0001:
			if truoc < INF:
				so_lan_co += 1
			moc.append("%.1fs:%.2fm" % [t, r])
			truoc = r
		t += d
	ck(so_lan_co == SO_CHANG, "co %d lan, cho %d lan" % [so_lan_co, SO_CHANG])
	ck(is_equal_approx(ban_kinh(0.0), BAN_KINH_SAN), "dau van phai full san")
	ck(is_equal_approx(ban_kinh(GIAY_VAN - 0.1), CO_CON * BAN_KINH_SAN), "cuoi van phai la %.2f m" \
			% (CO_CON * BAN_KINH_SAN))

	# ── 2. AN TOÀN → CẢNH BÁO → NHAM: mỗi lần co có đủ GIAY_BAO giây báo trước ──
	for k in SO_CHANG:
		var luc_co: float = CHO_TRUOC_KHI_CO + float(k) * GIAY_MOI_CHANG
		ck(not dang_bao(luc_co - GIAY_BAO - 0.1),
				"giay %.1f da bao roi, som hon %.1f s truoc khi co" \
						% [luc_co - GIAY_BAO - 0.1, GIAY_BAO])
		ck(dang_bao(luc_co - GIAY_BAO + 0.1),
				"giay %.1f chua bao, dang ra phai bao tu %.1f s" \
						% [luc_co - GIAY_BAO + 0.1, luc_co - GIAY_BAO])
		ck(dang_bao(luc_co - 0.05), "ngay truoc lan co o %.1f s ma khong bao" % luc_co)
		# Vành được báo phải thành nham đúng lúc co
		var r_bao: float = ti_le_bao(luc_co - 0.05) * BAN_KINH_SAN
		var r_sau: float = ban_kinh(luc_co + 0.05)
		ck(absf(r_bao - r_sau) < 0.01,
				"vanh bao o %.1f s huu %.2f m nhung sau khi co lai la %.2f m - bao sai cho"
				% [luc_co, r_bao, r_sau])
	# Đã co hết thì không báo nữa
	ck(not dang_bao(GIAY_VAN - 1.0), "da co het ma van bao")

	# ── 3. VANH CANH BAO PHAI DU DAY DE THAY ──
	var mong_nhat := INF
	var mong_tai := 0.0
	var giay_bao_tong := 0.0
	t = 0.0
	while t < GIAY_VAN:
		if dang_bao(t):
			giay_bao_tong += d
			var w: float = (ti_le_san(t) - ti_le_bao(t)) * BAN_KINH_SAN
			if w < mong_nhat:
				mong_nhat = w
				mong_tai = t
		t += d
	ck(mong_nhat >= 1.0,
			"vanh canh bao chi rong %.2f m (giay %.1f) - nhin tu cam tren cao khong thay"
			% [mong_nhat, mong_tai])
	# So với bản co dần: co đều 1.0 → CO_CON trong (CO_HET - CHO) giây
	var co_deu: float = BAN_KINH_SAN * (1.0 - 0.45) / (55.0 - 12.0) * GIAY_BAO
	ck(mong_nhat > co_deu * 1.5,
			"vanh %.2f m khong hon han ban co deu (%.2f m) - doi sang chang de lam gi"
			% [mong_nhat, co_deu])

	# ── 4. KIP CHAY: tu mep vanh bao vao trong phai di duoc trong GIAY_BAO ──
	var xa_nhat := 0.0
	for k in SO_CHANG:
		var luc_co: float = CHO_TRUOC_KHI_CO + float(k) * GIAY_MOI_CHANG
		var w: float = (ti_le_san(luc_co - 0.05) - ti_le_bao(luc_co - 0.05)) * BAN_KINH_SAN
		xa_nhat = maxf(xa_nhat, w)
	var can_giay: float = xa_nhat / SPEED
	ck(can_giay < GIAY_BAO,
			"chay tu mep ngoai vanh vao trong mat %.2f s nhung chi bao %.1f s" \
					% [can_giay, GIAY_BAO])
	ck(GIAY_BAO / maxf(can_giay, 0.01) >= 3.0,
			"chi du %.1fx thoi gian can - gap qua, chua tinh viec dang danh nhau"
			% (GIAY_BAO / maxf(can_giay, 0.01)))

	# ── 5. DIEN TICH: dau rong, cuoi chat nhung KHONG phai khong the dung ──
	var dt_dau := dien_tich(0.0)
	var dt_giua := dien_tich(CHO_TRUOC_KHI_CO + 2.5 * GIAY_MOI_CHANG)
	var dt_cuoi := dien_tich(GIAY_VAN - 0.1)
	ck(dt_giua < dt_dau * 0.75, "giua van moi con %.0f%% dien tich - chua ep ai" \
			% (dt_giua / dt_dau * 100.0))
	ck(dt_cuoi < dt_giua * 0.75, "cuoi van con %.0f%% so voi giua - chua that chat" \
			% (dt_cuoi / dt_giua * 100.0))
	# 8 người cuối ván: mỗi người bao nhiêu m²
	var moi_nguoi: float = dt_cuoi / 8.0
	ck(moi_nguoi >= 4.0, "cuoi van chi %.1f m2 moi nguoi (8 nguoi) - chen nhau khong the dung" \
			% moi_nguoi)
	ck(moi_nguoi <= 20.0, "cuoi van con %.1f m2 moi nguoi - chua tao ap luc gi" % moi_nguoi)

	# ── 6. CHAY: dau du de phai bo ra, nhung bi hat vao mot cai KHONG phai la xong ──
	var giay_chet: float = MAU_TOI_DA / MAT_MAU_MOI_GIAY
	ck(giay_chet >= 3.0, "chay %.1f s la chet - bi hat vao nham mot cai la xong" % giay_chet)
	ck(giay_chet <= 8.0, "chay %.1f s moi chet - khong du dau de phai bo ra" % giay_chet)
	# Thoát khỏi nham mất bao lâu: xa nhất là từ mép sân vào mép vùng an toàn cuối ván
	var sau_nhat: float = BAN_KINH_SAN - CO_CON * BAN_KINH_SAN
	var giay_bo_ra: float = sau_nhat / SPEED
	ck(giay_bo_ra < giay_chet,
			"bi hat ra mep san cuoi van thi bo vao mat %.2f s nhung chet sau %.2f s"
			% [giay_bo_ra, giay_chet])

	# ── 7. CAU LUA: bay du xa de qua san, va la DON day chu khong phai don giet ──
	var tam_cau: float = TOC_CAU * SONG_CAU
	ck(tam_cau >= BAN_KINH_SAN * 2.0 * 0.9,
			"cau lua bay %.1f m nhung san rong %.1f m - khong ban toi nua san ben kia"
			% [tam_cau, BAN_KINH_SAN * 2.0])
	# Phải thấy cầu lửa kịp: cầu 16 m/s, phản ứng ~0.3 s → cần thấy từ ≥ 5 m
	ck(TOC_CAU * 0.3 < BAN_KINH_SAN, "cau di %.1f m trong 0.3 s - gan nhu khong ne duoc" \
			% (TOC_CAU * 0.3))
	ck(TOC_CAU > SPEED, "cau %.1f m/s khong nhanh hon nguoi %.1f m/s - di bo cung ne duoc" \
			% [TOC_CAU, SPEED])
	# Nhịp bắn: không được thành vòi lửa liền mạch
	ck(NGHI_BAN >= 0.4, "nghi ban %.2f s - giu phim la mot voi lua" % NGHI_BAN)
	var cau_moi_van: float = GIAY_VAN / NGHI_BAN
	ck(cau_moi_van <= 150.0, "moi nguoi ban toi %.0f qua mot van - qua nhieu goi tin" % cau_moi_van)

	# ── 8. ĐÒN PHẢI ĐẨY ĐƯỢC NGƯỜI VÀO NHAM (cuối ván, từ tâm ra khỏi vùng an toàn) ──
	ck(DAY_NGANG > CO_CON * BAN_KINH_SAN,
			"hat %.1f (m/s) yeu hon ban kinh vung cuoi %.2f m - khong hat ai vao nham duoc"
			% [DAY_NGANG, CO_CON * BAN_KINH_SAN])

	# ── 9. CHANG PHAI PHU HET VAN ──
	var co_xong: float = CHO_TRUOC_KHI_CO + float(SO_CHANG - 1) * GIAY_MOI_CHANG
	ck(co_xong < GIAY_VAN, "co het o %.1f s nhung van dai %.1f s" % [co_xong, GIAY_VAN])
	var giay_cuoi: float = GIAY_VAN - co_xong
	ck(giay_cuoi >= 8.0,
			"chi con %.1f s choi trong vung nho nhat - khong kip thanh tran cuoi" % giay_cuoi)

	print("OK  co %d lan: %s" % [so_lan_co, " -> ".join(PackedStringArray(moc))])
	print("OK  bon trang thai du: bao dung %.1f s truoc moi lan co, vanh bao dung cho" % GIAY_BAO)
	print("OK  vanh canh bao day %.2f m (ban co deu chi %.2f m)" % [mong_nhat, co_deu])
	print("OK  kip chay: can %.2f s, duoc bao %.1f s (%.1fx)" \
			% [can_giay, GIAY_BAO, GIAY_BAO / can_giay])
	print("OK  dien tich %.0f -> %.0f -> %.0f m2; cuoi van %.1f m2 moi nguoi (8 nguoi)"
			% [dt_dau, dt_giua, dt_cuoi, moi_nguoi])
	print("OK  chay %.1f s la chet; bo ra xa nhat mat %.2f s" % [giay_chet, giay_bo_ra])
	print("OK  cau lua bay %.1f m qua san %.1f m; nghi ban %.2f s" \
			% [tam_cau, BAN_KINH_SAN * 2.0, NGHI_BAN])
	print("OK  tran cuoi keo dai %.1f s trong vung %.2f m" % [giay_cuoi, CO_CON * BAN_KINH_SAN])
	print("--- %d loi ---" % _loi)
	quit()
