extends MiniGame3D

## LASER LEAP — tia quét sát mặt sàn, nhảy qua. Đọc tia rồi quyết định, không phải nhảy theo nhịp.
##
## Khuôn T2. Không giới hạn giờ theo nghĩa thường: `giay_van` chỉ là chốt chặn, ván kết thúc khi
## còn một người.
##
## ## 0 gói tin
##
## Góc mỗi tia là hàm thuần của `gio()` và lịch đợt suy từ hạt giống. Va chạm thì mỗi máy chỉ
## kiểm nhân vật CỦA MÌNH rồi tự khai tử.
##
## ## Vì sao tia QUAY chứ không trượt ngang
##
## Tia trượt ngang thì đứng ở mép sàn là cả ván không phải nhảy lần nào. Tia quay quét qua mọi
## chỗ nên không có góc nào khỏi phải nhảy.
##
## ## Vì sao phải có LỊCH ĐỢT, không để ba tia quay đều mãi
##
## Bản trước cho cả ba tia quay quanh ĐÚNG tâm, CÙNG một tốc độ, pha cách đều nhau. Nó đúng ở
## chỗ không có góc an toàn — nhưng sai ở chỗ quan trọng hơn: **nhịp cố định**. Đứng bất cứ đâu
## cũng có tia đi qua đều đặn mỗi `PI / số_tia / tốc_độ` giây, nên người chơi chỉ cần tìm ra một
## nhịp nhảy rồi lặp lại là sống tới hết ván mà không cần nhìn gì nữa. Trò phản xạ thành trò
## bấm nhịp.
##
## Lịch đợt phá nhịp đó bằng bốn thứ đổi theo từng đợt, không phải bằng cách cho tia nhanh hơn:
##
##   - **Hướng:** tia quay ngược chiều nhau.
##   - **Tốc:** mỗi tia một hệ số riêng, nên hai tia không bao giờ về cùng một nhịp.
##   - **Pha đầu:** đợt mới bắt đầu từ một góc khác.
##   - **Lệch tâm:** tia quay quanh một điểm LỆCH khỏi tâm sàn, nên khoảng cách giữa hai lần tia
##     đi qua một chỗ không còn đều — đứng yên không còn đoán được.
##
## ## Vì sao thanh tia dài 30 m mà sàn chỉ 11,5 m bán kính
##
## Vì có lệch tâm. Tia lệch `LECH_TOI_DA` quét được một đĩa bán kính `nửa thanh` quanh điểm lệch
## đó; để đĩa ấy phủ kín sàn thì cần `nửa thanh >= 11,5 + lệch` = 14,5. Thanh ngắn hơn thì sinh
## ra một góc sàn tia không bao giờ với tới — đúng cái "chỗ đứng an toàn vĩnh viễn" phải tránh.
##
## ## Báo trước
##
## Tia hiện mờ và mỏng `GIAY_BAO` giây trước khi ăn người, và trong lúc đó `Area3D` tắt hẳn. Không
## có đoạn này thì đợt mới là một tia hiện ra giữa người chơi và giết ngay.

## Nhảy cao hơn mặt sàn chừng này thì tia lướt qua bên dưới.
const CAO_THOAT := 0.9
## Tốc độ quay nền lúc đầu và lúc cuối, radian/giây. Từng tia còn nhân thêm hệ số riêng.
const TOC_DAU := 0.55
const TOC_CUOI := 1.9
## Tăng hết tốc nền sau chừng này giây.
const GIAY_TANG_HET := 60.0

## Báo trước bao lâu rồi tia mới ăn người.
const GIAY_BAO := 1.1
## Một đợt kéo dài bao lâu, đầu ván và cuối ván.
const DOT_DAU := 3.6
const DOT_CUOI := 2.0
## Nghỉ giữa hai đợt. Nghỉ là lúc người chơi dịch chỗ — bỏ hẳn thì thành đọc tia liên tục không
## kịp thở, mà đó là khó vì rối chứ không khó vì cần giỏi.
const NGHI_DAU := 1.5
const NGHI_CUOI := 0.5
## Đợt và nghỉ co hết cỡ sau chừng này giây.
const GIAY_CO_HET := 45.0

## Tia quay quanh điểm lệch khỏi tâm sàn tối đa chừng này mét. Xem ghi chú "thanh 30 m" đầu file
## — nới con số này thì phải nới cả chiều dài thanh trong `san_laser.tscn`.
const LECH_TOI_DA := 3.0
## Hệ số tốc riêng của từng tia nằm trong khoảng này. Hai đầu phải LỆCH NHAU đủ để hai tia không
## trùng nhịp, nhưng không rộng tới mức có tia bò và có tia vụt.
const NHAN_TOC := Vector2(0.75, 1.35)

## Các kiểu đợt. Thứ tự này cũng là thứ tự khó dần — `kieu_cho_phep()` mở dần theo thời gian.
enum { MOT, DOI, CHEO, LIEN, NHIEU }

## Lúc còn đang báo thì mesh mỏng còn bao nhiêu phần so với lúc ăn người.
const DAY_KHI_BAO := 0.3

var _tia: Array[Node3D] = []
## Mesh và vùng va chạm của từng tia, cùng thứ tự với `_tia`.
var _mat: Array[MeshInstance3D] = []
var _vung: Array[Area3D] = []
## Tia nào đang THẬT SỰ ăn người. `_toi_thua()` chỉ hỏi những tia này.
var _an: Array[bool] = []
var _lich: Array = []
## Đợt đang chạy; -1 = chưa tới đợt nào.
var _dot := -1

var _mau_an: StandardMaterial3D = null
var _mau_bao: StandardMaterial3D = null


func _ready() -> void:
	super()
	ten = "LASER LEAP"
	luat = "WASD chạy · Space nhảy qua tia · đọc hướng tia, đừng nhảy theo nhịp"
	# Chốt chặn, không phải giới hạn thật: ván gần như luôn kết thúc vì còn một người. Để 0 thì
	# hai người giỏi có thể kéo nhau vô hạn và cả phòng ngồi chờ.
	giay_van = 90.0


func _dung_san() -> void:
	_tia.assign(san.find_children("Tia*", "Node3D", false, false))
	_mat.clear()
	_vung.clear()
	_an.clear()
	for t in _tia:
		_mat.append(t.get_node("Mat") as MeshInstance3D)
		_vung.append(t.get_node("Vung") as Area3D)
		_an.append(false)
	if _tia.is_empty():
		push_error("LaserLeap: san khong co node ten Tia*")
		return
	_mau_an = _tia[0].get_node("Mat").material_override as StandardMaterial3D
	_mau_bao = load("res://materials/mat_san_thuong.tres") as StandardMaterial3D
	_lich = lich_dot(hat_giong, _tia.size())
	_dot = -1
	for i in _tia.size():
		_tat(i)


func _luat_moi_nhip() -> void:
	var t := gio()
	# Tiến con trỏ đợt. Dùng `while` chứ không `if`: một khung hình dài (nạp scene, sụt khung)
	# có thể trôi qua cả một đợt ngắn, và bỏ qua đợt thì tia của nó không bao giờ tắt.
	while _dot + 1 < _lich.size() and t >= float(_lich[_dot + 1]["luc"]) - GIAY_BAO:
		_dot += 1
	if _dot < 0:
		return
	var d: Dictionary = _lich[_dot]
	var ds: Array = d["tia"]
	var bat_dau := float(d["luc"])
	for i in _tia.size():
		if i >= ds.size() or t >= float(d["het"]):
			_tat(i)
			continue
		var m: Dictionary = ds[i]
		_tia[i].visible = true
		_tia[i].position = Vector3(float(m["lx"]), 0.45, float(m["lz"]))
		# Góc = pha đầu + hướng × hệ số × (tích phân tốc nền từ lúc đợt bắt đầu tới giờ).
		# Lấy HIỆU hai tích phân chứ không nhân tốc với thời gian: xem `goc_quay()` ở lớp cha,
		# nhân thẳng thì mỗi lúc tốc nền đổi là góc giật một cái qua chỗ người đang đứng.
		# `maxf` chứ không `t` trần: lúc còn đang báo thì `t < bat_dau`, hiệu ra ÂM và tia quay
		# LÙI suốt lúc báo. Tia đứng yên lúc báo rồi mới chạy thì đọc hướng rõ hơn.
		var quet := goc_quay(0.0, maxf(t, bat_dau), TOC_DAU, TOC_CUOI, GIAY_TANG_HET) \
				- goc_quay(0.0, bat_dau, TOC_DAU, TOC_CUOI, GIAY_TANG_HET)
		_tia[i].rotation.y = float(m["pha"]) + float(m["huong"]) * float(m["nhan"]) * quet
		_dat_an(i, t >= bat_dau)


## Tia đang ăn người thì đỏ và dày thật; đang báo thì nhạt và mỏng.
##
## Không tắt/bật `Area3D.monitoring`: `overlaps_body()` cần vùng đã bật SẴN ít nhất một khung
## hình vật lý mới trả lời đúng, nên bật đúng lúc tia thành sát thương là mất một hai khung đầu.
## Để vùng bật suốt rồi chặn bằng `_an[i]` trong `_toi_thua()` vừa đúng vừa bớt một thứ phải nhớ.
func _dat_an(i: int, an: bool) -> void:
	_an[i] = an
	_mat[i].material_override = _mau_an if an else _mau_bao
	_mat[i].scale = Vector3.ONE if an else Vector3(1.0, 1.0, DAY_KHI_BAO)


func _tat(i: int) -> void:
	_an[i] = false
	_tia[i].visible = false


## Ghi đè chứ không thêm hàm mới: sàn tròn nên chạy quá đà vẫn rơi, phải giữ cả luật của lớp cha.
func _toi_thua() -> bool:
	if super():
		return true
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return false
	if p.global_position.y - san.global_position.y > CAO_THOAT:
		return false                    # đang ở trên không, tia lướt dưới chân
	# Hỏi thẳng `Area3D` chứ KHÔNG tự tính hình học: hộp va chạm và thanh tia nhìn thấy là cùng
	# một kích thước trong `.tscn`, nên chúng không thể lệch nhau.
	#
	# Bản trước tự tính với `BE_DAY = 0.55` trong khi mesh rộng 0.70 — người chơi đứng RÕ RÀNG
	# trong tia mà không chết. Đúng loại lỗi mà một con số chép tay ở hai nơi luôn đẻ ra.
	for i in _vung.size():
		if _an[i] and _vung[i] != null and _vung[i].overlaps_body(p):
			return true
	return false


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Một đợt kéo dài bao lâu tại giây `t`.
static func dai_dot(t: float) -> float:
	return lerpf(DOT_DAU, DOT_CUOI, clampf(t / GIAY_CO_HET, 0.0, 1.0))


## Nghỉ giữa hai đợt tại giây `t`.
static func nghi(t: float) -> float:
	return lerpf(NGHI_DAU, NGHI_CUOI, clampf(t / GIAY_CO_HET, 0.0, 1.0))


## Đợt bắt đầu ở giây `t` được dùng những kiểu nào, và tối đa mấy tia.
##
## Mở dần: đầu ván một tia cho người chơi học cách đọc, giữa ván thêm hướng ngược và tia chéo,
## cuối ván mới cho nhiều tia cùng lúc. Đây là chỗ độ khó tăng — KHÔNG phải ở tốc độ.
static func kieu_cho_phep(t: float) -> Array:
	if t < 10.0:
		return [MOT]
	if t < 22.0:
		return [MOT, DOI]
	if t < 34.0:
		return [DOI, CHEO, LIEN]
	return [DOI, CHEO, LIEN, NHIEU]


## Mấy tia cho một kiểu đợt.
static func so_tia_cho(kieu: int, toi_da: int) -> int:
	match kieu:
		MOT: return 1
		DOI, CHEO, LIEN: return mini(2, toi_da)
		_: return mini(4, toi_da)


## Toàn bộ lịch đợt của một ván, suy ra từ hạt giống. Mọi máy dựng ra y hệt.
##
## Mỗi đợt: `luc` bắt đầu ăn người, `het` lúc tắt, và một mảng tia với hướng / hệ số tốc / pha
## đầu / điểm lệch tâm. `luc` đã trừ sẵn phần báo trước ở `_luat_moi_nhip`.
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
		# Hướng và pha của tia ĐẦU; các tia sau đặt tương đối với nó theo kiểu đợt.
		var huong0 := 1.0 if rng.randf() < 0.5 else -1.0
		var pha0 := rng.randf() * TAU
		for k in n:
			var huong := huong0
			var nhan := 1.0
			var pha := pha0
			match kieu:
				DOI:
					# Ngược chiều, cùng tốc: hai tia cắt nhau hai lần mỗi vòng, và chỗ cắt dịch
					# dần — không có nhịp nào lặp lại.
					huong = huong0 if k == 0 else -huong0
					pha = pha0 + PI * k
				CHEO:
					# Khác tốc, khác điểm lệch: hai nhịp không bao giờ về cùng một nhịp.
					nhan = rng.randf_range(NHAN_TOC.x, NHAN_TOC.y)
					pha = pha0 + rng.randf() * TAU
				LIEN:
					# Cùng chiều, pha sát nhau: tia này vừa qua thì tia kia tới ngay — không cho
					# thả lỏng sau nhịp nhảy đầu.
					pha = pha0 + float(k) * rng.randf_range(0.35, 0.6)
				NHIEU:
					huong = 1.0 if rng.randf() < 0.5 else -1.0
					nhan = rng.randf_range(NHAN_TOC.x, NHAN_TOC.y)
					pha = pha0 + TAU * float(k) / float(n)
				_:
					nhan = rng.randf_range(NHAN_TOC.x, NHAN_TOC.y)
			var goc_lech := rng.randf() * TAU
			var r_lech := rng.randf() * LECH_TOI_DA
			tia.append({
				"huong": huong,
				"nhan": nhan,
				"pha": pha,
				"lx": cos(goc_lech) * r_lech,
				"lz": sin(goc_lech) * r_lech,
			})
		ds.append({"luc": t, "het": t + dai, "kieu": kieu, "tia": tia})
		t += dai + nghi(t) + GIAY_BAO
	return ds
