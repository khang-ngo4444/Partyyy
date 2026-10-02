extends MiniGame3D

## CROWN CAPTURE — một vương miện, 60 giây. Giữ được giây nào ăn giây đó.
##
## Khuôn T1, và là trò DUY NHẤT không xếp hạng theo thời gian sống. Ở đây **không ai chết**: vị
## trí bị kẹp trong lòng sàn nên hết giờ là mọi người vẫn còn đủ, và thứ duy nhất quyết định thắng
## thua là tổng giây đội miện.
##
## ## Vì sao phải ghi đè `_chot_ket_qua()`
##
## Lớp cha xếp "ai sống lâu hơn thì trên", đúng cho các trò kia. Trò này xếp theo **giây giữ
## miện**, một con số không liên quan gì tới cái chết. Ghi đè đúng một hàm là xong — phần trao
## miện, dọn sân, đường về vẫn là của lớp cha.
##
## ## Ai cộng điểm
##
## Master, và chỉ master. Mọi máy đều tự cộng một bảng giống hệt để hiện lên màn hình, nhưng bảng
## quyết định là của master — lệch đồng hồ giữa các máy khiến hai bảng chênh nhau vài phần trăm
## giây, và một trận hoà sát nút không được phép tuỳ vào máy nào đang hỏi.
##
## Chuyện này KHÔNG tốn thêm gói tin nào: bảng chỉ được gửi một lần duy nhất, lúc chốt kết quả.
##
## ## Cướp miện: CHẠM vào người đang đội là miện sang tay mình
##
## Đuổi bắt thuần tuý: người đội miện chạy, cả phòng đuổi; chạm được vào thân người đội là miện
## nhảy sang đầu mình, rồi tới lượt mình bị đuổi. Máy của NGƯỜI CHẠM tự xin (mỗi máy chỉ nói về
## nhân vật của mình), master duyệt — hai người cùng chạm thì gói nào tới trước thắng.
##
## Hai đòn tay không của `MiniGame3D` (bật `co_danh` trong `crown.tscn`) vẫn còn nhưng KHÔNG làm
## rơi miện: chuột trái đánh làm choáng (giữ chân người đội để kịp chạm, hay giữ chân kẻ đuổi để
## chạy), chuột phải chưởng hất văng (đẩy kẻ đuổi ra xa).
##
## ## Vì sao có `NGHI_CUOP`
##
## Không có nó thì người vừa mất miện chạm ngược lại ngay — miện nhảy qua nhảy lại giữa hai người
## đứng sát nhau mỗi khung hình. 1,1 giây là đủ để người vừa cướp chạy ra khỏi tầm.

## Miện vừa đổi chủ (hay vừa rơi) thì chừng này giây sau mới cướp/nhặt được.
const NGHI_CUOP := 1.1
## Hai tâm người cách nhau ngang chừng này mét là CHẠM: thân rộng 0,8 m, cộng chút dư cho trễ mạng.
const CHAM := 1.1
## Máy người chạm xin cướp tối đa mỗi chừng này giây — không thì đứng sát là gửi 60 gói/giây.
const NHIP_XIN := 0.25
## Miện đội trên đầu người giữ.
const CAO_DOI := 2.2
## Miện nằm dưới đất ở độ cao này khi chưa ai nhặt.
const CAO_NAM := 0.8

var _mien: Node3D = null
var _vung: Area3D = null
var _vong: Node3D = null

## Ai đang giữ. 0 = miện đang nằm đất. Chỉ đổi qua `_net_giu`.
var _ai_giu := 0
## Miện đang nằm ở đâu khi không ai giữ (toạ độ cục bộ trong `san`).
var _cho_nam := Vector3.ZERO
## Giờ ván sớm nhất được phép nhặt tiếp.
var _cho_toi := 0.0
var _xin_luc := -99.0
## player_id -> giây đã giữ. Mọi máy tự cộng; bảng của master là bảng quyết định.
var _diem: Dictionary = {}

## Bán kính sàn, ĐỌC từ mesh chứ không chép tay.
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
		# Cộng theo `_delta` của khung hình chứ không phải hiệu hai lần đọc đồng hồ: khung hình
		# đầu tiên sau khi đổi chủ sẽ cộng nhầm cả quãng vừa rồi cho người mới.
		_diem[_ai_giu] = float(_diem.get(_ai_giu, 0.0)) + get_process_delta_time()
	else:
		# Nằm ĐÚNG chỗ rơi, không về giữa sân: chỗ rơi là thông tin, và kéo nó về tâm là xoá đi
		# khoảnh khắc giành nhau mà cú đòn vừa tạo ra.
		_mien.position = _cho_nam
	# Vòng tầm nhặt chỉ hiện khi miện nằm đất VÀ đã hết nghỉ — nó trả lời đúng câu "chạy vào đây
	# lúc này có nhặt được không". Đội trên đầu thì vòng vô nghĩa.
	_vong.visible = _ai_giu == 0 and gio() >= _cho_toi

	if not con_song(NetManager.local_id()):
		return
	giu_trong_san(_ban_kinh - 0.5)
	# Chỉ máy của NGƯỜI SẮP NHẶT/CƯỚP đi hỏi — mỗi máy chỉ tự nói về nhân vật của mình.
	var id := NetManager.local_id()
	if _ai_giu == id or gio() < _cho_toi or gio() - _xin_luc < NHIP_XIN:
		return
	var toi := _nguoi(id)
	if toi == null:
		return
	var duoc := false
	if _ai_giu == 0:
		# Miện nằm đất: hỏi thẳng `Area3D` — tầm nhặt CHÍNH LÀ cái vòng `VongNhat` dưới quả miện,
		# cả hai lấy bán kính 1,5 trong `vuong_mien.tscn`.
		duoc = _vung.overlaps_body(toi)
	else:
		var nguoi_doi := _nguoi(_ai_giu)
		if nguoi_doi != null:
			var d := nguoi_doi.global_position - toi.global_position
			duoc = Vector2(d.x, d.z).length() <= CHAM
	if duoc:
		_xin_luc = gio()
		Fusion.rpc(_xin_cuop, id)


## Ô điểm chung ở đáy màn hình (`QuanTroMiniGame`): giây đã đội miện, và ♛ cho người đang đội.
##
## Thay cho số chạy trên đầu quả miện + bảng góc phải của bản trước: số trên đầu chỉ cho biết điểm
## của MỘT người, nên không ai biết mình đang thứ mấy.
func diem_cua(id: int) -> float:
	return float(_diem[id]) if _diem.has(id) else NAN


func chu_diem(id: int) -> String:
	if not _diem.has(id):
		return ""
	return "%s%.1f s" % ["♛ " if id == _ai_giu else "", float(_diem[id])]


## Trò này cố ý KHÔNG cho ai chết: thắng thua chỉ do tổng giây đội miện. Vị trí bị kẹp trong
## lòng sàn (`giu_trong_san`), nên cú đánh chỉ đẩy người ta rời quả miện chứ không hất xuống vực.
func _toi_thua() -> bool:
	return false


# ───────────────────────── trọng tài: master duyệt rồi phát ─────────────────────────

@rpc("any_peer", "call_local")
func _xin_cuop(ai: int) -> void:
	# Nhặt miện nằm đất HAY chạm cướp từ người đang đội — cùng một đường. Hai người cùng chạm thì
	# gói nào tới master trước thắng, gói sau bị `_cho_toi` chặn. Không có trọng tài thì mỗi máy tự
	# cho mình là người cướp được.
	if not NetManager.is_master() or ai == _ai_giu or gio() < _cho_toi or not con_song(ai):
		return
	Fusion.rpc(_net_giu, ai, Vector3.ZERO)


## Miện rơi xuống đúng chỗ người đội đứng. Giờ chỉ còn dùng khi người đội rời ván (xem dưới).
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


## Người giữ miện vừa rời ván (lưới đỡ — vị trí đã bị kẹp nên chuyện này không nên xảy ra): miện
## rơi tại chỗ cho người khác tới nhặt.
func _khi_ai_do_chet(id: int) -> void:
	if NetManager.is_master() and id == _ai_giu:
		_xin_roi(id)


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
