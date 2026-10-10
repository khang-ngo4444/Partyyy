extends MiniGame3D

## EXPLOSIVE EXCHANGE — chuyền bom đếm ngược; ai đang ôm lúc nổ thì ra.
## Master giữ `_ai_om` (client xin chuyền, master duyệt rồi phát). Nổ thì máy người ôm tự khai tử.
## Người ôm bom chạy nhanh hơn `TOC_OM_THEM` (trả lại khi hết ôm). Chuyền bằng nút E.

## E (trong sân không có gì để nhặt).
const NUT_CHUYEN := "interact"
## Thời gian bom đếm lần đầu.
const GIAY_DAU := 16.0
const GIAY_CUOI := 7.0
## Ngắn hết cỡ sau chừng này lần nổ.
const SO_LAN_NGAN := 4
## Vừa nhận bom thì chừng này giây sau mới chuyền được.
const NGHI_CHUYEN := 0.9
const CAO_TREO := 2.3
## Người ôm bom chạy nhanh thêm (m/s).
const TOC_OM_THEM := 1.6
## Dưới chừng này giây thì bom vào trạng thái gấp.
const GIAY_GAP := 4.0


var _bom: Node3D = null
var _vung: Area3D = null
var _dem: Label3D = null
var _sang: OmniLight3D = null
var _mat: Node3D = null
var _vong: Node3D = null

## 0 = chưa ai. Chỉ đổi qua `_net_trao`.
var _ai_om := 0
## `gio()` lúc bom nổ.
var _no_luc := 0.0
## `gio()` sớm nhất được chuyền tiếp.
var _cho_toi := 0.0
var _lan_no := 0
## Master đã bốc người ôm đầu tiên chưa.
var _da_thap := false
## Tốc gốc của nhân vật máy này, để trả lại.
var _toc_goc := -1.0
## Đọc từ mesh sàn.
var _ban_kinh := 11.5


func _ready() -> void:
	super()
	ten = "EXPLOSIVE EXCHANGE"
	luat = "WASD chạy · E chuyền bom cho người trong vòng đỏ · đừng ôm lúc nó nổ"
	giay_van = 0.0  # bom rút ngắn dần, ván tự kết thúc


func _dung_san() -> void:
	_bom = san.get_node_or_null("Bom") as Node3D
	if _bom == null:
		push_error("Explosive: san thieu node Bom")
		return
	_vung = _bom.get_node("Vung") as Area3D
	_dem = _bom.get_node("Dem") as Label3D
	_sang = _bom.get_node("Sang") as OmniLight3D
	_mat = _bom.get_node("Mat") as Node3D
	_vong = _bom.get_node("VongTam") as Node3D
	_bom.visible = false
	# Không đặt lại `_ai_om`/`_no_luc`: gói `_net_trao` của master có thể tới trước lúc này.
	_toc_goc = -1.0
	var bon := san.get_node_or_null("SanTron") as Node3D
	var m := bon.get_node_or_null("Mat") as MeshInstance3D if bon != null else null
	var cyl := m.mesh as CylinderMesh if m != null else null
	if cyl != null:
		_ban_kinh = cyl.top_radius


## Trả tốc gốc trước khi ra khỏi sân.
func dung_som() -> void:
	_dat_toc(false)
	super()


func _luat_moi_nhip() -> void:
	if _bom == null:
		return
	# Bốc người ôm đầu tiên ở đây (lúc `gio()` đã đặt lại).
	if NetManager.is_master() and not _da_thap:
		_da_thap = true
		_trao_cho_ai_do()
	var om := _nguoi(_ai_om) if _ai_om != 0 else null
	_bom.visible = om != null
	var toi := _ai_om == NetManager.local_id()
	_dat_toc(toi and om != null)
	if om == null:
		return
	_bom.global_position = om.global_position + Vector3.UP * CAO_TREO
	var con_lai := maxf(_no_luc - gio(), 0.0)
	_ve_bom(con_lai)

	# Người ôm quá giờ nổ mà máy họ không khai thì master khai hộ.
	if NetManager.is_master() and not toi and gio() >= _no_luc + 1.5 and con_song(_ai_om):
		Fusion.rpc(_net_chet, _ai_om, _no_luc)
	if not toi:
		return
	giu_trong_san(_ban_kinh - 0.5)
	# Chỉ máy người đang ôm tự khai tử.
	if gio() >= _no_luc:
		xin_chet()


## Bom gấp dần: phồng, sáng, chữ đỏ; vòng tầm chuyền chỉ sáng khi chuyền được.
func _ve_bom(con_lai: float) -> void:
	_dem.text = "%.1f" % con_lai
	var gap := 1.0 - clampf(con_lai / GIAY_GAP, 0.0, 1.0)
	# Phồng nhanh dần.
	var nhip := sin(gio() * TAU * lerpf(2.0, 9.0, gap))
	_mat.scale = Vector3.ONE * (1.0 + gap * 0.35 + nhip * 0.06 * (0.3 + gap))
	_sang.light_energy = lerpf(3.0, 9.0, gap)
	_dem.modulate = Color(1.0, 0.85, 0.5).lerp(Color(1.0, 0.25, 0.15), gap)
	_vong.visible = gio() >= _cho_toi


func _dat_toc(dang_om: bool) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	if _toc_goc < 0.0:
		_toc_goc = p.speed
	p.speed = _toc_goc + TOC_OM_THEM if dang_om else _toc_goc


## E để chuyền.
func _unhandled_input(event: InputEvent) -> void:
	if not _chay or not event.is_action_pressed(NUT_CHUYEN):
		return
	if _ai_om != NetManager.local_id() or gio() < _cho_toi:
		return
	var nan_nhan := _ai_gan_bom()
	if nan_nhan == 0:
		return
	get_viewport().set_input_as_handled()
	Fusion.rpc(_xin_chuyen, NetManager.local_id(), nan_nhan)


## Người gần nhất trong vòng `VongTam` (không phải người đang ôm); 0 = không ai.
func _ai_gan_bom() -> int:
	var gan := 0
	var cach := INF
	for b in _vung.get_overlapping_bodies():
		var p := b as Player
		if p == null or p.player_id() == _ai_om or not con_song(p.player_id()):
			continue
		var d := p.global_position.distance_squared_to(_bom.global_position)
		if d < cach:
			cach = d
			gan = p.player_id()
	return gan


# ─── trọng tài: master duyệt rồi phát ───

@rpc("any_peer", "call_local")
func _xin_chuyen(tu: int, den: int) -> void:
	if not NetManager.is_master():
		return
	# Chỉ người đang ôm chuyền được, cho người còn sống; gói tới trước thắng.
	if tu != _ai_om or not con_song(den) or gio() < _cho_toi:
		return
	Fusion.rpc(_net_trao, den, _no_luc, gio() + NGHI_CHUYEN)


## Master chọn người ôm mới và đặt đồng hồ.
func _trao_cho_ai_do() -> void:
	var song: Array = []
	for id in _song:
		if con_song(int(id)):
			song.append(int(id))
	if song.is_empty():
		return
	song.sort()  # cùng hạt giống thì cùng kết quả
	var ai := int(song[_rng.randi() % song.size()])
	Fusion.rpc(_net_trao, ai, gio() + giay_dem(_lan_no), gio() + NGHI_CHUYEN)


## Mọi mốc giờ do master tính rồi gửi kèm.
@rpc("any_peer", "call_local")
func _net_trao(ai: int, no_luc: float, cho_toi: float) -> void:
	_ai_om = ai
	_no_luc = no_luc
	_cho_toi = cho_toi


## Người ôm vừa nổ: master thắp quả tiếp theo.
func _khi_ai_do_chet(id: int) -> void:
	if not NetManager.is_master() or id != _ai_om:
		return
	_lan_no += 1
	_trao_cho_ai_do()


# ─── luật: hàm thuần ───

## Ngắn dần rồi dừng ở `GIAY_CUOI`.
static func giay_dem(lan: int) -> float:
	return lerpf(GIAY_DAU, GIAY_CUOI, clampf(float(lan) / float(SO_LAN_NGAN), 0.0, 1.0))
