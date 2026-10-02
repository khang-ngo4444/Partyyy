extends MiniGame3D

## WORD WARS — mỗi người một từ hiện trên đầu, chạy tới ô chữ trên sàn và bấm E để gõ từng chữ.
##
## Khuôn T3. Sàn là 26 ô A–Z đặt sẵn trong `san_chu.tscn` (lưới 6 cột như bàn phím trải dưới
## đất). Gõ xong một từ thì được một điểm và nhận từ mới. Hết giờ, ai nhiều từ nhất đứng đầu.
##
## ## Từ của mỗi người là hàm thuần — không gói tin nào để phát từ
##
## `tu_cua(hat_giong, id, so_tu_xong)` cho ra từ đang gõ của một người. Mọi máy biết cả ba
## tham số (điểm được cộng qua `_net_tien`), nên mọi máy hiện đúng chữ trên đầu từng người mà
## không ai phải gửi "từ của tôi là gì".
##
## ## Một gói cho mỗi chữ ĐÚNG
##
## Tiến độ phải gửi đi vì chữ trên đầu là thứ người khác nhìn để biết mình đang thua ai. Chữ
## sai không tốn gói nào và không bị phạt — phạt chỉ dạy người chơi đứng yên không dám gõ.
##
## Mỗi người chỉ tự gõ cho chính mình, nên không có gì để tranh, không cần trọng tài.
##
## ## Đánh nhau
##
## Ô chữ là của chung, nên chen nhau là chuyện tự nhiên: F đánh (đòn chung của `MiniGame3D`,
## bật `co_danh` trong `word_wars.tscn`) hất người ta khỏi ô họ đang cần và làm họ CHOÁNG
## `GIAY_CHOANG` giây không gõ được. Tiến độ không mất — mất chữ vì bị đánh là quá gắt.

## Nút gõ. Trong sân không có gì để nhặt nên phím này rảnh.
const NUT_GO := "interact"
## Nghỉ giữa hai lần gõ, giây. Chặn giữ phím E rồi lướt qua các ô.
const NGHI_GO := 0.15
## Bị đánh trúng thì không gõ được chừng này giây.
const GIAY_CHOANG := 1.0
## Kẹp người chơi trong bán kính này — sàn 11,5. Trò không chết vì rơi, nên cú đánh không được
## hất ai ra khỏi sàn.
const BAN_KINH_GIU := 11.0

const TU := ["NHA", "CUA", "BAN", "MEO", "CHO", "HOA", "CAY", "SAO", "MUA", "GIO",
		"NUI", "TRE", "COM", "PHO", "BIEN", "SONG", "BANH", "CHAM", "XANH", "TRANG",
		"VUI", "KHOE", "QUAT", "DEN", "MAY"]

## Chữ trên đầu của chính mình tô màu này, người khác màu trắng — nhìn sân đông là thấy ngay
## mình ở đâu.
const MAU_TOI := Color(1.0, 0.85, 0.2)

@export var chu_tren_dau_scene: PackedScene = null

var _o: Array[OChu] = []
## player_id -> số từ đã gõ xong. Mọi máy cùng cộng từ RPC; bảng của master là bảng chốt.
var _diem: Dictionary = {}
## player_id -> đã gõ đúng mấy chữ đầu của từ hiện tại.
var _tien: Dictionary = {}
## player_id -> Label3D trên đầu người đó. Nhãn là con của Player, phải tự gỡ khi xong ván.
var _nhan: Dictionary = {}
var _go_luc := -99.0
var _choang_toi := -99.0


func _ready() -> void:
	super()
	ten = "WORD WARS"
	luat = "WASD chạy · đứng lên ô chữ rồi bấm E · gõ đúng từ trên đầu mình · F đánh"
	giay_van = 60.0


func _dung_san() -> void:
	_o.assign(san.get_node("Bang").get_children())
	_diem.clear()
	_tien.clear()
	_go_luc = -99.0
	_choang_toi = -99.0
	for id in _song:
		_diem[int(id)] = 0
		_tien[int(id)] = 0
	if _o.size() != 26:
		push_error("WordWars: san co %d o chu, can 26" % _o.size())
	_gan_nhan()


func dung_som() -> void:
	_go_nhan()
	super()


func _luat_moi_nhip() -> void:
	giu_trong_san(BAN_KINH_GIU)
	for id in _nhan:
		var n := _nhan[id] as Label3D
		if is_instance_valid(n):
			n.text = hien_tu(tu_hien_tai(int(id)), int(_tien.get(id, 0)))


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if not _chay or not event.is_action_pressed(NUT_GO):
		return
	if gio() - _go_luc < NGHI_GO or gio() < _choang_toi:
		return
	var id := NetManager.local_id()
	var p := _nguoi(id)
	if p == null or not _tien.has(id):
		return
	get_viewport().set_input_as_handled()
	_go_luc = gio()
	var o := _o_duoi_chan(p)
	if o == null:
		return
	var tu := tu_hien_tai(id)
	var k := int(_tien[id])
	if k < tu.length() and o.chu == tu[k]:
		Fusion.rpc(_net_tien, id, k + 1)


## Tiến độ mới của một người. Gõ đủ chữ thì cộng điểm và về 0 — từ mới tự suy ra từ điểm.
##
## Gửi CON SỐ tiến độ chứ không gửi "+1": gói tới trễ hay lặp lại cũng không cộng đúp.
@rpc("any_peer", "call_local")
func _net_tien(id: int, tien: int) -> void:
	if not _tien.has(id) or tien != int(_tien[id]) + 1:
		return
	if tien >= tu_hien_tai(id).length():
		_diem[id] = int(_diem[id]) + 1
		_tien[id] = 0
	else:
		_tien[id] = tien


func _khi_bi_danh(_ke_danh: int, nan: int) -> void:
	if nan == NetManager.local_id():
		_choang_toi = gio() + GIAY_CHOANG


func tu_hien_tai(id: int) -> String:
	return tu_cua(hat_giong, id, int(_diem.get(id, 0)))


## Ô chữ đang ở dưới chân người này, null nếu không đứng trên ô nào.
func _o_duoi_chan(p: Player) -> OChu:
	for o in _o:
		if o.vung.overlaps_body(p):
			return o
	return null


# ───────────────────────── nhãn trên đầu ─────────────────────────

## Gắn một nhãn lên đầu MỌI người chơi trên máy này. Nhãn là scene đặt sẵn; ở đây chỉ
## `instantiate()` vì số người chỉ biết lúc vào ván.
func _gan_nhan() -> void:
	_go_nhan()
	if chu_tren_dau_scene == null:
		push_error("WordWars: thieu chu_tren_dau_scene")
		return
	for p: Player in get_tree().get_nodes_in_group("players"):
		var id := p.player_id()
		if not _tien.has(id):
			continue
		var n := chu_tren_dau_scene.instantiate() as Label3D
		n.modulate = MAU_TOI if p.is_mine else Color.WHITE
		p.add_child(n)
		_nhan[id] = n
		# Tên người chơi nằm đúng chỗ nhãn từ — ẩn đi cho khỏi chồng chữ, trả lại khi xong ván.
		p.name_tag.visible = false


func _go_nhan() -> void:
	for id in _nhan:
		var n = _nhan[id]
		if is_instance_valid(n):
			n.queue_free()
	_nhan.clear()
	for p: Player in get_tree().get_nodes_in_group("players"):
		p.name_tag.visible = not p.is_mine


# ───────────────────────── xếp hạng theo số từ ─────────────────────────

func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _diem:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool:
		if int(_diem[a]) != int(_diem[b]):
			return int(_diem[a]) > int(_diem[b])
		return int(_tien[a]) > int(_tien[b]))
	Fusion.rpc(_net_xep_hang, xep)


## Không ai rơi khỏi sàn trong trò này — xếp hạng chỉ theo số từ, chạy đủ giờ.
func _toi_thua() -> bool:
	return false


# ───────────────────────── luật: hàm thuần ─────────────────────────

## Từ thứ `so_xong` của người `id` trong ván có hạt giống `giong`. Mỗi người một chuỗi từ
## riêng, nhưng ai cũng tính ra được chuỗi của người khác.
static func tu_cua(giong: int, id: int, so_xong: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([giong, id, so_xong])
	return TU[rng.randi() % TU.size()]


## Chữ hiện trên đầu: chữ đã gõ thành `•`, nên chữ ĐẦU TIÊN còn thấy là chữ phải gõ kế tiếp.
static func hien_tu(tu: String, tien: int) -> String:
	return "•".repeat(tien) + tu.substr(tien)
