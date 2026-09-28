extends MiniGame3D

## CROWN CAPTURE — một vương miện, 60 giây. Giữ được giây nào ăn giây đó.
##
## Khuôn T1 thứ năm, và là trò ĐẦU TIÊN không xếp hạng theo thời gian sống. Ở đây không ai
## chết vì đối thủ — chết chỉ xảy ra nếu tự chạy văng khỏi sàn, và người chết thì thôi ăn điểm.
##
## ## Vì sao phải ghi đè `_chot_ket_qua()`
##
## Lớp cha xếp "ai sống lâu hơn thì trên", đúng cho chín trò kia. Trò này xếp theo **giây giữ
## miện**, một con số không liên quan gì tới cái chết. Ghi đè đúng một hàm là xong — phần trao
## miện, cướp miện, dọn sân, đường về vẫn là của lớp cha.
##
## ## Ai cộng điểm
##
## Master, và chỉ master. Mọi máy đều tự cộng một bảng giống hệt để hiện lên màn hình, nhưng
## bảng quyết định là của master — lệch đồng hồ giữa các máy khiến hai bảng chênh nhau vài phần
## trăm giây, và một trận hoà sát nút không được phép tuỳ vào máy nào đang hỏi.
##
## Chuyện này KHÔNG tốn thêm gói tin nào: bảng chỉ được gửi một lần duy nhất, lúc chốt kết quả.
##
## ## Vì sao có `NGHI_CUOP`
##
## Không có nó thì hai người đứng cạnh nhau cướp qua cướp lại mỗi khung hình — miện nhấp nháy
## giữa hai cái đầu, mà điểm thì vẫn chia đều. 1,1 giây buộc người vừa cướp phải chạy.

## Cướp xong chừng này giây sau mới cướp tiếp được.
const NGHI_CUOP := 1.1
## Miện đội trên đầu người giữ.
const CAO_DOI := 2.2
## Miện nằm dưới đất ở độ cao này khi chưa ai nhặt.
const CAO_NAM := 0.8

var _mien: Node3D = null
var _vung: Area3D = null
var _diem_3d: Label3D = null

## Ai đang giữ. 0 = miện đang nằm đất. Chỉ đổi qua `_net_giu`.
var _ai_giu := 0
## Giờ ván sớm nhất được phép cướp tiếp.
var _cho_toi := 0.0
## player_id -> giây đã giữ. Mọi máy tự cộng; bảng của master là bảng quyết định.
var _diem: Dictionary = {}


func _ready() -> void:
	super()
	ten = "CROWN CAPTURE"
	luat = "WASD chạy · chạm vương miện để cướp · giữ được giây nào ăn giây đó"
	giay_van = 60.0


func _dung_san() -> void:
	_mien = san.get_node_or_null("Mien") as Node3D
	if _mien == null:
		push_error("Crown: san thieu node Mien")
		return
	_vung = _mien.get_node("Vung") as Area3D
	_diem_3d = _mien.get_node("Diem") as Label3D
	_ai_giu = 0
	_cho_toi = 0.0
	_diem.clear()
	for id in _song:
		_diem[int(id)] = 0.0


func _luat_moi_nhip() -> void:
	if _mien == null:
		return
	var giu := _nguoi(_ai_giu) if _ai_giu != 0 else null
	if giu != null:
		_mien.global_position = giu.global_position + Vector3.UP * CAO_DOI
		# Cộng theo `_delta` của khung hình chứ không phải hiệu hai lần đọc đồng hồ: khung hình
		# đầu tiên sau khi đổi chủ sẽ cộng nhầm cả quãng vừa rồi cho người mới.
		_diem[_ai_giu] = float(_diem.get(_ai_giu, 0.0)) + get_process_delta_time()
		_diem_3d.text = "%.0f" % float(_diem[_ai_giu])
	else:
		_mien.position = Vector3(0.0, CAO_NAM, 0.0)
		_diem_3d.text = "?"

	# Chỉ máy của NGƯỜI SẮP CƯỚP đi hỏi — mỗi máy chỉ tự nói về nhân vật của mình.
	if _ai_giu == NetManager.local_id() or gio() < _cho_toi:
		return
	var toi := _nguoi(NetManager.local_id())
	if toi == null or not con_song(NetManager.local_id()):
		return
	# Hỏi thẳng `Area3D`: tầm cướp CHÍNH LÀ quầng sáng nhìn thấy quanh miện.
	if _vung.overlaps_body(toi):
		Fusion.rpc(_xin_cuop, NetManager.local_id())


# ───────────────────────── trọng tài: master duyệt rồi phát ─────────────────────────

@rpc("any_peer", "call_local")
func _xin_cuop(ai: int) -> void:
	# Hai người chạm miện cùng lúc thì gói nào tới master trước thắng, gói sau bị `_cho_toi`
	# chặn. Không có trọng tài thì mỗi máy tự cho mình là người cướp được.
	if not NetManager.is_master() or ai == _ai_giu or gio() < _cho_toi or not con_song(ai):
		return
	Fusion.rpc(_net_giu, ai)


@rpc("any_peer", "call_local")
func _net_giu(ai: int) -> void:
	_ai_giu = ai
	_cho_toi = gio() + NGHI_CUOP


## Người giữ miện vừa văng khỏi sàn: miện rơi về giữa sân cho người khác tới nhặt.
func _khi_ai_do_chet(id: int) -> void:
	if NetManager.is_master() and id == _ai_giu:
		Fusion.rpc(_net_giu, 0)


# ───────────────────────── xếp hạng theo giây giữ, không theo mạng ─────────────────────────

func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _diem:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool:
		return float(_diem[a]) > float(_diem[b]))
	Fusion.rpc(_net_xep_hang, xep)
