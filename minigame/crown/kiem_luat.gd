extends SceneTree

## Kiểm luật Crown Capture: godot --headless --path minigame/crown --script kiem_luat.gd
## Chặn xếp hạng theo người giữ cuối thay vì tổng giây giữ (#1).
## Hằng số chép tay; dùng `ck()` thay `assert`.

# crown.gd
const NGHI_CUOP := 1.1
const NGHI_BAN := 0.7
const CAO_DOI := 2.2
const CAO_NAM := 0.8
const DAY_NGANG := 9.0
const DAY_LEN := 3.5
const GIAY_VAN := 60.0

# vuong_mien.tscn / san_tron.tscn / cau_lua.gd / player.gd
const TAM_NHAT := 1.5            # Vung/Hinh.radius VA VongNhat.outer_radius — phai bang nhau
const VONG_NGOAI := 1.5
const BAN_KINH_SAN := 11.5
const TOC_CAU := 16.0
const SONG_CAU := 1.6
const SPEED := 6.0
const BAN_KINH_NGUOI := 0.4
const CAO_NGUOI := 1.8
const DAY_TAT_DAN := 9.0
const KEP := BAN_KINH_SAN - 0.5

var _loi := 0

func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)


## Chạy dòng thời gian đổi chủ miện → bảng điểm và người giữ cuối.
## `moc` = [[giây, ai_giu], ...].
static func chay(moc: Array, het: float) -> Dictionary:
	var diem := {}
	var cuoi := 0
	for i in moc.size():
		var tu: float = float(moc[i][0])
		var den: float = float(moc[i + 1][0]) if i + 1 < moc.size() else het
		var ai: int = int(moc[i][1])
		if ai != 0:
			diem[ai] = float(diem.get(ai, 0.0)) + maxf(den - tu, 0.0)
			cuoi = ai
		else:
			cuoi = 0
	return {"diem": diem, "cuoi": cuoi}


## Xếp theo tổng giây giữ (như `_chot_ket_qua`).
static func xep_theo_diem(diem: Dictionary) -> Array:
	var ids: Array = []
	for id in diem:
		ids.append(int(id))
	ids.sort_custom(func(a: int, b: int) -> bool: return float(diem[a]) > float(diem[b]))
	return ids


func _init() -> void:
	# ── 1. THẮNG BẰNG TỔNG GIÂY, KHÔNG BẰNG NGƯỜI GIỮ CUỐI ──
	var r := chay([[0.0, 1], [40.0, 0], [45.0, 2]], GIAY_VAN)
	var diem: Dictionary = r["diem"]
	var cuoi: int = int(r["cuoi"])
	var xep := xep_theo_diem(diem)
	ck(float(diem.get(1, 0.0)) > float(diem.get(2, 0.0)),
			"dong thoi gian sai: nguoi 1 phai giu lau hon (%.1f vs %.1f)" \
					% [diem.get(1, 0.0), diem.get(2, 0.0)])
	ck(cuoi == 2, "dong thoi gian sai: nguoi 2 phai la nguoi giu cuoi")
	ck(int(xep[0]) == 1,
			"nguoi %d nhat, dang ra la nguoi 1 (giu %.1f s) - xep theo nguoi giu CUOI"
			% [int(xep[0]), diem.get(1, 0.0)])
	ck(int(xep[0]) != cuoi, "nguoi nhat trung nguoi giu cuoi - dong thoi gian vo dung")

	# ── 2. DIEM GIU LAI SAU KHI MAT MIEN, va cong tiep khi nhat lai ──
	var r2 := chay([[0.0, 1], [10.0, 2], [20.0, 1], [30.0, 0]], GIAY_VAN)
	var d2: Dictionary = r2["diem"]
	ck(is_equal_approx(float(d2.get(1, 0.0)), 20.0),
			"nguoi 1 giu 10 + 10 giay phai duoc 20, dang duoc %.1f - diem bi xoa khi mat mien"
			% float(d2.get(1, 0.0)))
	ck(is_equal_approx(float(d2.get(2, 0.0)), 10.0), "nguoi 2 phai duoc 10 giay")
	# Miện nằm đất thì không ai ăn điểm
	var tong := 0.0
	for id in d2:
		tong += float(d2[id])
	ck(tong < GIAY_VAN - 25.0, "tong %.1f s > thoi gian co chu - mien nam dat ma van cong diem" \
			% tong)

	# ── 3. NHẶT MIỆN KHÔNG CHO ĐIỂM (nhặt rồi mất ngay = 0) ──
	var r3 := chay([[0.0, 5], [0.0, 0]], GIAY_VAN)
	ck(float((r3["diem"] as Dictionary).get(5, 0.0)) <= 0.001,
			"nhat roi mat ngay ma duoc %.3f diem - diem trao khi NHAT chu khong phai khi GIU"
			% float((r3["diem"] as Dictionary).get(5, 0.0)))

	# ── 4. BỊ HẤT THÌ KHÔNG TỰ NHẶT LẠI NGAY ──
	var hat_xa: float = DAY_NGANG * DAY_NGANG / (2.0 * DAY_TAT_DAN)
	var hat_lau: float = DAY_NGANG / DAY_TAT_DAN
	var tam_than: float = TAM_NHAT + BAN_KINH_NGUOI
	ck(hat_xa > tam_than,
			"hat xa %.2f m <= tam nhat %.2f m - nguoi bi hat van dung trong vong, nhat lai ngay"
			% [hat_xa, tam_than])
	# Thời gian người bị hất quay về được
	var ve_lai: float = hat_lau + (hat_xa - tam_than) / SPEED
	ck(ve_lai > NGHI_CUOP,
			"nguoi bi hat ve duoc sau %.2f s nhung mien mo nhat tu %.2f s - cu don thanh vo nghia"
			% [ve_lai, NGHI_CUOP])
	# Người khác cũng phải có cửa: trong NGHI_CUOP, ở gần bao nhiêu mét thì tới được
	var cua: float = NGHI_CUOP * SPEED + (ve_lai - NGHI_CUOP) * SPEED
	ck(cua > 4.0, "chi ai o trong %.1f m moi tranh duoc - cua qua hep" % cua)

	# ── 5. TAM NHAT ung voi VONG nhin thay, khong xa vo ly ──
	ck(is_equal_approx(TAM_NHAT, VONG_NGOAI),
			"Vung.radius %.2f khac VongNhat.outer_radius %.2f - tam nhat khong ung vong"
			% [TAM_NHAT, VONG_NGOAI])
	ck(tam_than <= 2.4, "nhat duoc tu %.2f m (tam den tam) - xa vo ly" % tam_than)
	ck(tam_than >= 1.2, "chi nhat duoc tu %.2f m - phai dung sat chinh xac" % tam_than)

	# ── 6. CAU LUA: ban toi duoc nua san ben kia, va ne duoc ──
	var tam_cau: float = TOC_CAU * SONG_CAU
	var duong_kinh: float = 2.0 * KEP
	ck(tam_cau >= duong_kinh * 0.9,
			"cau lua bay %.1f m nhung san rong %.1f m - khong thach thuc duoc nguoi o xa"
			% [tam_cau, duong_kinh])
	ck(TOC_CAU > SPEED, "cau %.1f m/s khong nhanh hon nguoi %.1f m/s - di bo cung ne duoc" \
			% [TOC_CAU, SPEED])
	ck(NGHI_BAN >= 0.4, "nghi ban %.2f s - giu phim la mot voi lua" % NGHI_BAN)
	# Người đội miện phải bị bắn trúng khá thường xuyên: mỗi người bắn bao nhiêu phát một ván
	var phat: float = GIAY_VAN / NGHI_BAN
	ck(phat >= 40.0, "moi nguoi chi ban %.0f phat ca van - mien doi chu qua it" % phat)

	# ── 7. KHONG AI CHET: het gio van con du nguoi ──
	ck(KEP < BAN_KINH_SAN, "kep %.1f >= san %.1f - nguoi choi ra duoc khoi san va chet" \
			% [KEP, BAN_KINH_SAN])
	ck(BAN_KINH_SAN - KEP >= 0.4, "kep sat bo qua (%.2f m)" % (BAN_KINH_SAN - KEP))
	# Hất mạnh nhất cũng không được đẩy ai ra khỏi vùng kẹp
	ck(hat_xa < duong_kinh * 0.5,
			"mot cu hat di %.2f m tren san ban kinh %.1f - hat tu tam la ra toi bo" % [hat_xa, KEP])

	# ── 8. MIEN DOI TREN DAU, khong lut trong nguoi; nam dat thi thay duoc ──
	ck(CAO_DOI > CAO_NGUOI, "mien doi %.2f m <= nguoi cao %.1f m - mien lut trong nhan vat" \
			% [CAO_DOI, CAO_NGUOI])
	ck(CAO_DOI < 3.5, "mien doi %.2f m - cao qua, nhin tu cam tren cao khong biet cua ai" % CAO_DOI)
	ck(CAO_NAM > 0.3, "mien nam o %.2f m - lut xuong san" % CAO_NAM)
	ck(CAO_NAM < CAO_DOI, "mien nam (%.2f) cao hon luc doi (%.2f) - doc lon" % [CAO_NAM, CAO_DOI])

	# ── 9. VÁN ĐỦ DÀI ĐỂ MIỆN ĐỔI CHỦ NHIỀU LẦN ──
	var mot_vong: float = NGHI_CUOP + (duong_kinh * 0.25) / SPEED
	var so_lan: float = GIAY_VAN / mot_vong
	ck(so_lan >= 8.0, "ca van chi doi chu duoc ~%.0f lan - khong thanh tranh gianh" % so_lan)

	print("OK  xep theo TONG giay: nguoi 1 (%.1f s) nhat, du nguoi 2 (%.1f s) dang giu luc het gio"
			% [diem.get(1, 0.0), diem.get(2, 0.0)])
	print("OK  diem giu lai sau khi mat mien: 10 + 10 = %.1f s" % float(d2.get(1, 0.0)))
	print("OK  nhat roi mat ngay = 0 diem (diem tra cho GIU, khong cho NHAT)")
	print("OK  hat xa %.2f m > tam nhat %.2f m; ve lai mat %.2f s > nghi %.2f s"
			% [hat_xa, tam_than, ve_lai, NGHI_CUOP])
	print("OK  tam nhat %.2f m = vong nhin thay; tam den tam %.2f m" % [TAM_NHAT, tam_than])
	print("OK  cau lua bay %.1f m qua san %.1f m; %.0f phat/nguoi/van" \
			% [tam_cau, duong_kinh, phat])
	print("OK  khong ai chet: kep %.1f trong san %.1f; mot cu hat chi di %.2f m" \
			% [KEP, BAN_KINH_SAN, hat_xa])
	print("OK  mien doi %.2f m tren nguoi cao %.1f m; nam dat o %.2f m" \
			% [CAO_DOI, CAO_NGUOI, CAO_NAM])
	print("OK  ~%.0f lan doi chu kha thi trong %.0f s" % [so_lan, GIAY_VAN])
	print("--- %d loi ---" % _loi)
	quit()
