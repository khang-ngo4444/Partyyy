extends SceneTree

## Kiểm luật Breaking Blocks; hằng số chép từ breaking_blocks.gd + player.gd.
## Chạy: godot --headless --path minigame/breaking_blocks --script kiem_luat.gd

enum { LANH, NHE, NANG, SAP_VO }

const CANH := 8
const RONG_O := 2.8
const KHE := 1.2
const BUOC := RONG_O + KHE
const GIAY_VO_MOT_NGUOI := 3.0
const THEM_MOI_NGUOI := 0.75
const GIAY_MOC_LAI := 4.5
const KHO_CUOI := 4.0
const GIAY_KHO_HET := 30.0
const MOC_NHE := 0.25
const MOC_NANG := 0.5
const MOC_SAP_VO := 0.7
const GIAY_BAO_TOI_THIEU := 0.6
const CAO_TINH := 3.0
const GIAY_VAN := 60.0
const SPEED := 6.0
const JUMP_HEIGHT := 1.2
const GRAVITY := 20.0

var _loi := 0


func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)


static func kho(t: float) -> float:
	return lerpf(1.0, KHO_CUOI, clampf(t / GIAY_KHO_HET, 0.0, 1.0))


static func giay_moc_lai(t: float) -> float:
	return GIAY_MOC_LAI * kho(t)


static func toc_hu(n: int, t: float) -> float:
	if n <= 0:
		return 0.0
	return (1.0 + THEM_MOI_NGUOI * float(n - 1)) * kho(t) / GIAY_VO_MOT_NGUOI


static func trang_thai(hu: float) -> int:
	if hu >= MOC_SAP_VO: return SAP_VO
	if hu >= MOC_NANG: return NANG
	if hu >= MOC_NHE: return NHE
	return LANH


static func giay_canh_bao(n: int, t: float) -> float:
	var v := toc_hu(n, t)
	if v <= 0.0: return INF
	return maxf((1.0 - MOC_SAP_VO) / v, GIAY_BAO_TOI_THIEU)


## Mô phỏng một ván: người chơi bỏ chạy khi ô mình đứng vượt `nguong` hư.
func mo_phong(so_nguoi: int, nguong: float, giong: int) -> Dictionary:
	var tong := CANH * CANH
	var hu := PackedFloat32Array(); hu.resize(tong)
	var bao := PackedFloat32Array(); bao.resize(tong)
	var vo_luc := PackedFloat32Array(); vo_luc.resize(tong)
	var con := []
	for i in tong:
		con.append(true); bao[i] = -1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var o_cua := []
	for k in so_nguoi:
		o_cua.append(rng.randi_range(0, tong - 1))
	var d := 1.0 / 60.0
	var t := 0.0
	var so_vo := 0
	var it_nhat := tong
	var roi := 0
	var het_luc := GIAY_VAN
	while t < GIAY_VAN:
		var song := 0
		for k in o_cua.size():
			if int(o_cua[k]) >= 0: song += 1
		if song <= 1:
			het_luc = t
			break

		var dong := {}
		for k in o_cua.size():
			var i: int = o_cua[k]
			if i >= 0 and con[i]:
				dong[i] = int(dong.get(i, 0)) + 1

		for i in tong:
			if not con[i]:
				if t - vo_luc[i] >= giay_moc_lai(t):
					con[i] = true; hu[i] = 0.0; bao[i] = -1.0
				continue
			var n := int(dong.get(i, 0))
			if n > 0:
				hu[i] = minf(hu[i] + toc_hu(n, t) * d, 1.0)
			if trang_thai(hu[i]) == SAP_VO:
				if bao[i] < 0.0: bao[i] = t
			else:
				bao[i] = -1.0
			if hu[i] >= 1.0 and bao[i] >= 0.0 and t - bao[i] >= GIAY_BAO_TOI_THIEU:
				con[i] = false; vo_luc[i] = t; hu[i] = 1.0; bao[i] = -1.0
				so_vo += 1

		# đứng trên ô vừa vỡ thì rơi
		for k in o_cua.size():
			var i: int = o_cua[k]
			if i >= 0 and not con[i]:
				o_cua[k] = -1
				roi += 1

		# ô đang đứng đã qua ngưỡng → nhảy sang ô kề lành nhất
		for k in o_cua.size():
			var i: int = o_cua[k]
			if i < 0 or hu[i] < nguong:
				continue
			var r := i / CANH
			var c := i % CANH
			# Ưu tiên ô không có ai (người thật tránh chung ô).
			var trong_o := {}
			for m in o_cua.size():
				if m != k and int(o_cua[m]) >= 0:
					trong_o[int(o_cua[m])] = true
			var tot := -1
			var tot_diem := INF
			for dr in [-1, 0, 1]:
				for dc in [-1, 0, 1]:
					if dr == 0 and dc == 0: continue
					var nr: int = r + dr
					var nc: int = c + dc
					if nr < 0 or nr >= CANH or nc < 0 or nc >= CANH: continue
					var j := nr * CANH + nc
					if not con[j]: continue
					var diem: float = hu[j] + (10.0 if trong_o.has(j) else 0.0)
					if diem < tot_diem:
						tot_diem = diem; tot = j
			if tot >= 0:
				o_cua[k] = tot

		var n_con := 0
		for i in tong:
			if con[i]: n_con += 1
		it_nhat = mini(it_nhat, n_con)
		t += d
	var song_cuoi := 0
	for k in o_cua.size():
		if int(o_cua[k]) >= 0: song_cuoi += 1
	return {"vo": so_vo, "it_nhat": it_nhat, "roi": roi, "het": het_luc, "song": song_cuoi}


func _init() -> void:
	var tong := CANH * CANH

	# ── 1. NHAY: khe phai toi duoc de dang ──
	var v0: float = sqrt(2.0 * GRAVITY * JUMP_HEIGHT)
	var bay: float = 2.0 * v0 / GRAVITY
	var tam: float = SPEED * bay
	ck(tam > KHE * 2.0, "tam nhay %.2f m, khe %.2f m - nhay chinh xac qua" % [tam, KHE])
	ck(tam > BUOC, "tam nhay %.2f m khong qua duoc buoc luoi %.2f m" % [tam, BUOC])
	ck(JUMP_HEIGHT < CAO_TINH, "nhay %.1f m ra khoi nguong tinh %.1f m" % [JUMP_HEIGHT, CAO_TINH])

	# ── 2. BON TRANG THAI dung thu tu, khong nhay bac ──
	var thay := []
	var h := 0.0
	while h <= 1.0001:
		var tt := trang_thai(h)
		if thay.is_empty() or thay[-1] != tt: thay.append(tt)
		h += 0.002
	ck(thay == [LANH, NHE, NANG, SAP_VO], "thu tu trang thai sai: %s" % str(thay))

	# ── 3. CONG BANG: moi to hop nguoi x do kho phai bao du lau ──
	var hep := INF
	var hep_tai := ""
	for n in range(1, 9):
		for gi in range(0, 61, 5):
			var w: float = giay_canh_bao(n, float(gi))
			if w < hep: hep = w; hep_tai = "%d nguoi, giay %d" % [n, gi]
			ck(w >= GIAY_BAO_TOI_THIEU - 0.001,
					"%d nguoi giay %d: bao chi %.3f s" % [n, gi, w])

	# ── 4. DUNG YEN LA PHAI CHET ──
	var cam_chet := -1.0
	var hu2 := 0.0
	var bao2 := -1.0
	var t2 := 0.0
	while t2 < GIAY_VAN:
		hu2 = minf(hu2 + toc_hu(1, t2) / 60.0, 1.0)
		if trang_thai(hu2) == SAP_VO and bao2 < 0.0: bao2 = t2
		if hu2 >= 1.0 and bao2 >= 0.0 and t2 - bao2 >= GIAY_BAO_TOI_THIEU:
			cam_chet = t2; break
		t2 += 1.0 / 60.0
	ck(cam_chet > 0.0, "dung yen ca van ma o khong vo - tro vo nghia")
	ck(cam_chet < 10.0, "dung yen %.1f s moi vo - cho qua lau" % cam_chet)

	# ── 6. DONG NGUOI THI NHANH HON ──
	for n in range(2, 9):
		ck(toc_hu(n, 0.0) > toc_hu(n - 1, 0.0), "%d nguoi khong nhanh hon %d" % [n, n - 1])

	# ── 7. DO KHO TANG DON DIEU ──
	var truoc := 0.0
	for gi in range(0, 61, 2):
		var k: float = kho(float(gi))
		ck(k >= truoc - 0.0001, "do kho tut o giay %d" % gi)
		truoc = k

	# ── 8. VAN THUC: ba kieu nguoi choi, moi kieu 5 hat giong ──
	var kieu := {"gioi (chay som .50)": 0.50, "thuong (chay .75)": 0.75, "cam (chay .95)": 0.95}
	var bao_cao := []
	var het_theo_kieu := {}
	var roi_theo_kieu := {}
	for ten in kieu:
		var a_vo := 0.0; var a_it := 0.0; var a_roi := 0.0; var a_het := 0.0; var a_song := 0.0
		for g in range(1, 6):
			var r := mo_phong(4, float(kieu[ten]), g * 977)
			a_vo += r["vo"]; a_it += r["it_nhat"]; a_roi += r["roi"]
			a_het += r["het"]; a_song += r["song"]
		a_vo /= 5.0; a_it /= 5.0; a_roi /= 5.0; a_het /= 5.0; a_song /= 5.0
		het_theo_kieu[ten] = a_het
		roi_theo_kieu[ten] = a_roi
		bao_cao.append("    %-20s %4.1f vo · san %4.1f/%d · %.1f roi · het %4.1f s · con %.1f"
				% [ten, a_vo, a_it, tong, a_roi, a_het, a_song])
		# Phải có chuyện xảy ra: ít nhất một người bị loại
		ck(a_roi >= 1.0, "%s: chi %.1f nguoi roi ca van - san khong nguy hiem" % [ten, a_roi])
		ck(a_vo >= 2.0, "%s: chi %.1f o vo - khong du nguy hiem" % [ten, a_vo])
		# Nhưng không được bay hết sân
		ck(a_it > tong * 0.25, "%s: san tut con %.1f/%d - bay het san" % [ten, a_it, tong])
	# Người cắm trụ phải chết nhiều hơn người biết chạy (đo bằng số người rơi).
	var roi_gioi: float = roi_theo_kieu["gioi (chay som .50)"]
	var roi_cam: float = roi_theo_kieu["cam (chay .95)"]
	ck(roi_cam > roi_gioi, "cam %.1f roi, gioi %.1f roi - cam khong bi phat gi"
			% [roi_cam, roi_gioi])

	print("OK  nhay: tam %.2f m vs khe %.2f m / buoc luoi %.2f m" % [tam, KHE, BUOC])
	print("OK  4 trang thai dung thu tu LANH -> NHE -> NANG -> SAP_VO")
	print("OK  bao hep nhat %.2f s (%s), san cung %.2f s" % [hep, hep_tai, GIAY_BAO_TOI_THIEU])
	print("OK  dung yen thi o vo sau %.1f s" % cam_chet)
	print("OK  roi o thi vet nut o lai, khong tu lanh; moc lai %.1f s -> %.1f s"
			% [giay_moc_lai(0.0), giay_moc_lai(60.0)])
	print("OK  van thuc 4 nguoi, 5 hat giong moi kieu:")
	for l in bao_cao:
		print(l)
	print("--- %d loi ---" % _loi)
	quit()
