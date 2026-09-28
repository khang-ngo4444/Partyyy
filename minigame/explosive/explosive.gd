extends MiniGame3D

## EXPLOSIVE EXCHANGE — chuyền bom đếm ngược. Ai đang ôm lúc nó nổ thì ra.
##
## Khuôn T1 thứ tư. Trò DUY NHẤT trong nhóm T1 cần trọng tài: hai người chạm nhau cùng lúc thì
## "ai đang ôm bom" là một câu hỏi mà mỗi máy tự trả lời sẽ ra hai đáp án khác nhau. Nên master
## giữ một biến `_ai_om` và phát ra — đúng mẫu mục 8 của GUIDE: **client xin, master duyệt,
## master phát**.
##
## Toàn bộ phần còn lại vẫn 0 gói tin: bom nằm ở đâu thì mọi máy tự treo nó lên đầu người đang
## ôm, đồng hồ đếm ngược là hàm của `gio()`.
##
## ## Nổ KHÔNG do master tuyên
##
## Tới giờ nổ, chính máy của người đang ôm gọi `xin_chet()` — đúng luật xuyên suốt dự án:
## nạn nhân tự khai tử. Master chỉ nghe tin ấy rồi chọn người ôm tiếp theo. Nhờ vậy lớp cha lo
## trọn phần xếp hạng, ở đây không có dòng nào về điểm.
##
## ## Vì sao có `NGHI_CHUYEN`
##
## Không có nó thì hai người đứng cạnh nhau chuyền qua chuyền lại mỗi khung hình: bom nhấp nháy
## giữa hai cái đầu và mạng đầy gói `xin_chuyen`. 0,9 giây đủ để người vừa nhận phải chạy đi.

## Bom nổ sau chừng này giây kể từ lúc được trao — lần đầu, và về sau.
const GIAY_DAU := 16.0
const GIAY_CUOI := 7.0
## Ngắn hết cỡ sau chừng này lần nổ.
const SO_LAN_NGAN := 4
## Vừa nhận bom thì chừng này giây sau mới chuyền được.
const NGHI_CHUYEN := 0.9
## Bom treo trên đầu người ôm.
const CAO_TREO := 2.3

var _bom: Node3D = null
var _vung: Area3D = null
var _dem: Label3D = null

## Ai đang ôm. 0 = chưa ai. Chỉ đổi qua `_net_trao`, kể cả trên máy master.
var _ai_om := 0
## Giờ ván (theo `gio()`) mà bom sẽ nổ.
var _no_luc := 0.0
## Giờ ván sớm nhất được phép chuyền tiếp.
var _cho_toi := 0.0
## Đã nổ bao nhiêu lần — để rút ngắn dần đồng hồ.
var _lan_no := 0
## Master đã bốc người ôm đầu tiên chưa. Gói `_net_trao` mất một chuyến đi mới về, không có cờ
## này thì master bốc lại mỗi khung hình cho tới khi gói đầu tiên quay về.
var _da_thap := false


func _ready() -> void:
	super()
	ten = "EXPLOSIVE EXCHANGE"
	luat = "WASD chạy · chạm người khác để chuyền bom · đừng ôm lúc nó nổ"
	giay_van = 0.0                      # bom rút ngắn dần, ván tự kết thúc


func _dung_san() -> void:
	_bom = san.get_node_or_null("Bom") as Node3D
	if _bom == null:
		push_error("Explosive: san thieu node Bom")
		return
	_vung = _bom.get_node("Vung") as Area3D
	_dem = _bom.get_node("Dem") as Label3D
	_bom.visible = false
	_da_thap = false


func _luat_moi_nhip() -> void:
	if _bom == null:
		return
	# Bốc người ôm đầu tiên ở đây chứ KHÔNG ở `_dung_san()`: lúc đó lớp cha chưa đặt lại mốc
	# thời gian, `gio()` còn là giờ của ván trước và bom sẽ nổ ngay khi vừa thắp.
	if NetManager.is_master() and not _da_thap:
		_da_thap = true
		_trao_cho_ai_do()
	var om := _nguoi(_ai_om) if _ai_om != 0 else null
	_bom.visible = om != null
	if om == null:
		return
	_bom.global_position = om.global_position + Vector3.UP * CAO_TREO
	_dem.text = "%.1f" % maxf(_no_luc - gio(), 0.0)

	if _ai_om != NetManager.local_id():
		return
	# Chỉ máy của người đang ôm mới đi hỏi — không thì cả phòng cùng gửi một câu hỏi.
	if gio() >= _no_luc:
		xin_chet()
	elif gio() >= _cho_toi:
		var nan_nhan := _ai_gan_bom()
		if nan_nhan != 0:
			Fusion.rpc(_xin_chuyen, NetManager.local_id(), nan_nhan)


## Người gần bom nhất mà không phải người đang ôm. 0 nếu không có ai.
##
## Hỏi thẳng `Area3D` của quả bom: tầm chuyền CHÍNH LÀ quầng sáng nhìn thấy, không phải một con
## số chép tay trong code.
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


# ───────────────────────── trọng tài: master duyệt rồi phát ─────────────────────────

@rpc("any_peer", "call_local")
func _xin_chuyen(tu: int, den: int) -> void:
	if not NetManager.is_master():
		return
	# Chỉ người ĐANG ôm mới chuyền được, và chỉ chuyền cho người còn sống. Hai người chạm nhau
	# cùng lúc thì gói nào tới trước thắng — và chỉ một gói được duyệt, vì gói sau đã sai `tu`.
	if tu != _ai_om or not con_song(den) or gio() < _cho_toi:
		return
	Fusion.rpc(_net_trao, den, _no_luc)


## Master chọn người ôm bom mới và đặt đồng hồ mới.
func _trao_cho_ai_do() -> void:
	var song: Array = []
	for id in _song:
		if con_song(int(id)):
			song.append(int(id))
	if song.is_empty():
		return
	song.sort()                         # sắp trước khi bốc: cùng hạt giống thì cùng kết quả
	var ai := int(song[_rng.randi() % song.size()])
	Fusion.rpc(_net_trao, ai, gio() + giay_dem(_lan_no))


@rpc("any_peer", "call_local")
func _net_trao(ai: int, no_luc: float) -> void:
	_ai_om = ai
	_no_luc = no_luc
	_cho_toi = gio() + NGHI_CHUYEN


## Người ôm bom vừa nổ: master thắp quả tiếp theo. Lớp cha đã ghi nhận cái chết rồi.
func _khi_ai_do_chet(id: int) -> void:
	if not NetManager.is_master() or id != _ai_om:
		return
	_lan_no += 1
	_trao_cho_ai_do()


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Bom lần thứ `lan` đếm được bao nhiêu giây. Ngắn dần rồi dừng ở `GIAY_CUOI`.
static func giay_dem(lan: int) -> float:
	return lerpf(GIAY_DAU, GIAY_CUOI, clampf(float(lan) / float(SO_LAN_NGAN), 0.0, 1.0))
