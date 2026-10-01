extends SceneTree

## KIỂM LUẬT Acidic Atoll — chạy ngoài game, không nạp project:
##
##     godot --headless --path minigame/acidic_atoll --script kiem_luat.gd
##
## Hằng số CHÉP TAY từ `acidic_atoll.gd`, `dao.tscn`, `san_tron.tscn`, `bom_axit.gd`, `player.gd`.
## Chép chứ không `preload` vì `acidic_atoll.gd` kéo theo `MiniGame3D` → `Fusion` → cả project.
##
## Ba thứ bộ này tồn tại để chặn, cả ba đều KHÔNG thấy được trong một ván chơi thử:
##
##   1. **Không còn đảo nào sống qua được lần chìm tới.** Cửa sổ trượt có thể ăn hết mọi đảo an
##      toàn cùng lúc, và lúc đó người chơi bắt buộc phải xuống axit dù chơi đúng. Kiểm #4 quét
##      mọi chặng và đòi luôn có ít nhất một đảo an toàn ở CẢ chặng này và chặng sau.
##   2. **Khe quá xa không nhảy được.** `BAN_KINH_VANH` và `BAN_KINH_DAO` quyết định khe; đổi một
##      con số là khe đổi theo và không ai nhận ra tới lúc chơi. Kiểm #1 đo cả hai khe.
##   3. **Axit thành bẫy chết.** `CAO_DAO` lớn hơn `jump_height` thì rơi xuống axit là không leo
##      lên được, và trò thành "chạm axit là chết" thay vì "bò ra được".
##
## Dùng `ck()` chứ không `assert()`: `assert` fail trong `--headless --script` làm Godot ĐỨNG chờ
## debugger, 0% CPU, không in một chữ nào.

# acidic_atoll.gd
const SO_DAO := 6
const SO_VANH := 5
const BAN_KINH_DAO := 3.0
const BAN_KINH_VANH := 7.5
const CAO_DAO := 0.8
const TOI_DA_CHIM := 4
const CHO_TRUOC_KHI_CHIM := 8.0
const GIAY_MOI_CHANG := 9.0
const GIAY_BAO := 3.5
const MAT_MAU_MOI_GIAY := 20.0
const MAU_TOI_DA := 100.0
const BAT_DAU_NEM := 3.0
const NGHI_DAU := 2.3
const NGHI_CUOI := 1.0
const GIAY_DAY_HET := 55.0
const GIAY_VAN := 70.0

# san_tron.tscn / bom_axit.gd / player.gd
const BAN_KINH_BON := 11.5
const GIAY_ROI_BOM := 1.5
const JUMP_HEIGHT := 1.2
const GRAVITY := 20.0
const SPEED := 6.0

var _loi := 0

func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)

static func cho_dao(i: int) -> Vector3:
	if i <= 0:
		return Vector3.ZERO
	var a := TAU * float(i - 1) / float(SO_VANH)
	return Vector3(cos(a) * BAN_KINH_VANH, 0.0, sin(a) * BAN_KINH_VANH)

static func thu_tu_chim(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	for i in SO_DAO:
		ds.append(i)
	for i in range(ds.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tam = ds[i]
		ds[i] = ds[j]
		ds[j] = tam
	return ds

static func chang(t: float) -> int:
	if t < CHO_TRUOC_KHI_CHIM:
		return 0
	return 1 + int((t - CHO_TRUOC_KHI_CHIM) / GIAY_MOI_CHANG)

static func luc_chang_sau(t: float) -> float:
	return CHO_TRUOC_KHI_CHIM + float(chang(t)) * GIAY_MOI_CHANG

static func so_chim(k: int) -> int:
	return mini(maxi(k, 0), TOI_DA_CHIM)

static func dao_chim(giong: int, k: int) -> Array:
	if k <= 0:
		return []
	var tt := thu_tu_chim(giong)
	var ds: Array = []
	for j in so_chim(k):
		ds.append(tt[(k - 1 + j) % SO_DAO])
	return ds

static func dao_bao(giong: int, t: float) -> Array:
	if t < luc_chang_sau(t) - GIAY_BAO:
		return []
	var k := chang(t)
	var nay := dao_chim(giong, k)
	var ds: Array = []
	for i in dao_chim(giong, k + 1):
		if not nay.has(i):
			ds.append(i)
	return ds

static func dao_noi(giong: int, k: int) -> Array:
	var chim := dao_chim(giong, k)
	var ds: Array = []
	for i in SO_DAO:
		if not chim.has(i):
			ds.append(i)
	return ds

static func lich_roi(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong + 1
	var ds: Array = []
	var t := BAT_DAU_NEM
	while t < 180.0:
		var noi := dao_noi(giong, chang(t))
		var i: int = noi[rng.randi_range(0, noi.size() - 1)]
		var c := cho_dao(i)
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * BAN_KINH_DAO
		ds.append({"luc": t, "cho": Vector3(c.x + cos(a) * r, 0.0, c.z + sin(a) * r)})
		t += lerpf(NGHI_DAU, NGHI_CUOI, clampf(t / GIAY_DAY_HET, 0.0, 1.0))
	return ds

## Chang cuoi con y nghia trong mot van
static func chang_cuoi() -> int:
	return chang(GIAY_VAN - 0.01)


func _init() -> void:
	# ── 1. KHE PHAI NHAY DUOC ──
	var v0: float = sqrt(2.0 * GRAVITY * JUMP_HEIGHT)
	var tam_nhay: float = SPEED * (2.0 * v0 / GRAVITY)
	var khe_giua: float = BAN_KINH_VANH - 2.0 * BAN_KINH_DAO
	var cach_vanh: float = 2.0 * PI * BAN_KINH_VANH / float(SO_VANH)
	var khe_vanh: float = cach_vanh - 2.0 * BAN_KINH_DAO
	ck(khe_giua > 0.0, "dao giua CHAM dao vanh (khe %.2f m) - khong con la dao roi" % khe_giua)
	ck(khe_vanh > 0.0, "hai dao vanh CHAM nhau (khe %.2f m)" % khe_vanh)
	ck(khe_giua < tam_nhay, "khe giua<->vanh %.2f m > tam nhay %.2f m" % [khe_giua, tam_nhay])
	ck(khe_vanh < tam_nhay, "khe vanh<->vanh %.2f m > tam nhay %.2f m" % [khe_vanh, tam_nhay])
	# Khong duoc sat sao: nhay chinh xac tung cm la pham spec
	ck(tam_nhay > khe_vanh * 1.2, "chi du %.2fx tam nhay cho khe rong nhat - nhay chinh xac qua" % (tam_nhay / khe_vanh))
	# Dao phai nam trong bon
	ck(BAN_KINH_VANH + BAN_KINH_DAO <= BAN_KINH_BON,
			"dao vanh tran ra ngoai bon: %.1f > %.1f" % [BAN_KINH_VANH + BAN_KINH_DAO, BAN_KINH_BON])

	# ── 2. AXIT KHONG DUOC LA BAY CHET ──
	ck(CAO_DAO < JUMP_HEIGHT,
			"mat dao cao %.2f m >= nhay %.2f m - roi xuong axit la khong leo len duoc"
			% [CAO_DAO, JUMP_HEIGHT])
	ck(JUMP_HEIGHT - CAO_DAO >= 0.3, "chi du %.2f m du dat - leo len doi may man" % (JUMP_HEIGHT - CAO_DAO))
	var giay_chet: float = MAU_TOI_DA / MAT_MAU_MOI_GIAY
	ck(giay_chet >= 3.0, "loi axit %.1f s la chet - bi hat xuong mot cai la xong" % giay_chet)
	ck(giay_chet <= 8.0, "loi axit %.1f s moi chet - khong du dau de phai leo len" % giay_chet)
	# Loi tu cho xa nhat trong bon ve dao gan nhat mat bao lau
	var loi_xa: float = BAN_KINH_BON - (BAN_KINH_VANH + BAN_KINH_DAO)
	var giay_loi: float = (loi_xa + khe_vanh) / SPEED
	ck(giay_loi < giay_chet, "loi ve dao mat %.2f s nhung chet sau %.2f s" % [giay_loi, giay_chet])

	# ── 3. SO DAO CHIM TANG DAN, va luon con dao noi ──
	var truoc := -1
	var moc: Array = []
	for k in range(0, chang_cuoi() + 1):
		var n := so_chim(k)
		ck(n >= truoc, "so dao chim TUT o chang %d: %d -> %d" % [k, truoc, n])
		ck(n < SO_DAO, "chang %d chim het %d/%d dao - khong con cho nao dung" % [k, n, SO_DAO])
		truoc = n
		moc.append(SO_DAO - n)
	ck(so_chim(0) == 0, "chang 0 phai chua chim dao nao")
	ck(so_chim(chang_cuoi()) == TOI_DA_CHIM,
			"het van moi chim %d dao, chua dat tran %d" % [so_chim(chang_cuoi()), TOI_DA_CHIM])

	# ── 4. LUON CO DAO SONG QUA DUOC LAN CHIM TOI (quet 200 hat giong) ──
	var te_nhat := 99
	var te_tai := ""
	for g in range(1, 201):
		for k in range(0, chang_cuoi() + 2):
			var noi_nay := dao_noi(g, k)
			var noi_sau := dao_noi(g, k + 1)
			var ben := 0
			for i in noi_nay:
				if noi_sau.has(i):
					ben += 1
			if ben < te_nhat:
				te_nhat = ben
				te_tai = "hat %d, chang %d" % [g, k]
			ck(ben >= 1,
					"hat %d chang %d: KHONG dao nao song qua chang sau - nguoi choi dung dung cung phai xuong axit"
					% [g, k])
			# Dao duoc bao phai dung la dao sap chim
			var tt: float = CHO_TRUOC_KHI_CHIM + float(k) * GIAY_MOI_CHANG - 0.05
			if k >= 1 and tt > 0.0:
				for i in dao_bao(g, tt):
					ck(dao_noi(g, chang(tt)).has(i), "hat %d: dao %d bi bao nhung dang chim san" % [g, i])
					ck(not dao_noi(g, chang(tt) + 1).has(i), "hat %d: dao %d bi bao nhung khong chim" % [g, i])

	# ── 5. CO BAO TRUOC DUNG GIAY_BAO ──
	for k in range(1, chang_cuoi() + 1):
		var luc: float = CHO_TRUOC_KHI_CHIM + float(k) * GIAY_MOI_CHANG
		ck(dao_bao(7, luc - 0.05).size() > 0, "ngay truoc lan chim o %.1f s ma khong bao dao nao" % luc)
		ck(dao_bao(7, luc - GIAY_BAO - 0.2).size() == 0, "bao som hon %.1f s truoc khi chim" % GIAY_BAO)
	# Kip chay: tu giua dao bi bao sang dao noi gan nhat
	var can_chay: float = (BAN_KINH_DAO + khe_vanh) / SPEED
	ck(can_chay < GIAY_BAO, "chay sang dao khac mat %.2f s nhung chi bao %.1f s" % [can_chay, GIAY_BAO])
	ck(GIAY_BAO / can_chay >= 2.0, "chi du %.1fx thoi gian can - gap qua" % (GIAY_BAO / can_chay))

	# ── 6. TAP DAO AN TOAN PHAI DOI (bat di chuyen lap lai, khong don mot lan) ──
	var so_doi := 0
	for k in range(1, chang_cuoi() + 1):
		if str(dao_noi(7, k)) != str(dao_noi(7, k + 1)):
			so_doi += 1
	ck(so_doi >= chang_cuoi() - 1,
			"tap dao an toan chi doi %d/%d lan - nguoi choi dung mot cho la xong"
			% [so_doi, chang_cuoi()])

	# ── 7. BOM: luon roi LEN DAO CON NOI, trong ban kinh dao ──
	var lich := lich_roi(99)
	var ngoai := 0
	var tren_dao_chim := 0
	for b in lich:
		var tt: float = float(b["luc"])
		if tt > GIAY_VAN:
			continue
		var cho: Vector3 = b["cho"]
		var xz := Vector2(cho.x, cho.z)
		var noi := dao_noi(99, chang(tt))
		var trong := false
		for i in noi:
			var c := cho_dao(i)
			if xz.distance_to(Vector2(c.x, c.z)) <= BAN_KINH_DAO + 0.001:
				trong = true
				break
		if not trong:
			# tren dao dang chim, hay ngoai het?
			var tren_chim := false
			for i in dao_chim(99, chang(tt)):
				var c := cho_dao(i)
				if xz.distance_to(Vector2(c.x, c.z)) <= BAN_KINH_DAO + 0.001:
					tren_chim = true
					break
			if tren_chim: tren_dao_chim += 1
			else: ngoai += 1
	ck(ngoai == 0, "%d qua bom roi ra ngoai moi dao - bom vo nghia" % ngoai)
	ck(tren_dao_chim == 0, "%d qua bom roi len dao dang chim" % tren_dao_chim)
	# Bom phai kip thay: vong danh dau hien GIAY_ROI_BOM giay truoc khi no
	ck(GIAY_ROI_BOM >= 1.0, "bom roi trong %.2f s - khong kip ne" % GIAY_ROI_BOM)
	var bom_trong_van := 0
	for b in lich:
		if float(b["luc"]) <= GIAY_VAN:
			bom_trong_van += 1
	ck(bom_trong_van >= 20, "chi %d qua bom ca van - bom khong gay ap luc gi" % bom_trong_van)
	ck(bom_trong_van <= 70, "toi %d qua bom ca van - ap luc chong len dao chim thanh roi" % bom_trong_van)

	# ── 8. DIEN TICH AN TOAN: dau rong, cuoi chat ──
	var dt1: float = PI * BAN_KINH_DAO * BAN_KINH_DAO
	var dt_dau: float = dt1 * float(SO_DAO)
	var dt_cuoi: float = dt1 * float(SO_DAO - TOI_DA_CHIM)
	ck(dt_cuoi < dt_dau * 0.5, "cuoi van con %.0f%% dien tich - chua ep ai" % (dt_cuoi / dt_dau * 100.0))
	var moi_nguoi: float = dt_cuoi / 8.0
	ck(moi_nguoi >= 4.0, "cuoi van %.1f m2 moi nguoi (8 nguoi) - chen khong the dung" % moi_nguoi)

	# ── 9. XAC DINH: cung hat giong ra cung ket qua ──
	ck(str(thu_tu_chim(4242)) == str(thu_tu_chim(4242)), "cung hat giong ra hai thu tu khac nhau")
	ck(str(thu_tu_chim(1)) != str(thu_tu_chim(2)), "hai hat giong ra cung thu tu")
	ck(str(lich_roi(4242)) == str(lich_roi(4242)), "cung hat giong ra hai lich bom khac nhau")

	print("OK  khe giua<->vanh %.2f m · vanh<->vanh %.2f m · tam nhay %.2f m" % [khe_giua, khe_vanh, tam_nhay])
	print("OK  mat dao cao %.2f m < nhay %.2f m; loi axit %.1f s la chet, loi ve mat %.2f s"
			% [CAO_DAO, JUMP_HEIGHT, giay_chet, giay_loi])
	print("OK  dao con noi theo chang: %s" % str(moc))
	print("OK  200 hat giong: luon >= %d dao song qua chang sau (te nhat %s)" % [te_nhat, te_tai])
	print("OK  bao %.1f s truoc moi lan chim; chay sang dao khac can %.2f s (%.1fx)"
			% [GIAY_BAO, can_chay, GIAY_BAO / can_chay])
	print("OK  tap dao an toan doi %d/%d chang - phai di chuyen lap lai" % [so_doi, chang_cuoi()])
	print("OK  %d qua bom, tat ca roi len dao con noi" % bom_trong_van)
	print("OK  dien tich %.0f -> %.0f m2; cuoi van %.1f m2 moi nguoi (8 nguoi)" % [dt_dau, dt_cuoi, moi_nguoi])
	print("--- %d loi ---" % _loi)
	quit()
