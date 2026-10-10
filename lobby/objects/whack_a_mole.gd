class_name WhackAMole
extends Node3D

## Đập chuột chũi trên model máy arcade "Whack em All": chuột nhô lên từ 5 lỗ có sẵn trên mặt máy.
## Master gieo lỗ và chấm điểm, phát nguyên trạng thái JSON. Chuột chỉ là hình, không vật lý.

enum Pha { CHO, DEM_NGUOC, CHOI, XONG }
enum Lenh { BAT_DAU, LAM_LAI }


## Vị trí 5 lỗ (đo bằng tia quét khi máy cao CAO_DO). Đổi model thì đo lại.
const LO_MAY := [
	Vector3(-0.125, 0.534, -0.968),
	Vector3(-0.125, 0.534, -0.693),
	Vector3(-0.369, 0.660, -1.038),
	Vector3(-0.369, 0.660, -0.826),
	Vector3(-0.369, 0.660, -0.610),
]
const SO_LO := 5
const CAO_DO := 1.6
## Bán kính miệng lỗ ở CAO_DO.
const BAN_KINH_LO := 0.045
## Đoạn đứng yên / bị đập trong clip gốc (giây, clip dài 9.42 s).
const DOAN_DUNG := [0.9, 3.4]
const DOAN_DAP := [8.3, 8.8]

## Chiều cao máy (m); lỗ, chuột, nút, bảng tính theo số này. Scale node `May` thì sửa theo.
@export var may_cao := 2.0
## Độ dài hiệp, giây.
@export var giay_hiep := 45.0
@export var giay_dem_nguoc := 3.0
## Thời gian chuột ở trên trước khi thụt xuống.
@export var chuot_len_min := 1.8
@export var chuot_len_max := 3.2
## Nghỉ giữa hai lần nhô của cùng một lỗ.
@export var nghi_min := 0.7
@export var nghi_max := 1.8
## Trúng khi tia nhìn đi qua đỉnh chuột trong bán kính này (không đo từ đầu búa vì lỗ quá gần nhau).
@export var ban_kinh_ngam := 0.3
## Xa hơn chừng này thì không với tới.
@export var tam_voi := 3.0

var _pha := Pha.CHO
## Bit i = lỗ i đang có chuột.
var _len := 0
var _diem: Dictionary = {}
var _moc := 0.0
## "id,id:diem" của người thắng, rỗng = chưa ai đập trúng.
var _thang := ""

## Master: giờ (đồng hồ master) lỗ i đổi trạng thái.
var _han: Array[float] = []
var _than: Array[Node3D] = []
var _anim: Array[AnimationPlayer] = []
var _giay_dem := -1
## Xoay và dịch của model máy, để đổi toạ độ lỗ sang node này.
var _goc_may := Basis.IDENTITY
var _dich_may := Vector3.ZERO

## Bảng, đếm ngược, pháo hoa, nút dựng sẵn trong whack_a_mole.tscn.
@onready var _bang: Label3D = $Bang
@onready var _dem: Label3D = $Dem
@onready var _no: CPUParticles3D = $No


func _ready() -> void:
	add_to_group("whack_a_mole")
	Fusion.register_broadcast_receiver(self)
	_dung_may()  # chạy trước: chuột, nút, bảng bám theo máy
	_dung_chuot()
	for i in SO_LO:
		_han.append(0.0)
	if not NetManager.is_master():
		_xin_trang_thai.call_deferred()


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


## Tỉ lệ giữa máy thật và lúc đo lỗ.
func _ti() -> float:
	return may_cao / CAO_DO


## Độ cao mặt chơi (miệng lỗ thấp nhất).
func _mat_choi() -> float:
	return LO_MAY[0].y * _ti()


## Chiều cao con chuột, vừa lòng miệng lỗ.
func _cao_chuot() -> float:
	return BAN_KINH_LO * 3.6 * _ti()


## Chuột nhô cao hơn đáy lỗ chừng này.
func _len_cao() -> float:
	return _cao_chuot() * 0.6


## Vị trí lỗ i trong toạ độ node này.
func _cho_lo(i: int) -> Vector3:
	return _goc_may * (LO_MAY[i] * _ti()) + _dich_may


# ─── mạng ───

func _xin(lenh: int) -> void:
	Fusion.rpc(_net_xin, lenh, NetManager.local_id())


func _xin_trang_thai() -> void:
	Fusion.rpc(_net_xin_trang_thai)


@rpc("any_peer", "call_local")
func _net_xin_trang_thai() -> void:
	if NetManager.is_master():
		_phat("")


@rpc("any_peer", "call_local")
func _net_xin(lenh: int, _nguoi: int) -> void:
	if not NetManager.is_master():
		return
	match lenh:
		Lenh.BAT_DAU:
			if _pha == Pha.CHO or _pha == Pha.XONG:
				_diem = {}
				_len = 0
				_thang = ""
				_pha = Pha.DEM_NGUOC
				_moc = _gio() + giay_dem_nguoc
				_phat("dem")
		Lenh.LAM_LAI:
			if _pha != Pha.CHOI:
				_diem = {}
				_len = 0
				_thang = ""
				_pha = Pha.CHO
				_phat("lam_lai")


## Máy người vung búa gọi: tia nhìn có đi qua con chuột nào đang lên không.
func thu_dap(goc: Vector3, huong: Vector3, nguoi: int) -> void:
	if _pha != Pha.CHOI:
		return
	var trung := -1
	var gan_nhat := ban_kinh_ngam
	for i in SO_LO:
		if _len & (1 << i) == 0:
			continue
		var toi := _dinh_chuot(i) - goc
		var xa := toi.dot(huong)
		if xa < 0.0 or xa > tam_voi:
			continue
		var lech := (toi - huong * xa).length()
		if lech < gan_nhat:
			gan_nhat = lech
			trung = i
	if trung >= 0:
		Fusion.rpc(_net_dap, trung, nguoi)


@rpc("any_peer", "call_local")
func _net_dap(lo: int, nguoi: int) -> void:
	if not NetManager.is_master():
		return
	if _pha != Pha.CHOI or lo < 0 or lo >= SO_LO or _len & (1 << lo) == 0:
		return
	var truoc := _len
	_len &= ~(1 << lo)
	_han[lo] = _gio() + randf_range(nghi_min, nghi_max)
	_diem[str(nguoi)] = int(_diem.get(str(nguoi), 0)) + 1
	_cap_nhat_chuot(truoc)
	_phat("dap:%d" % lo)


func _phat(su_kien: String) -> void:
	var ms := 0
	if _pha == Pha.DEM_NGUOC or _pha == Pha.CHOI:
		ms = roundi(maxf(0.0, _moc - _gio()) * 1000.0)
	Fusion.rpc(_net_trang_thai, JSON.stringify({
		"pha": _pha, "len": _len, "diem": _diem, "ms": ms, "thang": _thang, "su_kien": su_kien,
	}))


@rpc("any_peer", "call_local")
func _net_trang_thai(json: String) -> void:
	var g = JSON.parse_string(json)
	if not (g is Dictionary):
		return
	if not NetManager.is_master():
		var truoc := _len
		_pha = clampi(int(g.get("pha", 0)), Pha.CHO, Pha.XONG) as Pha
		_len = int(g.get("len", 0))
		var d = g.get("diem")
		_diem = d if d is Dictionary else {}
		_thang = str(g.get("thang", ""))
		var giay := float(g.get("ms", 0)) / 1000.0
		var tre := NetManager.rtt_ms() / 2000.0
		if _pha == Pha.DEM_NGUOC or _pha == Pha.CHOI:
			_moc = _gio() + giay - tre
		if truoc != _len:
			_cap_nhat_chuot(truoc)
	_hieu_ung(str(g.get("su_kien", "")))


# ─── luật (master) ───

func _process(_delta: float) -> void:
	_ve_bang()
	_tich_tac()
	if not NetManager.is_master():
		return
	if _pha == Pha.DEM_NGUOC and _gio() >= _moc:
		_pha = Pha.CHOI
		_moc = _gio() + giay_hiep
		for i in SO_LO:
			_han[i] = _gio() + randf_range(0.2, 1.2)
		_phat("bat_dau")
		return
	if _pha != Pha.CHOI:
		return
	if _gio() >= _moc:
		_pha = Pha.XONG
		var truoc := _len
		_len = 0
		_thang = _ai_thang()
		_cap_nhat_chuot(truoc)
		_phat("thang")
		return
	var doi := false
	var cu := _len
	for i in SO_LO:
		if _gio() < _han[i]:
			continue
		if _len & (1 << i) != 0:
			_len &= ~(1 << i)
			_han[i] = _gio() + randf_range(nghi_min, nghi_max)
		else:
			_len |= 1 << i
			_han[i] = _gio() + randf_range(chuot_len_min, chuot_len_max)
		doi = true
	if doi:
		_cap_nhat_chuot(cu)
		_phat("chuot")


## Trả "id,id:diem"; máy nhận tự đổi ra tên (master có thể chưa có tên người đó).
func _ai_thang() -> String:
	var cao := 0
	var ids: PackedStringArray = []
	for k in _diem:
		var v := int(_diem[k])
		if v > cao:
			cao = v
			ids = [str(k)]
		elif v == cao and v > 0:
			ids.append(str(k))
	if cao == 0:
		return ""
	return "%s:%d" % [",".join(ids), cao]


## Đổi "id,id:diem" ra câu hiện lên bảng.
func _cau_thang() -> String:
	if _thang == "":
		return "KHONG AI DAP TRUNG CON NAO"
	var doi := _thang.split(":")
	if doi.size() != 2:
		return _thang
	var ten: PackedStringArray = []
	for id in doi[0].split(",", false):
		ten.append(Player.ten_theo_id(get_tree(), int(id)))
	return "%s THANG - %s CHUOT" % [" & ".join(ten), doi[1]]


# ─── hiển thị ───

func _dinh_chuot(i: int) -> Vector3:
	return to_global(_cho_lo(i) + Vector3.UP * (_len_cao() + _cao_chuot() * 0.5))


func _cap_nhat_chuot(truoc: int) -> void:
	for i in SO_LO:
		if i >= _than.size():
			return
		var gio_len := _len & (1 << i) != 0
		if gio_len == (truoc & (1 << i) != 0):
			continue
		var than := _than[i]
		var tw := than.create_tween()
		tw.tween_property(than, "position:y", _len_cao() if gio_len else -_cao_chuot(), 0.3) \
				.set_trans(Tween.TRANS_BACK if gio_len else Tween.TRANS_QUAD)
		if gio_len:
			than.visible = true
			_dien(i, DOAN_DUNG, true)
		else:
			# Lỗ chỉ lõm vài cm, nhìn từ trên vẫn thấy — ẩn hẳn.
			tw.tween_callback(func(): than.visible = false)


## Chạy một đoạn của clip gốc bằng `play_section`.
func _dien(i: int, doan: Array, lap: bool) -> void:
	if i >= _anim.size():
		return
	var ap := _anim[i]
	if ap == null:
		return
	var ten: String = ap.get_animation_list()[0]
	ap.get_animation(ten).loop_mode = Animation.LOOP_LINEAR if lap else Animation.LOOP_NONE
	if ap.has_method("play_section"):
		ap.play_section(ten, doan[0], doan[1], -1.0, 1.0)
	else:
		ap.play(ten)
		ap.seek(doan[0], true)


func _ve_bang() -> void:
	var dong: PackedStringArray = ["DAP CHUOT CHUI"]
	match _pha:
		Pha.CHO:
			dong.append("BAM BAT DAU")
		Pha.DEM_NGUOC:
			dong.append("CHUAN BI...")
		Pha.CHOI:
			dong.append("CON %d GIAY" % maxi(0, ceili(_moc - _gio())))
		Pha.XONG:
			dong.append(_cau_thang())
	var ds: Array = []
	for k in _diem:
		ds.append([int(_diem[k]), int(k)])
	ds.sort_custom(func(a, b): return a[0] > b[0])
	for c in ds:
		dong.append("%s  %d" % [Player.ten_theo_id(get_tree(), c[1]), c[0]])
	_bang.text = "\n".join(dong)
	_dem.visible = _pha == Pha.DEM_NGUOC
	if _dem.visible:
		_dem.text = str(maxi(1, ceili(_moc - _gio())))


func _tich_tac() -> void:
	if _pha != Pha.DEM_NGUOC:
		_giay_dem = -1
		return
	var g := ceili(_moc - _gio())
	if g != _giay_dem and g > 0:
		_giay_dem = g
		_keu("dem")


func _hieu_ung(su_kien: String) -> void:
	if su_kien.begins_with("dap:"):
		var lo := int(su_kien.substr(4))
		_keu("dap")
		_dien(lo, DOAN_DAP, false)
		_no.global_position = _dinh_chuot(lo)
		_no.restart()
		return
	match su_kien:
		"chuot":
			_keu("chuot")
		"dem", "bat_dau", "lam_lai":
			_keu(su_kien)
		"thang":
			_keu("thang")
			_no.global_position = to_global(Vector3(0.0, may_cao * 0.7, 0.4))
			_no.restart()


## Phát `Tieng/<ten>` (AudioStreamPlayer3D trong scene).
func _keu(ten: String) -> void:
	var loa := get_node_or_null("Tieng/" + ten) as AudioStreamPlayer3D
	if loa != null:
		loa.play()


# ─── dựng hình ───


## Máy arcade: node `May`, mặt chơi hướng +Z; va chạm StaticSurface_Machine.
func _dung_may() -> void:
	var may := $May as Node3D
	_goc_may = Basis(Vector3.UP, may.rotation.y)
	_dich_may = may.position


## Chuột: `Lo0`..`Lo4` / `Than` / `Chuot`; `Than` ẩn sẵn, trượt lên xuống khi chơi.
func _dung_chuot() -> void:
	for i in SO_LO:
		var than := get_node("Lo%d/Than" % i) as Node3D
		_than.append(than)
		var ap := than.find_child("AnimationPlayer", true, false) as AnimationPlayer
		_anim.append(ap)
		if ap != null:
			_dien(i, DOAN_DUNG, true)
