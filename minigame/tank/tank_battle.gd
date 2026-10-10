extends MiniGame

## Tank 1990 — đấu trường 2D, sống lâu nhất thắng; trúng một phát là ra.
## Chỉ gửi sự kiện (đổi hướng kèm toạ độ, bắn, trúng, phá gạch); người bị bắn tự nhận.

const GIAY_VAN := 75.0
const CO_DAN := 8.0

## Xe và đạn sinh giữa ván.
@export var xe_scene: PackedScene
@export var dan_scene: PackedScene

var _xe: Dictionary = {}         ## player_id -> XeTang
var _chet_theo: Array = []       ## id theo thứ tự chết, dùng để xếp hạng ngược
var _con_lai: Array = []
var _chay := false
var _het_luc := 0.0
var _huong_cu := Vector2i.ZERO

@onready var _san: Node2D = $San
@onready var _ban_do: BanDoTank = $San/BanDo
@onready var _lop_xe: Node2D = $San/Xe
@onready var _lop_dan: Node2D = $San/Dan
@onready var _dong_ho: Label = $Lop/DongHo


func _ready() -> void:
	ten = "TANK 1990"
	luat = "WASD di chuyển · J hoặc Space bắn · sống sót lâu nhất thắng"
	Fusion.register_broadcast_receiver(self)
	# Phải gỡ đăng ký RPC khi rời cây (mỗi ván tạo mới).
	tree_exiting.connect(func(): Fusion.unregister_broadcast_receiver(self))
	# Canh giữa màn hình theo kích thước bản đồ.
	_san.position = (get_viewport().get_visible_rect().size - _ban_do.kich_thuoc()) * 0.5
	set_process(false)


func bat_dau(nguoi_choi: Array, hat_giong: int) -> void:
	_don_sach()
	_chet_theo.clear()
	_con_lai = nguoi_choi.duplicate()
	_huong_cu = Vector2i.ZERO
	var cho := _ban_do.cho_sinh()
	for i in nguoi_choi.size():
		var id := int(nguoi_choi[i])
		var xe: XeTang = xe_scene.instantiate()
		_lop_xe.add_child(xe)
		xe.khoi_tao(NetManager.color_for(_chi_so_mau(id)), id == NetManager.local_id())
		# Chỗ sinh xoay theo hạt giống.
		xe.lai(Vector2i.ZERO, cho[posmod(i + hat_giong, cho.size())])
		_xe[id] = xe
	_het_luc = _gio() + GIAY_VAN
	_chay = true
	set_process(true)


func dung_som() -> void:
	_chay = false
	set_process(false)
	_don_sach()


# ─── vòng chơi ───

func _process(delta: float) -> void:
	if not _chay:
		return
	_doc_phim()
	for id: int in _xe:
		_xe[id].chay(delta, _ban_do)
	_cham_dan()
	_dong_ho.text = "%d\"   còn %d xe" % [maxi(0, int(_het_luc - _gio())), _con_lai.size()]
	if _gio() >= _het_luc or _con_lai.size() <= 1:
		_ket_thuc()


func _doc_phim() -> void:
	var toi := NetManager.local_id()
	var xe: XeTang = _xe.get(toi)
	if xe == null or not xe.song:
		return
	var h := Vector2i.ZERO
	# Một hướng tại một thời điểm (không đi chéo).
	if Input.is_key_pressed(KEY_W):
		h = Vector2i(0, -1)
	elif Input.is_key_pressed(KEY_S):
		h = Vector2i(0, 1)
	elif Input.is_key_pressed(KEY_A):
		h = Vector2i(-1, 0)
	elif Input.is_key_pressed(KEY_D):
		h = Vector2i(1, 0)
	if h != _huong_cu:
		_huong_cu = h
		# Kèm toạ độ để máy nhận nắn lại.
		Fusion.rpc(_net_lai, toi, h, xe.position)
	if Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_SPACE):
		if xe.san_sang_ban(_gio()):
			# Ghi giờ ngay, không đợi gói quay về.
			xe.ghi_ban(_gio())
			Fusion.rpc(_net_ban, toi, xe.position, xe.huong)


func _cham_dan() -> void:
	var toi := NetManager.local_id()
	var xe_toi: XeTang = _xe.get(toi)
	for d: Dan in _lop_dan.get_children():
		var l := _ban_do.loai_tai(d.position)
		if l == OTuong.Loai.THEP:
			d.queue_free()                             # đạn tan, tường thép không vỡ
			continue
		if l == OTuong.Loai.GACH:
			# Chỉ chủ viên đạn phát lệnh phá gạch.
			if d.chu == toi:
				Fusion.rpc(_net_pha, _ban_do.chi_so_tai(d.position))
			d.queue_free()
			continue
		# Chỉ kiểm xe của mình.
		if xe_toi != null and xe_toi.song and d.chu != toi:
			if d.position.distance_to(xe_toi.position) < (XeTang.CO + CO_DAN) * 0.5:
				Fusion.rpc(_net_trung, toi)
				d.queue_free()


func _ket_thuc() -> void:
	if not _chay:
		return
	_chay = false
	set_process(false)
	for d in _lop_dan.get_children():
		d.queue_free()                                 # đạn đang bay không được giết thêm ai
	# Chết sau = hạng cao hơn.
	var hang := _con_lai.duplicate()
	var nguoc := _chet_theo.duplicate()
	nguoc.reverse()
	hang.append_array(nguoc)
	xong.emit(hang)


func _don_sach() -> void:
	for n in _lop_xe.get_children() + _lop_dan.get_children():
		n.queue_free()
	_xe.clear()


# ─── gói mạng ───

@rpc("any_peer", "call_local")
func _net_lai(id: int, h: Vector2i, vi: Vector2) -> void:
	if _xe.has(id):
		_xe[id].lai(h, vi)


@rpc("any_peer", "call_local")
func _net_ban(id: int, vi: Vector2, h: Vector2i) -> void:
	var d: Dan = dan_scene.instantiate()
	d.position = vi
	d.huong = Vector2(h)
	d.chu = id
	_lop_dan.add_child(d)
	if _xe.has(id):
		_xe[id].ghi_ban(_gio())


@rpc("any_peer", "call_local")
func _net_trung(id: int) -> void:
	if not _xe.has(id) or not _xe[id].song:
		return
	_xe[id].chet()
	_chet_theo.append(id)
	_con_lai.erase(id)


@rpc("any_peer", "call_local")
func _net_pha(ix: int) -> void:
	_ban_do.pha(ix)


func _chi_so_mau(id: int) -> int:
	return posmod(id - 1, NetManager.PLAYER_COLORS.size())


static func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0
