class_name MiniGame3D
extends MiniGame

## Khung chung cho minigame 3D bằng nhân vật: dựng sân trên cao, đưa người chơi lên rồi trả về
## chỗ cũ, đếm giờ, xếp hạng. Lớp con chỉ lo luật. Mỗi máy tự đếm giờ; người thua tự khai tử.

enum { DON_DANH, DON_CHUONG }

## Sân đặt cao hơn phòng chờ chừng này.
const CAO_SAN := 300.0

## Rơi thấp hơn mặt sân chừng này là rơi khỏi sàn.
const ROI_KHOI_SAN := 8.0

## Hai đòn tay không (bật `co_danh`): ĐÁNH (chuột trái/F) gây choáng,
## CHƯỞNG (chuột phải/G) hất văng.
## Tầm tính từ tâm người đánh tới tâm nạn nhân.
const NUT_DANH := "danh"
const NUT_CHUONG := "chuong"
const TAM_DON := [1.7, 2.8]

## Nạn nhân phải ở phía trước (tích vô hướng tối thiểu).
const GOC_DON := [0.2, 0.5]

## Nghỉ giữa hai đòn cùng loại (giây).
const NGHI_DON := [0.55, 1.1]
const GIAY_CHOANG := 0.9

## Lực hất của CHƯỞNG (ngang, lên).
const CHUONG_NGANG := 10.0
const CHUONG_LEN := 3.5

## Phóng to hình nhân vật trong sân (chỉ hình).
const TO_HON := 1.3

## Sống tới cuối ván được cộng thêm.
const THUONG_SONG_CUOI := 10.0

@export var san_scene: PackedScene = null

## 0 = không giới hạn, chạy tới khi còn một người.
@export var giay_van := 60.0
@export var co_danh := false

var san: Node3D = null
var hat_giong := 0

## player_id -> giây sống được; -1 = còn sống.
var _song: Dictionary = {}

## Thứ tự master nhận tin chết (phá hoà).
var _thu_tu_chet: Array = []

## Chỗ đứng trước khi lên sân, để trả về.
var _cho_cu := Transform3D.IDENTITY
var _co_cho_cu := false
var _khoa_cu := false
var _bat_dau_luc := 0.0
var _chay := false
var _rng := RandomNumberGenerator.new()
var _don_luc := [-99.0, -99.0]

## Nhân vật máy này bị choáng tới `gio()` này.
var _choang_toi := -99.0
var _dang_choang := false
var _da_chot := false
var _het_luc := 0.0


func _ready() -> void:
	# Sân nằm trong thế giới — không che nền.
	che_nen = false
	Fusion.register_broadcast_receiver(self)
	# Phải gỡ đăng ký RPC khi rời cây (mỗi ván tạo mới).
	tree_exiting.connect(func(): Fusion.unregister_broadcast_receiver(self))
	set_process(false)


func bat_dau(nguoi_choi: Array, giong: int) -> void:
	hat_giong = giong
	_rng.seed = giong
	_song.clear()
	_thu_tu_chet.clear()
	for id in nguoi_choi:
		_song[int(id)] = -1.0

	san = san_scene.instantiate() as Node3D
	san.position.y = CAO_SAN
	get_tree().current_scene.add_child(san)
	_dung_san()

	# Chỉ nhấc nhân vật của máy này.
	var toi := _nguoi(NetManager.local_id())
	if toi != null:
		_cho_cu = toi.global_transform
		_co_cho_cu = true
		var i := maxi(nguoi_choi.find(NetManager.local_id()), 0)
		toi.global_position = san.global_position + _cho_vao(i, nguoi_choi.size()) + Vector3.UP
		toi.velocity = Vector3.ZERO
	_che_do_san(true)

	_bat_dau_luc = _gio_may()
	_chay = true
	set_process(true)


## Dọn sân và trả người chơi về chỗ cũ (gọi nhiều lần được).
func dung_som() -> void:
	_chay = false
	set_process(false)
	_che_do_san(false)
	var toi := _nguoi(NetManager.local_id())
	if toi != null and _co_cho_cu:
		toi.global_transform = _cho_cu
		toi.velocity = Vector3.ZERO
	_co_cho_cu = false
	if san != null and is_instance_valid(san):
		san.queue_free()
	san = null


## Giây từ lúc ván bắt đầu — chướng ngại là hàm của số này.
func gio() -> float:
	return _gio_may() - _bat_dau_luc


func con_song(id: int) -> bool:
	return _song.has(id) and float(_song[id]) < 0.0


func so_con_song() -> int:
	var n := 0
	for id in _song:
		if con_song(int(id)):
			n += 1
	return n


func _process(_delta: float) -> void:
	if not _chay:
		return
	if co_danh:
		_nhip_choang()
	_luat_moi_nhip()
	if con_song(NetManager.local_id()) and _toi_thua():
		xin_chet()
	if not NetManager.is_master():
		return
	if so_con_song() <= 1 or (giay_van > 0.0 and gio() >= giay_van):
		_chot_ket_qua()


# ─── lớp con cài ba hàm này ───


func _dung_san() -> void:
	pass


## Mỗi khung khi ván đang chạy.
func _luat_moi_nhip() -> void:
	pass


## Nhân vật của máy này vừa thua chưa (mặc định: rơi khỏi sàn).
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	return p != null and p.global_position.y < san.global_position.y - ROI_KHOI_SAN


# ─── đánh tay không ───


## Đọc chuột ở `_input` vì GUI có thể nuốt click.
func _input(event: InputEvent) -> void:
	if not co_danh or not _chay:
		return
	var loai := -1
	if event.is_action_pressed(NUT_DANH):
		loai = DON_DANH
	elif event.is_action_pressed(NUT_CHUONG):
		loai = DON_CHUONG
	if loai < 0 or gio() - float(_don_luc[loai]) < float(NGHI_DON[loai]) or dang_choang():
		return
	var toi := _nguoi(NetManager.local_id())
	if toi == null or not con_song(NetManager.local_id()):
		return
	get_viewport().set_input_as_handled()
	_don_luc[loai] = gio()
	var nan := tim_nan(toi, loai)
	if nan == null:
		return
	var huong := nan.global_position - toi.global_position
	huong.y = 0.0
	Fusion.rpc(_net_danh, NetManager.local_id(), nan.player_id(), huong.normalized(), loai)


## Người gần nhất trong tầm, phía trước, còn sống; null = trượt (máy người đánh phán).
func tim_nan(toi: Player, loai: int) -> Player:
	var truoc := -toi.global_basis.z
	truoc.y = 0.0
	truoc = truoc.normalized()
	var gan: Player = null
	var gan_nhat: float = TAM_DON[loai]
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p == toi or not con_song(p.player_id()):
			continue
		var d := p.global_position - toi.global_position
		d.y = 0.0
		var dai := d.length()
		if dai > gan_nhat or dai < 0.001 or truoc.dot(d / dai) < float(GOC_DON[loai]):
			continue
		gan = p
		gan_nhat = dai
	return gan


## Chỉ máy của nạn nhân tự áp hậu quả.
@rpc("any_peer", "call_local")
func _net_danh(ke_danh: int, nan: int, huong: Vector3, loai: int) -> void:
	if not _chay:
		return
	if nan == NetManager.local_id():
		var p := _nguoi(nan)
		if loai == DON_CHUONG and p != null:
			p.day(huong * CHUONG_NGANG + Vector3.UP * CHUONG_LEN)
		elif loai == DON_DANH:
			_choang_toi = gio() + GIAY_CHOANG
	_khi_bi_danh(ke_danh, nan, loai)


## Mọi máy; lớp con thêm luật riêng.
func _khi_bi_danh(_ke_danh: int, _nan: int, _loai: int) -> void:
	pass


func dang_choang() -> bool:
	return gio() < _choang_toi


## Choáng = khoá WASD và nhảy; chỉ đổi khoá lúc vào/ra choáng.
func _nhip_choang() -> void:
	var choang := dang_choang()
	if choang == _dang_choang:
		return
	_dang_choang = choang
	var p := _nguoi(NetManager.local_id())
	if p != null:
		p.khoa_di_chuyen = choang
		p.velocity = Vector3.ZERO


## Giữ nhân vật máy này trong bán kính `r` quanh tâm sân.
func giu_trong_san(r: float) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null or san == null:
		return
	var l := p.global_position - san.global_position
	var v := Vector2(l.x, l.z)
	if v.length() <= r:
		return
	v = v.normalized() * r
	p.global_position = san.global_position + Vector3(v.x, l.y, v.y)


# ─── chết và xếp hạng ───


## Tự khai thua.
func xin_chet() -> void:
	if not con_song(NetManager.local_id()):
		return
	Fusion.rpc(_net_chet, NetManager.local_id(), gio())


@rpc("any_peer", "call_local")
func _net_chet(id: int, giay: float) -> void:
	if not _song.has(id) or not con_song(id):
		return
	_song[id] = giay
	_thu_tu_chet.append(id)
	_khi_ai_do_chet(id)


func _khi_ai_do_chet(_id: int) -> void:
	pass


## CHỈ master chốt bảng rồi phát.
func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _song:
		xep.append(int(id))
	# Còn sống đứng đầu, rồi ai chết sau đứng trên. Xếp theo thứ tự master nhận lệnh chết,
	# KHÔNG so giờ: `_song[id]` là đồng hồ máy người chết, lệch đồng hồ master → thắng thành thua.
	xep.sort_custom(func(a: int, b: int) -> bool:
		var ia := 1 << 30 if con_song(a) else _thu_tu_chet.find(a)
		var ib := 1 << 30 if con_song(b) else _thu_tu_chet.find(b)
		return ia > ib)
	Fusion.rpc(_net_xep_hang, xep)


@rpc("any_peer", "call_local")
func _net_xep_hang(xep: Array) -> void:
	_chay = false
	set_process(false)
	if not _da_chot:
		_da_chot = true
		_het_luc = gio()
	xong.emit(xep)


# ─── ô điểm: mặc định là điểm sinh tồn ───


## Giây sống, cộng `THUONG_SONG_CUOI` nếu sống tới lúc chốt.
func diem_cua(id: int) -> float:
	if not _song.has(id):
		return NAN
	var chet := float(_song[id])
	if chet >= 0.0:
		return chet
	if _da_chot:
		return _het_luc + THUONG_SONG_CUOI
	return gio()


func chu_diem(id: int) -> String:
	var d := diem_cua(id)
	if is_nan(d):
		return ""
	var them := " ★" if _da_chot and con_song(id) else ""
	return "%.0f%s" % [d, them]


# ─── người chơi ───


## Rải người chơi trên vòng tròn quanh tâm.
func _cho_vao(i: int, tong: int) -> Vector3:
	if tong <= 1:
		return Vector3.ZERO
	var a := TAU * i / float(tong)
	return Vector3(cos(a), 0.0, sin(a)) * ban_kinh_vao_san()


func ban_kinh_vao_san() -> float:
	return 7.0


## Bật/tắt chế độ sân: camera sân, WASD theo trục thế giới.
func _che_do_san(bat: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		# Phóng to hình mọi người (cục bộ).
		p.model_root.scale = Vector3.ONE * (TO_HON if bat else 1.0)
		if not p.is_mine:
			continue
		p.che_do_san = bat
		# Bàn party khoá WASD — mở khi vào sân, trả lại khi ra.
		if bat:
			_khoa_cu = p.khoa_di_chuyen
			p.khoa_di_chuyen = false
			var c := _cam_san()
			if c != null:
				c.make_current()
		else:
			p.khoa_di_chuyen = _khoa_cu
			if p.rig != null and is_instance_valid(p.rig):
				p.rig.camera.make_current()


## Camera nằm ở `SanDau/Cam` của sân.
func _cam_san() -> Camera3D:
	return san.find_child("Cam", true, false) as Camera3D if san != null else null


func _nguoi(id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == id:
			return p
	return null


func _gio_may() -> float:
	return Time.get_ticks_msec() / 1000.0


# ─── luật dùng chung ───


## Góc của vật quay có tốc độ tăng đều (tích phân tốc độ, không phải tốc_độ × t).
static func goc_quay(pha: float, t: float, toc_dau: float, toc_cuoi: float,
		tang_het: float) -> float:
	var k := minf(t, tang_het)
	var quet := toc_dau * k + (toc_cuoi - toc_dau) * k * k / (2.0 * tang_het)
	if t > tang_het:
		quet += toc_cuoi * (t - tang_het)
	return pha + quet
