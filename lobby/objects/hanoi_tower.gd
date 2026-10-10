class_name HanoiTower
extends Node3D

## Tháp Hà Nội: 3 cọc, 6–8 đĩa, chuyển hết từ A sang C với ít bước nhất.
## Không vật lý: đĩa vẽ theo `_coc`. Master giữ luật và phát nguyên trạng thái JSON;
## máy nào cũng giữ đủ nên đổi master vẫn chơi tiếp.
## Ai bấm BẮT ĐẦU thì ván là của người đó; bỏ đi `giay_bo_di` giây thì ai cũng LÀM LẠI được.

enum Pha { CHO, DEM_NGUOC, CHOI, XONG }
enum Lenh { COC, BAT_DAU, LAM_LAI, SO_DIA }

const MAU_DIA: Array[Color] = [
	Color("e5484d"), Color("f76b15"), Color("f5d90a"), Color("46a758"),
	Color("00b8d9"), Color("3e63dd"), Color("8e4ec6"), Color("d6409f"),
]
const MAU_DUNG := Color("46a758")
const MAU_SAI := Color("e5484d")
const MAU_DANG_CAM := Color("f5d90a")
const MAU_DE_COC := Color("5a3a26")
const DE_DAY := 0.06
## Lỗ giữa đĩa, lớn hơn thân cọc chút.
const LO_DIA := 0.024
## Chỗ đĩa đang cầm, hệ toạ độ camera (xem Player.diem_cam).
const CHO_CAM := Vector3(0.0, -0.22, -0.55)

## Đĩa và chữ nổi sinh lúc chạy (số đĩa đổi theo ván).
@export var dia_scene: PackedScene
@export var chu_bay_scene: PackedScene
@export_range(6, 8) var so_dia := 6
@export var ban_cao := 0.9
@export var khoang_coc := 0.5
@export var coc_cao := 0.42
@export var ban_kinh_nho := 0.07
@export var ban_kinh_lon := 0.2
@export var day_dia := 0.045
@export var giay_dem_nguoc := 3.0
## Người chơi không bấm cọc chừng này giây thì người khác được LÀM LẠI / BẮT ĐẦU.
@export var giay_bo_di := 30.0

# ─── trạng thái: mọi máy giữ giống nhau, master là nguồn ───
var _pha := Pha.CHO
## Mỗi cọc là mảng đĩa từ dưới lên; đĩa 0 nhỏ nhất.
var _coc: Array = [[], [], []]
var _nguoi := 0
## Cọc có đĩa đang nhấc, -1 = không (đĩa vẫn nằm trong mảng tới khi đặt).
var _cam_tu := -1
var _buoc := 0
## Giờ máy này: DEM_NGUOC = lúc hết đếm, CHOI = lúc bắt đầu tính giờ.
var _moc := 0.0
var _giay_xong := 0.0
## "số đĩa" → [bước, ms, tên]; giữ tên để người giữ kỷ lục rời phòng vẫn còn.
var _ky_luc: Dictionary = {}
## Lần cuối người chơi bấm cọc; máy nào cũng ghi để đổi master vẫn có.
var _lan_cuoi := 0.0
var _dia: Array[MeshInstance3D] = []
var _coc_nut: Array[Pressable] = []
var _coc_de: Array[StandardMaterial3D] = []
var _giay_dem := -1
var _kiem_nguoi := 0.0

## Bàn, cọc, nút và bảng dựng sẵn trong hanoi_tower.tscn (số đo khớp các export ở trên).
@onready var _nut_so_dia: Pressable = $HanoiSoDia
@onready var _bang: Label3D = $Bang
@onready var _dem: Label3D = $Dem
@onready var _no: CPUParticles3D = $No


func _ready() -> void:
	add_to_group("hanoi_tower")
	Fusion.register_broadcast_receiver(self)
	for i in 3:
		var coc := get_node("HanoiCoc%d" % i) as Pressable
		_coc_nut.append(coc)
		_coc_de.append((coc.get_node("De") as MeshInstance3D).material_override)
	_dat_coc_ban_dau()
	_dung_dia()
	# Người vào muộn tự xin lại trạng thái.
	if not NetManager.is_master():
		_xin_trang_thai.call_deferred()


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


func _mat_de() -> float:
	return ban_cao + DE_DAY


func _x_coc(i: int) -> float:
	return (i - 1) * khoang_coc


# ─── mạng ───

func _xin(lenh: int, coc := -1) -> void:
	Fusion.rpc(_net_xin, lenh, coc, NetManager.local_id())


func _xin_trang_thai() -> void:
	Fusion.rpc(_net_xin_trang_thai)


@rpc("any_peer", "call_local")
func _net_xin_trang_thai() -> void:
	if NetManager.is_master():
		_phat("")


@rpc("any_peer", "call_local")
func _net_xin(lenh: int, coc: int, nguoi: int) -> void:
	if not NetManager.is_master():
		return
	var su_kien := ""
	match lenh:
		Lenh.COC:
			su_kien = _bam_coc(coc, nguoi)
		Lenh.BAT_DAU:
			if _duoc_dieu_khien(nguoi):
				_bat_dau(nguoi)
				su_kien = "dem"
		Lenh.LAM_LAI:
			if _duoc_dieu_khien(nguoi):
				_ve_cho()
				su_kien = "lam_lai"
		Lenh.SO_DIA:
			if _pha == Pha.CHO or _pha == Pha.XONG:
				so_dia = 6 if so_dia >= 8 else so_dia + 1
				_ve_cho()
				_dung_dia()
				su_kien = "lam_lai"
	if su_kien != "":
		_phat(su_kien)


func _phat(su_kien: String) -> void:
	var ms := 0
	match _pha:
		Pha.DEM_NGUOC:
			ms = roundi(maxf(0.0, _moc - _gio()) * 1000.0)
		Pha.CHOI:
			ms = roundi((_gio() - _moc) * 1000.0)
		Pha.XONG:
			ms = roundi(_giay_xong * 1000.0)
	var goi := {
		"pha": _pha, "so_dia": so_dia, "coc": _coc, "nguoi": _nguoi, "cam": _cam_tu,
		"buoc": _buoc, "ms": ms, "ky_luc": _ky_luc, "su_kien": su_kien,
	}
	Fusion.rpc(_net_trang_thai, JSON.stringify(goi))


@rpc("any_peer", "call_local")
func _net_trang_thai(json: String) -> void:
	var g = JSON.parse_string(json)
	if not (g is Dictionary):
		return
	# Master đã có trạng thái này, chỉ cần hiệu ứng.
	if not NetManager.is_master():
		_ap_dung(g)
	_hieu_ung(str(g.get("su_kien", "")))


func _ap_dung(g: Dictionary) -> void:
	var coc = g.get("coc")
	if not (coc is Array) or coc.size() != 3:
		return
	var moi: Array = [[], [], []]
	for i in 3:
		if not (coc[i] is Array):
			return
		for v in coc[i]:
			moi[i].append(int(v))
	_coc = moi
	_pha = clampi(int(g.get("pha", 0)), Pha.CHO, Pha.XONG) as Pha
	_nguoi = int(g.get("nguoi", 0))
	_cam_tu = int(g.get("cam", -1))
	_buoc = int(g.get("buoc", 0))
	var ky = g.get("ky_luc")
	_ky_luc = ky if ky is Dictionary else {}
	# Đổi ms master gửi ra mốc giờ máy này, trừ nửa RTT.
	var giay := float(g.get("ms", 0)) / 1000.0
	var tre := NetManager.rtt_ms() / 2000.0
	match _pha:
		Pha.DEM_NGUOC:
			_moc = _gio() + giay - tre
		Pha.CHOI:
			_moc = _gio() - giay - tre
		Pha.XONG:
			_giay_xong = giay
	_lan_cuoi = _gio()
	var n := clampi(int(g.get("so_dia", 6)), 6, 8)
	if n != so_dia or _dia.size() != so_dia:
		so_dia = n
		_dung_dia()


# ─── luật (chỉ master) ───

func _duoc_dieu_khien(nguoi: int) -> bool:
	if _pha == Pha.CHO or _pha == Pha.XONG or nguoi == _nguoi:
		return true
	return _gio() - _lan_cuoi > giay_bo_di


func _bam_coc(i: int, nguoi: int) -> String:
	if _pha != Pha.CHOI or nguoi != _nguoi or i < 0 or i > 2:
		return ""
	_lan_cuoi = _gio()
	if _cam_tu < 0:
		if _coc[i].is_empty():
			return ""
		_cam_tu = i
		return "nhat"
	var dia: int = _coc[_cam_tu].back()
	var tu := _cam_tu
	_cam_tu = -1
	if i == tu:
		return "dat"
	# Sai luật: thả ra là đĩa tự về chỗ.
	if not _coc[i].is_empty() and int(_coc[i].back()) < dia:
		return "sai"
	_coc[tu].pop_back()
	_coc[i].append(dia)
	_buoc += 1
	if _coc[2].size() == so_dia:
		_xong()
		return "thang"
	return "dat"


func _bat_dau(nguoi: int) -> void:
	_ve_cho()
	_nguoi = nguoi
	_pha = Pha.DEM_NGUOC
	_moc = _gio() + giay_dem_nguoc
	_lan_cuoi = _gio()


func _ve_cho() -> void:
	_pha = Pha.CHO
	_nguoi = 0
	_buoc = 0
	_cam_tu = -1
	_dat_coc_ban_dau()


func _xong() -> void:
	_pha = Pha.XONG
	_giay_xong = _gio() - _moc
	var ms := roundi(_giay_xong * 1000.0)
	var cu = _ky_luc.get(str(so_dia))
	if cu == null or _buoc < int(cu[0]) or (_buoc == int(cu[0]) and ms < int(cu[1])):
		_ky_luc[str(so_dia)] = [_buoc, ms, Player.ten_theo_id(get_tree(), _nguoi)]


func _dat_coc_ban_dau() -> void:
	_coc = [[], [], []]
	for k in range(so_dia - 1, -1, -1):
		_coc[0].append(k)


func _process(delta: float) -> void:
	var t := 1.0 - exp(-delta * 14.0)
	for k in _dia.size():
		_dia[k].position = _dia[k].position.lerp(_dich_dia(k), t)
	_ve_bang()
	_to_coc()
	_tich_tac()
	if NetManager.is_master():
		_master_theo_doi(delta)


func _master_theo_doi(delta: float) -> void:
	if _pha == Pha.DEM_NGUOC and _gio() >= _moc:
		_pha = Pha.CHOI
		_moc = _gio()
		_lan_cuoi = _gio()
		_phat("bat_dau")
	# Người chơi rời phòng thì trả tháp về chỗ.
	_kiem_nguoi += delta
	if _kiem_nguoi < 0.5:
		return
	_kiem_nguoi = 0.0
	if (_pha == Pha.DEM_NGUOC or _pha == Pha.CHOI) and _nguoi_node(_nguoi) == null:
		_ve_cho()
		_phat("lam_lai")


# ─── hiển thị (mọi máy) ───

func _nguoi_node(id: int) -> Player:
	if id == 0:
		return null
	for n in get_tree().get_nodes_in_group("players"):
		if n is Player and n.player_id() == id:
			return n
	return null


## Chỗ đĩa k cần tới (toạ độ của tháp).
func _dich_dia(k: int) -> Vector3:
	for i in 3:
		var tang: int = _coc[i].find(k)
		if tang < 0:
			continue
		if i == _cam_tu and tang == _coc[i].size() - 1:
			var p := _nguoi_node(_nguoi)
			if p != null:
				return to_local(p.diem_cam(CHO_CAM).origin)
			return Vector3(_x_coc(i), _mat_de() + coc_cao + 0.12, 0.0)
		return Vector3(_x_coc(i), _mat_de() + day_dia * (tang + 0.5), 0.0)
	return Vector3.ZERO


func _giay_da_choi() -> float:
	match _pha:
		Pha.CHOI:
			return _gio() - _moc
		Pha.XONG:
			return _giay_xong
	return 0.0


func _dong_ho(giay: float) -> String:
	var g := int(giay)
	@warning_ignore("integer_division")
	return "%d:%02d" % [g / 60, g % 60]


func _ve_bang() -> void:
	var ten := Player.ten_theo_id(get_tree(), _nguoi)
	var dong: PackedStringArray = ["THAP HA NOI - %d DIA" % so_dia]
	match _pha:
		Pha.CHO:
			dong.append("BAM BAT DAU DE CHOI")
		Pha.DEM_NGUOC:
			dong.append("%s CHUAN BI" % ten)
		Pha.CHOI:
			dong.append("%s DANG CHOI" % ten)
		Pha.XONG:
			dong.append("%s XONG!" % ten)
	if _pha != Pha.CHO:
		dong.append("BUOC %d   (IT NHAT %d)" % [_buoc, (1 << so_dia) - 1])
		dong.append("THOI GIAN " + _dong_ho(_giay_da_choi()))
	var kl = _ky_luc.get(str(so_dia))
	if kl is Array and kl.size() == 3:
		dong.append("KY LUC: %s  %d BUOC  %s" % [kl[2], int(kl[0]), _dong_ho(int(kl[1]) / 1000.0)])
	else:
		dong.append("KY LUC: CHUA CO")
	_bang.text = "\n".join(dong)
	_nut_so_dia.set_label("%d DIA" % so_dia)
	_dem.visible = _pha == Pha.DEM_NGUOC
	if _dem.visible:
		_dem.text = str(maxi(1, ceili(_moc - _gio())))


## Đang cầm đĩa: cọc đặt được xanh, sai luật đỏ, cọc vừa nhấc vàng.
func _to_coc() -> void:
	var dia := -1
	if _cam_tu >= 0 and _cam_tu < 3 and not _coc[_cam_tu].is_empty():
		dia = _coc[_cam_tu].back()
	for i in 3:
		var mau := Color.WHITE
		var de := MAU_DE_COC
		if dia >= 0:
			if i == _cam_tu:
				mau = MAU_DANG_CAM
			elif _coc[i].is_empty() or int(_coc[i].back()) > dia:
				mau = MAU_DUNG
			else:
				mau = MAU_SAI
			de = mau.darkened(0.35)
		_coc_nut[i].text.modulate = mau
		_coc_de[i].albedo_color = de


## Tiếng tích tắc mỗi giây đếm ngược; mỗi máy tự đếm theo `_moc`.
func _tich_tac() -> void:
	if _pha != Pha.DEM_NGUOC:
		_giay_dem = -1
		return
	var g := ceili(_moc - _gio())
	if g != _giay_dem and g > 0:
		_giay_dem = g
		_keu("dem")


func _hieu_ung(su_kien: String) -> void:
	match su_kien:
		"nhat", "dat", "sai", "bat_dau", "lam_lai":
			_keu(su_kien)
		"thang":
			_keu("thang")
			_no.restart()
			var chu := chu_bay_scene.instantiate() as ChuBay
			# Thấp hơn bảng trạng thái và nhích ra trước để chữ không đè nhau.
			chu.position = Vector3(0.0, _mat_de() + 0.2, 0.3)
			add_child(chu)
			chu.bay("%s XONG!\n%d BUOC - %s" % [Player.ten_theo_id(get_tree(), _nguoi), _buoc,
					_dong_ho(_giay_xong)], 0.2, 2.5)


## Phát `Tieng/<ten>` (AudioStreamPlayer3D trong scene).
func _keu(ten: String) -> void:
	var loa := get_node_or_null("Tieng/" + ten) as AudioStreamPlayer3D
	if loa != null:
		loa.play()


# ─── dựng hình ───


## Đĩa k: vòng xuyến `dia_scene`, bán kính nội suy theo số đĩa, ép dẹt còn `day_dia`.
func _dung_dia() -> void:
	for d in _dia:
		d.queue_free()
	_dia.clear()
	for k in so_dia:
		var r := lerpf(ban_kinh_nho, ban_kinh_lon, float(k) / (so_dia - 1))
		var mi := dia_scene.instantiate() as MeshInstance3D
		(mi.mesh as TorusMesh).outer_radius = r
		(mi.material_override as StandardMaterial3D).albedo_color = MAU_DIA[k % MAU_DIA.size()]
		mi.scale = Vector3(1.0, day_dia / (r - LO_DIA), 1.0)
		add_child(mi)
		_dia.append(mi)
	for k in _dia.size():
		_dia[k].position = _dich_dia(k)
