extends MiniGame3D

## EXPLOSIVE EXCHANGE — chuyền bom đếm ngược. Ai đang ôm lúc nó nổ thì ra.
##
## Khuôn T1. Trò DUY NHẤT trong nhóm T1 cần trọng tài: hai người chạm nhau cùng lúc thì "ai đang
## ôm bom" là một câu hỏi mà mỗi máy tự trả lời sẽ ra hai đáp án khác nhau. Nên master giữ một
## biến `_ai_om` và phát ra — đúng mẫu mục 8 của GUIDE: **client xin, master duyệt, master phát**.
##
## Toàn bộ phần còn lại vẫn 0 gói tin: bom nằm ở đâu thì mọi máy tự treo nó lên đầu người đang
## ôm, đồng hồ đếm ngược là hàm của `gio()`.
##
## ## Nổ KHÔNG do master tuyên
##
## Tới giờ nổ, chính máy của người đang ôm gọi `xin_chet()` — đúng luật xuyên suốt dự án: nạn
## nhân tự khai tử. Master chỉ nghe tin ấy rồi chọn người ôm tiếp theo. Nhờ vậy lớp cha lo trọn
## phần xếp hạng, ở đây không có dòng nào về điểm.
##
## Bom **loại thẳng**, không trừ máu. Hai trò T1 kia dùng `ThanhMau` vì ở đó bị hất vào nham/axit
## là chuyện xảy ra liên tục; ở đây "ôm bom lúc nó nổ" là một sự kiện dứt khoát và người chơi đã
## có cả `GIAY_DAU` giây để tránh nó.
##
## ## Vì sao người ôm bom chạy NHANH HƠN
##
## Mọi người cùng `Player.speed = 6.0`. `kiem_luat.gd` mô phỏng đuổi bắt 1v1 trên sàn tròn và đo
## được: không boost thì bắt từ đầu này sàn sang đầu kia mất **4,88 giây**, trong khi bom ngắn
## nhất chỉ 7 giây và còn mất 0,9 giây nghỉ chuyền — còn **1,22 giây** để làm mọi thứ. Lỡ một
## nhịp quay đầu là chết, và người ôm bom gần như không có việc gì để chơi ngoài cầu may.
##
## `TOC_OM_THEM = 1,6` hạ xuống 2,83 giây, còn lại 3,27 giây. Đủ để khép dần khoảng cách nếu đuổi
## đúng hướng, không đủ để bắt ngay — kẻ chạy trốn vẫn có đất diễn.
##
## Phải TRẢ LẠI khi hết ôm và trong `dung_som()`, không thì người chơi mang tốc độ đó về phòng
## chờ — đúng cái bẫy `Player.truot` của Slippery Sprint đã dính một lần.
##
## ## Vì sao chuyền bằng NÚT chứ không tự chuyền khi chạm
##
## Bản trước tự chuyền cho người gần nhất ngay khi hết `NGHI_CHUYEN`. Nó tiện nhưng biến cú
## chuyền thành chuyện xảy ra với người chơi chứ không phải việc họ làm: chạy ngang qua ai đó là
## mất bom, kể cả khi đang muốn giữ để dồn người khác vào góc. Giờ phải bấm `interact`.
##
## ## Vì sao có `NGHI_CHUYEN`
##
## Không có nó thì hai người đứng cạnh nhau chuyền qua chuyền lại mỗi khung hình: bom nhấp nháy
## giữa hai cái đầu và mạng đầy gói `xin_chuyen`. 0,9 giây đủ để người vừa nhận phải chạy đi.

## Nút chuyền. `interact` (E) — trong sân không có vật nào để nhặt nên phím này rảnh.
const NUT_CHUYEN := "interact"
## Bom nổ sau chừng này giây kể từ lúc được trao — lần đầu, và về sau.
const GIAY_DAU := 16.0
const GIAY_CUOI := 7.0
## Ngắn hết cỡ sau chừng này lần nổ.
const SO_LAN_NGAN := 4
## Vừa nhận bom thì chừng này giây sau mới chuyền được.
const NGHI_CHUYEN := 0.9
## Bom treo trên đầu người ôm.
const CAO_TREO := 2.3
## Người ôm bom chạy nhanh hơn chừng này m/s. `Player.speed` mặc định 6,0.
const TOC_OM_THEM := 1.6
## Còn dưới chừng này giây thì bom vào trạng thái GẤP: phồng, sáng rực, chữ đỏ.
const GIAY_GAP := 4.0


var _bom: Node3D = null
var _vung: Area3D = null
var _dem: Label3D = null
var _sang: OmniLight3D = null
var _mat: Node3D = null
var _vong: Node3D = null

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
## Tốc độ gốc của nhân vật máy này, để còn trả lại.
var _toc_goc := -1.0
## Bán kính sàn, ĐỌC từ mesh chứ không chép tay.
var _ban_kinh := 11.5


func _ready() -> void:
	super()
	ten = "EXPLOSIVE EXCHANGE"
	luat = "WASD chạy · E chuyền bom cho người trong vòng đỏ · đừng ôm lúc nó nổ"
	giay_van = 0.0                      # bom rút ngắn dần, ván tự kết thúc


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
	_da_thap = false
	_ai_om = 0
	_toc_goc = -1.0
	var bon := san.get_node_or_null("SanTron") as Node3D
	var m := bon.get_node_or_null("Mat") as MeshInstance3D if bon != null else null
	var cyl := m.mesh as CylinderMesh if m != null else null
	if cyl != null:
		_ban_kinh = cyl.top_radius


## Trả tốc độ gốc trước khi ra khỏi sân. Thiếu dòng này thì ai đang ôm bom lúc ván dừng sẽ mang
## tốc độ đó về phòng chờ.
func dung_som() -> void:
	_dat_toc(false)
	super()


func _luat_moi_nhip() -> void:
	if _bom == null:
		return
	# Bốc người ôm đầu tiên ở đây chứ KHÔNG ở `_dung_san()`: lúc đó lớp cha chưa đặt lại mốc thời
	# gian, `gio()` còn là giờ của ván trước và bom sẽ nổ ngay khi vừa thắp.
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

	if not toi:
		return
	_giu_tren_san()
	# Chỉ máy của người đang ôm mới tự khai tử — không thì cả phòng cùng gửi một tin.
	if gio() >= _no_luc:
		xin_chet()


## Bom gấp dần: phồng lên, sáng rực, chữ đổi sang đỏ. Vòng tầm chuyền mờ đi khi chưa chuyền được.
##
## Không có đoạn này thì cả ván bom chỉ là một con số đang tụt, và "sắp nổ" với "mới nhận" nhìn
## y như nhau — mục 1/2/12 của thiết kế đòi người chơi nhận ra độ gấp mà không phải đọc số.
func _ve_bom(con_lai: float) -> void:
	_dem.text = "%.1f" % con_lai
	var gap := 1.0 - clampf(con_lai / GIAY_GAP, 0.0, 1.0)
	# Nhịp phồng nhanh dần: 2 nhịp/giây lúc thường, 9 nhịp/giây lúc sắp nổ.
	var nhip := sin(gio() * TAU * lerpf(2.0, 9.0, gap))
	_mat.scale = Vector3.ONE * (1.0 + gap * 0.35 + nhip * 0.06 * (0.3 + gap))
	_sang.light_energy = lerpf(3.0, 9.0, gap)
	_dem.modulate = Color(1.0, 0.85, 0.5).lerp(Color(1.0, 0.25, 0.15), gap)
	# Vòng chỉ sáng khi ĐANG chuyền được — nó là thứ trả lời "bấm E lúc này có ăn không".
	_vong.visible = gio() >= _cho_toi


## Kẹp nhân vật CỦA MÁY NÀY trong lòng sàn. Chỉ `is_mine` — kéo người khác là đánh nhau với
## replicator đang gửi vị trí của họ.
##
## Người ôm bom không được chạy ra khỏi sân để khỏi phải chuyền cho ai: sàn tròn mà ngoài là hư
## không thì "nhảy ra ngoài" là một đường thoát khỏi luật chơi.
func _giu_tren_san() -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	var l := p.global_position - san.global_position
	var r := Vector2(l.x, l.z)
	var toi_da := _ban_kinh - 0.5
	if r.length() <= toi_da:
		return
	r = r.normalized() * toi_da
	p.global_position = san.global_position + Vector3(r.x, l.y, r.y)


## Bật/tắt tốc độ của người ôm bom, chỉ trên nhân vật của máy này.
func _dat_toc(dang_om: bool) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	if _toc_goc < 0.0:
		_toc_goc = p.speed
	p.speed = _toc_goc + TOC_OM_THEM if dang_om else _toc_goc


## Bấm E để chuyền. Cố ý bắt bấm: xem ghi chú "vì sao chuyền bằng nút" đầu file.
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


## Người gần bom nhất mà không phải người đang ôm. 0 nếu không có ai.
##
## Hỏi thẳng `Area3D` của quả bom: tầm chuyền CHÍNH LÀ cái vòng đỏ `VongTam` dưới chân người ôm —
## cả hai lấy bán kính 1,8 trong `bom_chuyen.tscn`, không phải một con số chép tay trong code.
##
## Bản trước để `Vung` ngay tại quả bom (trên đầu, cao 2,3 m) nên tầm thật là một hình cầu lơ
## lửng, không ứng với thứ gì nhìn thấy được: comment bảo nó bằng "quầng sáng" nhưng quầng sáng
## là `OmniLight` tầm 6,0 còn quả bom chỉ bán kính 0,55.
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
##
## Không cần tránh "trao lại cho người vừa ôm": hàm này chỉ chạy khi người ôm cũ đã CHẾT (xem
## `_khi_ai_do_chet`), nên `con_song` đã loại họ ra. Lặp lại người ôm là chuyện không xảy ra được.
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
