extends MiniGame3D

## LASER LEAP — tia quét quay sát mặt sàn, nhảy qua; còn một người là xong.
## Tia quay theo lịch đợt (hướng, tốc, pha, lệch tâm đổi mỗi đợt) để không có nhịp cố định.
## Tia báo trước `GIAY_BAO` giây rồi mới ăn người. Góc tia là hàm của `gio()` — 0 gói tin.

## Kiểu đợt, theo thứ tự khó dần.
enum { MOT, DOI, CHEO, LIEN, NHIEU }

const CAO_THOAT := 0.9

## Tốc quay nền đầu/cuối ván (rad/s); mỗi tia nhân hệ số riêng.
const TOC_DAU := 0.55
const TOC_CUOI := 1.9
const GIAY_TANG_HET := 60.0
const GIAY_BAO := 1.1

## Độ dài một đợt, đầu/cuối ván.
const DOT_DAU := 3.6
const DOT_CUOI := 2.0

## Nghỉ giữa hai đợt (lúc dịch chỗ).
const NGHI_DAU := 1.5
const NGHI_CUOI := 0.5
const GIAY_CO_HET := 45.0

## Tâm quay lệch tối đa (nới thì phải nới chiều dài thanh tia trong scene).
const LECH_TOI_DA := 3.0

## Khoảng hệ số tốc riêng của từng tia.
const NHAN_TOC := Vector2(0.75, 1.35)

## Độ dày tia lúc đang báo (so với lúc ăn người).
const DAY_KHI_BAO := 0.3

## Vật liệu tia lúc báo trước.
@export var mat_bao: StandardMaterial3D = null

var _tia: Array[Node3D] = []
var _mat: Array[MeshInstance3D] = []
var _vung: Array[Area3D] = []

## Tia đang thật sự ăn người.
var _an: Array[bool] = []
var _lich: Array = []

## -1 = chưa tới đợt nào.
var _dot := -1
var _mau_an: StandardMaterial3D = null


func _ready() -> void:
	super()
	ten = "LASER LEAP"
	luat = "WASD chạy · Space nhảy qua tia · đọc hướng tia, đừng nhảy theo nhịp"
	# Chốt chặn: ván gần như luôn kết thúc vì còn một người.
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
	_lich = lich_dot(hat_giong, _tia.size())
	_dot = -1
	for i in _tia.size():
		_tat(i)


func _luat_moi_nhip() -> void:
	var t := gio()
	# `while`: một khung dài có thể trôi qua cả một đợt ngắn.
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
		# Góc = pha đầu + hướng × hệ số × tích phân tốc nền; lúc báo thì tia đứng yên.
		var quet := goc_quay(0.0, maxf(t, bat_dau), TOC_DAU, TOC_CUOI, GIAY_TANG_HET) \
				- goc_quay(0.0, bat_dau, TOC_DAU, TOC_CUOI, GIAY_TANG_HET)
		_tia[i].rotation.y = float(m["pha"]) + float(m["huong"]) * float(m["nhan"]) * quet
		_dat_an(i, t >= bat_dau)


## Đang ăn người: đỏ và dày; đang báo: nhạt và mỏng (vùng va chạm luôn bật, chặn bằng `_an`).
func _dat_an(i: int, an: bool) -> void:
	_an[i] = an
	_mat[i].material_override = _mau_an if an else mat_bao
	_mat[i].scale = Vector3.ONE if an else Vector3(1.0, 1.0, DAY_KHI_BAO)


func _tat(i: int) -> void:
	_an[i] = false
	_tia[i].visible = false


## Giữ cả luật rơi của lớp cha.
func _toi_thua() -> bool:
	if super():
		return true
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return false
	if p.global_position.y - san.global_position.y > CAO_THOAT:
		return false  # đang trên không, tia lướt dưới chân
	# Hỏi thẳng `Area3D` (cùng kích thước với tia nhìn thấy).
	for i in _vung.size():
		if _an[i] and _vung[i] != null and _vung[i].overlaps_body(p):
			return true
	return false


# ─── luật: hàm thuần ───


static func dai_dot(t: float) -> float:
	return lerpf(DOT_DAU, DOT_CUOI, clampf(t / GIAY_CO_HET, 0.0, 1.0))


static func nghi(t: float) -> float:
	return lerpf(NGHI_DAU, NGHI_CUOI, clampf(t / GIAY_CO_HET, 0.0, 1.0))


## Kiểu đợt và số tia tối đa được dùng tại giây `t` (mở dần theo thời gian).
static func kieu_cho_phep(t: float) -> Array:
	if t < 10.0:
		return [MOT]
	if t < 22.0:
		return [MOT, DOI]
	if t < 34.0:
		return [DOI, CHEO, LIEN]
	return [DOI, CHEO, LIEN, NHIEU]


static func so_tia_cho(kieu: int, toi_da: int) -> int:
	match kieu:
		MOT: return 1
		DOI, CHEO, LIEN: return mini(2, toi_da)
		_: return mini(4, toi_da)


## Lịch đợt cả ván từ hạt giống: mỗi đợt {luc, het, tia: [hướng, hệ số tốc, pha, lệch tâm]}.
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
		# Tia đầu; các tia sau đặt tương đối theo kiểu đợt.
		var huong0 := 1.0 if rng.randf() < 0.5 else -1.0
		var pha0 := rng.randf() * TAU
		for k in n:
			var huong := huong0
			var nhan := 1.0
			var pha := pha0
			match kieu:
				DOI:
					# Ngược chiều, cùng tốc.
					huong = huong0 if k == 0 else -huong0
					pha = pha0 + PI * k
				CHEO:
					# Khác tốc, khác điểm lệch.
					nhan = rng.randf_range(NHAN_TOC.x, NHAN_TOC.y)
					pha = pha0 + rng.randf() * TAU
				LIEN:
					# Cùng chiều, pha sát nhau.
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
