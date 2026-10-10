extends MiniGame3D

## CROWN CAPTURE — một vương miện, 60 giây; ai đội lâu nhất thắng. Không ai chết.
## Chạm người đang đội là cướp miện (máy người chạm xin, master duyệt).
## Đòn tay không chỉ gây choáng/hất.

## Miện vừa đổi chủ thì chừng này giây sau mới cướp/nhặt được.
const NGHI_CUOP := 1.1
## Khoảng cách ngang giữa hai tâm người coi là chạm.
const CHAM := 1.1
## Xin cướp tối đa mỗi chừng này giây.
const NHIP_XIN := 0.25
const CAO_DOI := 2.2
const CAO_NAM := 0.8

var _mien: Node3D = null
var _vung: Area3D = null
var _vong: Node3D = null

## 0 = miện nằm đất. Chỉ đổi qua `_net_giu`.
var _ai_giu := 0
## Chỗ miện nằm khi không ai giữ (toạ độ trong sân).
var _cho_nam := Vector3.ZERO
## `gio()` sớm nhất được nhặt tiếp.
var _cho_toi := 0.0
var _xin_luc := -99.0
## player_id -> giây đã giữ; bảng của master là bảng chốt.
var _diem: Dictionary = {}

## Đọc từ mesh sàn.
var _ban_kinh := 11.5


func _ready() -> void:
	super()
	ten = "CROWN CAPTURE"
	luat = "WASD chạy · chạm người đội miện là cướp được miện · chuột trái đánh · chuột phải chưởng"
	giay_van = 60.0


func _dung_san() -> void:
	_mien = san.get_node_or_null("Mien") as Node3D
	if _mien == null:
		push_error("Crown: san thieu node Mien")
		return
	_vung = _mien.get_node("Vung") as Area3D
	_vong = _mien.get_node("VongNhat") as Node3D
	_ai_giu = 0
	_cho_nam = Vector3(0.0, CAO_NAM, 0.0)
	_cho_toi = 0.0
	_diem.clear()
	for id in _song:
		_diem[int(id)] = 0.0
	var bon := san.get_node_or_null("SanTron") as Node3D
	var m := bon.get_node_or_null("Mat") as MeshInstance3D if bon != null else null
	var cyl := m.mesh as CylinderMesh if m != null else null
	if cyl != null:
		_ban_kinh = cyl.top_radius


func dung_som() -> void:
	super()


func _luat_moi_nhip() -> void:
	if _mien == null:
		return
	var giu := _nguoi(_ai_giu) if _ai_giu != 0 else null
	if giu != null:
		_mien.global_position = giu.global_position + Vector3.UP * CAO_DOI
		# Cộng theo delta khung hình.
		_diem[_ai_giu] = float(_diem.get(_ai_giu, 0.0)) + get_process_delta_time()
	else:
		# Miện nằm đúng chỗ rơi.
		_mien.position = _cho_nam
	# Vòng tầm nhặt chỉ hiện khi miện nằm đất và hết thời gian nghỉ.
	_vong.visible = _ai_giu == 0 and gio() >= _cho_toi

	if not con_song(NetManager.local_id()):
		return
	giu_trong_san(_ban_kinh - 0.5)
	# Chỉ máy người sắp nhặt/cướp đi hỏi.
	var id := NetManager.local_id()
	if _ai_giu == id or gio() < _cho_toi or gio() - _xin_luc < NHIP_XIN:
		return
	var toi := _nguoi(id)
	if toi == null:
		return
	var duoc := false
	if _ai_giu == 0:
		# Tầm nhặt là `Area3D` dưới quả miện.
		duoc = _vung.overlaps_body(toi)
	else:
		var nguoi_doi := _nguoi(_ai_giu)
		if nguoi_doi != null:
			var d := nguoi_doi.global_position - toi.global_position
			duoc = Vector2(d.x, d.z).length() <= CHAM
	if duoc:
		_xin_luc = gio()
		Fusion.rpc(_xin_cuop, id)


## Ô điểm: giây đã đội miện, ♛ cho người đang đội.
func diem_cua(id: int) -> float:
	return float(_diem[id]) if _diem.has(id) else NAN


func chu_diem(id: int) -> String:
	if not _diem.has(id):
		return ""
	return "%s%.1f s" % ["♛ " if id == _ai_giu else "", float(_diem[id])]


## Không ai chết (bị kẹp trong sàn).
func _toi_thua() -> bool:
	return false


# ─── trọng tài: master duyệt rồi phát ───

@rpc("any_peer", "call_local")
func _xin_cuop(ai: int) -> void:
	# Nhặt hay cướp cùng một đường; gói tới trước thắng.
	if not NetManager.is_master() or ai == _ai_giu or gio() < _cho_toi or not con_song(ai):
		return
	Fusion.rpc(_net_giu, ai, Vector3.ZERO)


## Miện rơi tại chỗ người đội (khi họ rời ván).
@rpc("any_peer", "call_local")
func _xin_roi(ai: int) -> void:
	if not NetManager.is_master() or ai != _ai_giu:
		return
	var p := _nguoi(ai)
	var cho := Vector3(0.0, CAO_NAM, 0.0)
	if p != null:
		var l := p.global_position - san.global_position
		cho = Vector3(l.x, CAO_NAM, l.z)
	Fusion.rpc(_net_giu, 0, cho)


@rpc("any_peer", "call_local")
func _net_giu(ai: int, cho: Vector3) -> void:
	_ai_giu = ai
	_cho_toi = gio() + NGHI_CUOP
	if ai == 0:
		_cho_nam = cho


## Người giữ miện rời ván: miện rơi tại chỗ.
func _khi_ai_do_chet(id: int) -> void:
	if NetManager.is_master() and id == _ai_giu:
		_xin_roi(id)


# ─── xếp hạng theo giây giữ ───

func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _diem:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool:
		return float(_diem[a]) > float(_diem[b]))
	Fusion.rpc(_net_xep_hang, xep)
