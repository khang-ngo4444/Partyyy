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
## ## Vì sao cướp miện phải qua ĐÒN, không phải chạm vào người giữ
##
## Bản trước để `Area3D` cướp ngay trên quả miện, mà miện thì đội trên đầu người giữ — nên chỉ
## cần **chạy tới chạm vào người giữ** là miện sang tay mình. Hai hệ quả, cả hai đều sai với trò:
##
##   1. **Không có đòn nào trong một trò PvP.** Người không giữ miện chẳng có việc gì làm ngoài
##      chạy tới đụng. Không có chuyện chặn đường, không có chuyện tranh nhau.
##   2. **Miện sang tay TỨC THÌ.** Không có khoảnh khắc miện nằm đất để mà giành. Người đến trước
##      ăn tất, và cả ván là một chuỗi đụng-đổi-chủ.
##
## Giờ: bắn cầu lửa trúng người đang giữ thì **miện RƠI xuống đúng chỗ họ đứng**, không bay sang
## ai. Ai chạy tới trước thì nhặt. Cầu lửa bắn vào người không giữ miện thì chỉ hất — vẫn có ích,
## vì đó là cách hẩy đối thủ ra khỏi quả miện đang nằm đất.
##
## Cầu lửa dùng lại nguyên `CauLua` + `cau_lua.tscn` của Magma & Mages, không viết hệ đòn mới.
##
## ## Vì sao có `NGHI_CUOP`
##
## Không có nó thì người vừa bị hất quay lại nhặt luôn quả miện vừa rơi, và cú đòn thành vô nghĩa.
## 1,1 giây đủ để người khác tới tranh.

## Nút bắn. `interact` (E) — trong sân không có vật nào để nhặt nên phím này rảnh.
const NUT_BAN := "interact"
## Nghỉ giữa hai phát, giây. Không có thì giữ phím là một vòi lửa liền mạch.
const NGHI_BAN := 0.7
## Cầu lửa rời tay ở độ cao này, để nó bay ngang tầm ngực chứ không lết dưới sàn.
const CAO_BAN := 1.0
## Trúng cầu lửa thì bị hất mạnh cỡ nào — ngang và dốc lên.
##
## Nhẹ hơn Magma (11,0 / 4,5) vì ở đây hất không để giết: chỉ cần đẩy người ta rời khỏi quả miện
## vừa rơi. Hất quá mạnh thì ai trúng một phát là mất luôn lượt tranh.
const DAY_NGANG := 9.0
const DAY_LEN := 3.5

## Miện rơi xuống rồi chừng này giây sau mới nhặt được.
const NGHI_CUOP := 1.1
## Miện đội trên đầu người giữ.
const CAO_DOI := 2.2
## Miện nằm dưới đất ở độ cao này khi chưa ai nhặt.
const CAO_NAM := 0.8

@export var cau_lua_scene: PackedScene = null

@onready var _bang: Label = $Lop/Bang

var _mien: Node3D = null
var _vung: Area3D = null
var _diem_3d: Label3D = null
var _vong: Node3D = null

## Ai đang giữ. 0 = miện đang nằm đất. Chỉ đổi qua `_net_giu`.
var _ai_giu := 0
## Miện đang nằm ở đâu khi không ai giữ (toạ độ cục bộ trong `san`).
var _cho_nam := Vector3.ZERO
## Giờ ván sớm nhất được phép nhặt tiếp.
var _cho_toi := 0.0
## player_id -> giây đã giữ. Mọi máy tự cộng; bảng của master là bảng quyết định.
var _diem: Dictionary = {}

var _cau: Array[CauLua] = []
var _ban_luc := -99.0
## instance_id của những quả ĐÃ hất mình rồi. Quả cầu sống 1,6 giây; không nhớ thì nó cộng dồn
## lực đẩy mỗi khung hình và bắn người chơi ra khỏi bản đồ.
var _da_dinh: Dictionary = {}
## Bán kính sàn, ĐỌC từ mesh chứ không chép tay.
var _ban_kinh := 11.5


func _ready() -> void:
	super()
	ten = "CROWN CAPTURE"
	luat = "WASD chạy · E bắn cầu lửa · trúng người đội miện thì miện rơi · giữ lâu thì thắng"
	giay_van = 60.0


func _dung_san() -> void:
	_mien = san.get_node_or_null("Mien") as Node3D
	if _mien == null:
		push_error("Crown: san thieu node Mien")
		return
	_vung = _mien.get_node("Vung") as Area3D
	_diem_3d = _mien.get_node("Diem") as Label3D
	_vong = _mien.get_node("VongNhat") as Node3D
	_ai_giu = 0
	_cho_nam = Vector3(0.0, CAO_NAM, 0.0)
	_cho_toi = 0.0
	_cau.clear()
	_da_dinh.clear()
	_ban_luc = -99.0
	_diem.clear()
	for id in _song:
		_diem[int(id)] = 0.0
	$Lop.visible = true
	var bon := san.get_node_or_null("SanTron") as Node3D
	var m := bon.get_node_or_null("Mat") as MeshInstance3D if bon != null else null
	var cyl := m.mesh as CylinderMesh if m != null else null
	if cyl != null:
		_ban_kinh = cyl.top_radius


func dung_som() -> void:
	$Lop.visible = false
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
		_diem_3d.text = "%.0f" % float(_diem[_ai_giu])
	else:
		# Nằm ĐÚNG chỗ rơi, không về giữa sân: chỗ rơi là thông tin, và kéo nó về tâm là xoá đi
		# khoảnh khắc giành nhau mà cú đòn vừa tạo ra.
		_mien.position = _cho_nam
		_diem_3d.text = "?"
	# Vòng tầm nhặt chỉ hiện khi miện nằm đất VÀ đã hết nghỉ — nó trả lời đúng câu "chạy vào đây
	# lúc này có nhặt được không". Đội trên đầu thì vòng vô nghĩa.
	_vong.visible = _ai_giu == 0 and gio() >= _cho_toi
	_ve_bang()
	_cau = _cau.filter(func(c: CauLua) -> bool: return is_instance_valid(c))

	if not con_song(NetManager.local_id()):
		return
	_giu_tren_san()
	# Chỉ máy của NGƯỜI SẮP NHẶT đi hỏi — mỗi máy chỉ tự nói về nhân vật của mình.
	if _ai_giu != 0 or gio() < _cho_toi:
		return
	var toi := _nguoi(NetManager.local_id())
	# Hỏi thẳng `Area3D`: tầm nhặt CHÍNH LÀ cái vòng `VongNhat` dưới quả miện — cả hai lấy bán
	# kính 1,5 trong `vuong_mien.tscn`.
	#
	# Bản trước comment bảo tầm nhặt bằng "quầng sáng", nhưng quầng sáng là `OmniLight` tầm 6,0
	# còn vùng nhặt chỉ 1,5 — nói một đằng làm một nẻo.
	if toi != null and _vung.overlaps_body(toi):
		Fusion.rpc(_xin_cuop, NetManager.local_id())


## Bảng điểm của CẢ PHÒNG, không chỉ người đang giữ.
##
## Thiếu nó thì người chơi không biết mình đang thứ mấy, và cả phần "cuối ván ai cũng xông vào
## người dẫn điểm" không xảy ra được — không ai biết ai đang dẫn.
func _ve_bang() -> void:
	var ids: Array = []
	for id in _diem:
		ids.append(int(id))
	ids.sort_custom(func(a: int, b: int) -> bool: return float(_diem[a]) > float(_diem[b]))
	var dong := PackedStringArray()
	for i in ids.size():
		var id: int = ids[i]
		var dau := "♛ " if id == _ai_giu else "   "
		dong.append("%s%-12s %5.1f s" % [dau, Player.ten_theo_id(get_tree(), id), float(_diem[id])])
	_bang.text = "\n".join(dong)


## Kẹp nhân vật CỦA MÁY NÀY trong lòng sàn. Chỉ `is_mine` — kéo người khác là đánh nhau với
## replicator đang gửi vị trí của họ.
##
## Trò này cố ý KHÔNG cho ai chết: thắng thua chỉ do tổng giây đội miện, nên hất nhau xuống vực
## sẽ biến nó thành nửa deathmatch. Hất giờ chỉ để đẩy người ta rời quả miện.
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


## Trúng cầu lửa: tự áp lực đẩy lên mình, và nếu mình đang đội miện thì xin cho miện rơi.
##
## Ghi đè `_toi_thua()` vì đây là hàm lớp cha gọi mỗi khung hình cho nhân vật của máy này. Trả về
## `false` luôn: trò này không có đường thua nào, hết giờ mới chốt.
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return false
	for c in _cau:
		if c.nguoi_ban == NetManager.local_id() or _da_dinh.has(c.get_instance_id()):
			continue
		if not c.overlaps_body(p):
			continue
		_da_dinh[c.get_instance_id()] = true
		var ra := p.global_position - c.global_position
		ra.y = 0.0
		if ra.length_squared() < 0.001:
			ra = Vector3.RIGHT
		p.day(ra.normalized() * DAY_NGANG + Vector3.UP * DAY_LEN)
		if _ai_giu == NetManager.local_id():
			Fusion.rpc(_xin_roi, NetManager.local_id())
		c.queue_free()
		break
	return false


func _unhandled_input(event: InputEvent) -> void:
	if not _chay or not event.is_action_pressed(NUT_BAN):
		return
	if gio() - _ban_luc < NGHI_BAN:
		return
	var p := _nguoi(NetManager.local_id())
	if p == null or not con_song(NetManager.local_id()):
		return
	get_viewport().set_input_as_handled()
	_ban_luc = gio()
	# Bắn theo hướng thân đang quay — ở chế độ sân, thân tự quay theo hướng chạy.
	var huong := -p.global_transform.basis.z
	huong.y = 0.0
	Fusion.rpc(_net_ban, NetManager.local_id(),
			p.global_position + Vector3.UP * CAO_BAN, huong.normalized())


## Một gói cho cả đời quả cầu. Mọi máy tự dựng và tự cho nó bay — không gửi vị trí lần nào nữa.
@rpc("any_peer", "call_local")
func _net_ban(id: int, tu: Vector3, huong: Vector3) -> void:
	if san == null or cau_lua_scene == null:
		return
	var c := cau_lua_scene.instantiate() as CauLua
	san.add_child(c)
	c.ban(tu, huong, id)
	_cau.append(c)


# ───────────────────────── trọng tài: master duyệt rồi phát ─────────────────────────

@rpc("any_peer", "call_local")
func _xin_cuop(ai: int) -> void:
	# Hai người chạm miện cùng lúc thì gói nào tới master trước thắng, gói sau bị `_cho_toi`
	# chặn. Không có trọng tài thì mỗi máy tự cho mình là người nhặt được.
	if not NetManager.is_master() or _ai_giu != 0 or gio() < _cho_toi or not con_song(ai):
		return
	Fusion.rpc(_net_giu, ai, Vector3.ZERO)


## Người đang đội miện vừa trúng đòn: miện rơi xuống đúng chỗ họ đứng.
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
