extends SceneTree

## KIỂM LUẬT Explosive Exchange — chạy ngoài game, không nạp project:
##
##     godot --headless --path minigame/explosive --script kiem_luat.gd
##
## Hằng số CHÉP TAY từ `explosive.gd`, `bom_chuyen.tscn`, `san_tron.tscn`, `player.tscn`. Chép chứ
## không `preload` vì `explosive.gd` kéo theo `MiniGame3D` → `Fusion` → cả project.
##
## Thứ bộ này tồn tại để chặn: **người ôm bom không còn biên nào để chuyền**.
##
## Mọi người cùng `Player.speed = 6.0`. Mô phỏng đuổi bắt 1v1 trên sàn tròn cho ra: không boost
## thì bắt được từ đầu này sàn sang đầu kia mất **4,88 giây**, mà bom ngắn nhất chỉ 7 giây và còn
## mất 0,9 giây nghỉ chuyền — còn **1,22 giây**. Quá sát: lỡ một nhịp quay đầu là chết.
##
## `TOC_OM_THEM = 1,6` hạ xuống 2,83 giây, còn lại 3,27 giây. Đó là cả lý do nó tồn tại, và kiểm
## #1 là thứ giữ cho nó không bị ai "dọn cho gọn".
##
## Lưu ý về giới hạn của mô phỏng: kẻ chạy trốn ở đây chạy ngược hướng rồi men theo bờ — một người
## thật biết vòng tròn sẽ khó bắt hơn. Nên 4,88 giây là biên DƯỚI của cái khó, không phải biên
## trên. Lần đầu tôi viết kiểm này đã khẳng định "bằng tốc thì không bao giờ bắt được"; chính mô
## phỏng bác lại, và con số trên là bản đã sửa.
##
## Dùng `ck()` chứ không `assert()`: `assert` fail trong `--headless --script` làm Godot ĐỨNG chờ
## debugger, 0% CPU, không in một chữ nào.

# explosive.gd
const GIAY_DAU := 16.0
const GIAY_CUOI := 7.0
const SO_LAN_NGAN := 4
const NGHI_CHUYEN := 0.9
const CAO_TREO := 2.3
const TOC_OM_THEM := 1.6
const GIAY_GAP := 4.0

# bom_chuyen.tscn / san_tron.tscn / player.tscn
const TAM_CHUYEN := 1.8          # VongTam.outer_radius VA Vung/Hinh.radius — phai bang nhau
const VONG_NGOAI := 1.8
const BAN_KINH_SAN := 11.5
const BAN_KINH_NGUOI := 0.4
const CAO_NGUOI := 1.8
const SPEED := 6.0

const KEP := BAN_KINH_SAN - 0.5
const D := 1.0 / 60.0

var _loi := 0

func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)

static func giay_dem(lan: int) -> float:
	return lerpf(GIAY_DAU, GIAY_CUOI, clampf(float(lan) / float(SO_LAN_NGAN), 0.0, 1.0))


## Duoi bat 1v1 tren san tron. Tra ve giay bat duoc, -1 neu khong bat duoc trong `tran` giay.
##
## Ke chay tron chay NGUOC huong nguoi om; sat bo thi chuyen sang tiep tuyen (cach tron toi uu
## tren mot dia). Nguoi om lao THANG vao - ke duoi don duong se bat nhanh hon, nen con so o day
## la bien tren.
static func duoi(them: float, tran: float, cach_dau: float) -> float:
	var om := Vector2(-cach_dau * 0.5, 0.0)
	var tron := Vector2(cach_dau * 0.5, 0.0)
	if om.length() > KEP:
		om = om.normalized() * KEP
	if tron.length() > KEP:
		tron = tron.normalized() * KEP
	var t := 0.0
	while t < tran:
		if om.distance_to(tron) <= TAM_CHUYEN + BAN_KINH_NGUOI:
			return t
		var ra := (tron - om).normalized()
		var moi := tron + ra * SPEED * D
		if moi.length() > KEP:
			var n := tron.normalized()
			var tt := Vector2(-n.y, n.x)
			if tt.dot(ra) < 0.0:
				tt = -tt
			moi = tron + tt * SPEED * D
			if moi.length() > KEP:
				moi = moi.normalized() * KEP
		tron = moi
		om += (tron - om).normalized() * (SPEED + them) * D
		if om.length() > KEP:
			om = om.normalized() * KEP
		t += D
	return -1.0


func _init() -> void:
	var duong_kinh: float = 2.0 * KEP

	# ── 1. KHONG BOOST THI BIEN QUA SAT (vi sao TOC_OM_THEM ton tai) ──
	var khong_boost: float = duoi(0.0, 60.0, duong_kinh)
	ck(khong_boost >= 0.0, "khong boost ma khong bat duoc trong 60 s - mo phong sai")
	var bien_khong: float = GIAY_CUOI - NGHI_CHUYEN - khong_boost
	ck(bien_khong < 1.5,
			"khong boost van con %.2f s bien - vay TOC_OM_THEM khong can thiet, bo di"
			% bien_khong)

	# ── 2. CO BOOST THI PHAI BAT DUOC, trong bom NGAN NHAT ──
	var lau_nhat := -1.0
	var lau_tai := 0.0
	for cach in [2.5, 5.0, 8.0, 12.0, 16.0, duong_kinh]:
		var g: float = duoi(TOC_OM_THEM, GIAY_CUOI * 3.0, float(cach))
		ck(g >= 0.0, "+%.1f m/s: KHONG bat duoc tu %.1f m trong %.0f s" % [TOC_OM_THEM, cach, GIAY_CUOI * 3.0])
		if g > lau_nhat:
			lau_nhat = g
			lau_tai = float(cach)
	ck(lau_nhat >= 0.0 and lau_nhat < GIAY_CUOI,
			"xau nhat bat mat %.2f s nhung bom ngan nhat chi %.1f s - con hai nguoi la nguoi om chet chac"
			% [lau_nhat, GIAY_CUOI])
	# Nhung cung khong duoc bat NGAY: khong thi ke chay tron khong co dat dien
	ck(lau_nhat > 1.5, "bat duoc trong %.2f s tu moi cho - ke chay tron khong co co hoi nao" % lau_nhat)
	# Nguoi VUA NHAN con bao nhieu giay sau khi het nghi chuyen
	var con_sau_nghi: float = GIAY_CUOI - NGHI_CHUYEN
	ck(con_sau_nghi > lau_nhat,
			"vua nhan bom thi con %.2f s nhung bat nguoi khac mat toi %.2f s" % [con_sau_nghi, lau_nhat])
	var bien_co: float = GIAY_CUOI - NGHI_CHUYEN - lau_nhat
	ck(bien_co >= 2.5,
			"co boost van chi con %.2f s bien tren bom ngan nhat - chua du de choi" % bien_co)
	ck(lau_nhat < khong_boost,
			"boost KHONG lam bat nhanh hon: %.2f s vs %.2f s" % [lau_nhat, khong_boost])

	# ── 3. BOOST KHONG DUOC QUA MANH ──
	var ti: float = (SPEED + TOC_OM_THEM) / SPEED
	ck(ti <= 1.45, "nguoi om nhanh gap %.2f lan - ke chay tron khong lam gi duoc" % ti)
	ck(TOC_OM_THEM > 0.0, "khong co boost thi xem kiem #1")

	# ── 4. DONG HO NGAN DAN, KHONG tang lai ──
	var truoc := INF
	var moc: Array = []
	for lan in range(0, SO_LAN_NGAN + 3):
		var g := giay_dem(lan)
		ck(g <= truoc + 0.001, "bom lan %d DAI HON lan truoc: %.1f -> %.1f" % [lan, truoc, g])
		truoc = g
		moc.append("%.1f" % g)
	ck(is_equal_approx(giay_dem(0), GIAY_DAU), "bom dau tien phai %.1f s" % GIAY_DAU)
	ck(is_equal_approx(giay_dem(SO_LAN_NGAN), GIAY_CUOI), "sau %d lan phai xuong %.1f s" % [SO_LAN_NGAN, GIAY_CUOI])
	ck(giay_dem(99) >= GIAY_CUOI, "bom khong duoc ngan hon %.1f s" % GIAY_CUOI)

	# ── 5. DONG HO DU DAI DE CHUYEN DUOC ──
	# Bom ngan nhat phai chua: nghi chuyen + di bat + bam nut
	ck(GIAY_CUOI > NGHI_CHUYEN + lau_nhat,
			"bom ngan nhat %.1f s < nghi %.1f + bat %.2f - khong the chuyen kip" % [GIAY_CUOI, NGHI_CHUYEN, lau_nhat])
	# Nhung khong duoc dai den muc bo qua duoc bom
	ck(GIAY_DAU < 25.0, "bom dau %.0f s - du lau de lo bom di choi viec khac" % GIAY_DAU)

	# ── 6. CO CHANG GAP, ke ca tren bom NGAN NHAT ──
	ck(GIAY_GAP < GIAY_CUOI, "chang gap %.1f s >= bom ngan nhat %.1f s - bom luc nao cung dang gap" % [GIAY_GAP, GIAY_CUOI])
	ck(GIAY_GAP >= 2.0, "chang gap chi %.1f s - khong kip nhan ra da gap" % GIAY_GAP)
	var ti_gap: float = GIAY_GAP / GIAY_CUOI
	ck(ti_gap <= 0.75, "chang gap chiem %.0f%% bom ngan nhat - gan nhu ca van dang gap" % (ti_gap * 100.0))

	# ── 7. NGHI_CHUYEN: chong ping-pong nhung khong giam nguoi vua nhan ──
	# Hai nguoi dung canh nhau: nghi phai du de nguoi vua nhan chay ra khoi tam chuyen
	var chay_ra: float = (TAM_CHUYEN + BAN_KINH_NGUOI) / SPEED
	ck(NGHI_CHUYEN >= chay_ra * 0.8,
			"nghi %.2f s nhung chay ra khoi tam chuyen mat %.2f s - chuyen qua chuyen lai duoc"
			% [NGHI_CHUYEN, chay_ra])
	ck(NGHI_CHUYEN < 2.0, "nghi %.2f s - nguoi vua nhan bi khoa tay qua lau" % NGHI_CHUYEN)

	# ── 8. TAM CHUYEN: phai ung voi VONG DO nhin thay, va khong duoc xa vo ly ──
	ck(is_equal_approx(TAM_CHUYEN, VONG_NGOAI),
			"Vung/Hinh.radius %.2f khac VongTam.outer_radius %.2f - tam chuyen khong ung voi vong do nhin thay"
			% [TAM_CHUYEN, VONG_NGOAI])
	var tam_than: float = TAM_CHUYEN + BAN_KINH_NGUOI
	ck(tam_than <= 2.6, "chuyen duoc tu %.2f m (tam den tam) - xa vo ly" % tam_than)
	ck(tam_than >= 1.2, "chi chuyen duoc tu %.2f m - phai cham sat moi an, kho den muc nham" % tam_than)
	# Vung phai phu het than nguoi dung canh: cao 2.2 tu chan nguoi om
	ck(2.2 >= CAO_NGUOI, "Vung cao 2.2 m < nguoi cao %.1f m - chuyen hut khi dung sat" % CAO_NGUOI)

	# ── 9. CHONG LACH LUAT: khong ai ra duoc khoi san ──
	ck(KEP < BAN_KINH_SAN, "kep %.1f >= san %.1f - nguoi om bom chay ra ngoai de khoi phai chuyen" % [KEP, BAN_KINH_SAN])
	ck(BAN_KINH_SAN - KEP >= 0.4, "kep sat bo qua (%.2f m) - than nguoi co the lo ra ngoai" % (BAN_KINH_SAN - KEP))
	# San du rong de duoi va chay: it nhat vai lan tam chuyen
	ck(duong_kinh > tam_than * 6.0, "san rong %.1f m chi gap %.1f lan tam chuyen - chay dau cung bi cham" % [duong_kinh, duong_kinh / tam_than])

	# ── 10. BOM TREO TREN DAU, khong lut trong nguoi ──
	ck(CAO_TREO > CAO_NGUOI, "bom treo %.2f m <= nguoi cao %.1f m - bom lut trong nhan vat" % [CAO_TREO, CAO_NGUOI])
	ck(CAO_TREO < 3.5, "bom treo %.2f m - cao qua, nhin tu cam tren cao khong biet cua ai" % CAO_TREO)

	print("OK  khong boost: bat mat %.2f s -> chi con %.2f s bien (qua sat)" % [khong_boost, bien_khong])
	print("OK  +%.1f m/s: bat mat %.2f s (tu %.1f m) -> con %.2f s bien tren bom ngan nhat %.1f s"
			% [TOC_OM_THEM, lau_nhat, lau_tai, bien_co, GIAY_CUOI])
	print("OK  nguoi om nhanh gap %.2f lan; vua nhan con %.2f s sau nghi chuyen" % [ti, con_sau_nghi])
	print("OK  dong ho ngan dan: %s giay" % " -> ".join(PackedStringArray(moc)))
	print("OK  chang gap %.1f s = %.0f%% bom ngan nhat" % [GIAY_GAP, ti_gap * 100.0])
	print("OK  nghi chuyen %.2f s vs chay ra khoi tam %.2f s" % [NGHI_CHUYEN, chay_ra])
	print("OK  tam chuyen %.2f m = vong do; tam den tam %.2f m; san %.1f m" % [TAM_CHUYEN, tam_than, duong_kinh])
	print("OK  bom treo %.2f m tren nguoi cao %.1f m" % [CAO_TREO, CAO_NGUOI])
	print("--- %d loi ---" % _loi)
	quit()
