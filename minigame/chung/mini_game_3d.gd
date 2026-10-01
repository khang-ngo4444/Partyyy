class_name MiniGame3D
extends MiniGame

## KHUNG CHUNG cho mọi minigame pha 3 chơi bằng NHÂN VẬT trong không gian 3D — khuôn T1 (sàn
## đẩy nhau), T2 (né chướng ngại) và T3 (lưới ô) đều dựng trên đây.
##
## Lớp con chỉ lo **luật**: cái gì giết người chơi, cái gì cho điểm. Mọi thứ còn lại ở đây.
##
## ## ⚠️ PHẢI TRẢ NGƯỜI CHƠI VỀ CHỖ CŨ
##
## Bản đầu tiên của file này nhấc người chơi lên sân ở `y = 300` rồi **không bao giờ đưa họ
## xuống**: `dung_som()` xoá cái sân đi và để cả phòng lơ lửng giữa không trung. Ở pha 2 thì
## gói trạng thái bàn kéo họ về ô nên không lộ; về **pha 1 thì không có gì kéo họ về cả** —
## cả phòng rơi tự do xuyên thế giới.
##
## Nên `_cho_cu` chụp lại `global_transform` trước khi đi, và `dung_som()` đặt lại. Đây là
## phần BẮT BUỘC phải chạy thử, không phải phần phụ: test minigame tách rời rồi kết luận
## "chạy được" chính là cách bỏ sót nó lần trước.
##
## ## Sân nằm ở đâu — và vì sao không dùng `Fusion.load_scene()`
##
## Sân là scene nạp **cục bộ** vào `current_scene` ở `CAO_SAN` mét trên trời — đúng cách
## `PhaBanCo` làm với bàn party, và cách đó đã chạy thật qua Photon. `load_scene()` đẹp hơn về
## lý thuyết nhưng còn một câu chưa ai kiểm: người chơi do `FusionSpawner` spawn có sống sót
## khi `unload_scene()` gỡ phòng chờ không (MINIGAME.md mục 9). Không đánh cược vào đó.
##
## Sân **không phải object mạng** — mọi máy tự dựng từ cùng hạt giống, tốn đúng 0 byte.
##
## ## Đồng hồ: mỗi máy tự đếm, KHÔNG đồng bộ
##
## Chướng ngại là hàm của `gio()`. Hai máy lệch nhau cỡ nửa RTT (30–45 ms), không sửa và không
## cần sửa: **người bị nạn tự khai tử**, nên lệch một nhịp chỉ làm người khác thấy mình chết
## sớm/muộn vài phần trăm giây, không bao giờ đẻ ra hai kết quả chỏi nhau.

## Sân đặt cao hơn phòng chờ chừng này. Bàn party đang ở 100 m, để xa hẳn ra.
const CAO_SAN := 300.0
## Rơi thấp hơn mặt sân chừng này thì coi như đã rơi khỏi sàn.
const ROI_KHOI_SAN := 8.0

## Scene sân của trò này. Lớp con trỏ export này sang scene của nó trong `.tscn`.
@export var san_scene: PackedScene = null
## Ván dài bao lâu. 0 = không giới hạn, chạy tới khi còn một người.
@export var giay_van := 60.0

var san: Node3D = null
var hat_giong := 0
## player_id -> giây sống được. Người còn sống mang -1 cho tới lúc chết.
var _song: Dictionary = {}
## player_id theo ĐÚNG thứ tự master nhận tin chết. Dùng để phá hoà.
var _thu_tu_chet: Array = []
## Chỗ đứng trước khi lên sân, để còn đường về. Xem ghi chú đầu file.
var _cho_cu := Transform3D.IDENTITY
var _co_cho_cu := false
var _bat_dau_luc := 0.0
var _chay := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Sân nằm trong THẾ GIỚI, không nằm trong lớp phủ — nền đục sẽ che mất nó.
	che_nen = false
	Fusion.register_broadcast_receiver(self)
	# BẮT BUỘC gỡ đăng ký khi ra khỏi cây: minigame được tạo mới và xoá đi sau MỖI ván, không
	# gỡ thì mỗi ván để lại một receiver đã chết mà Fusion vẫn gọi RPC vào.
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

	# CHỈ nhấc nhân vật của máy này. Vị trí người khác do replicator lo — tự đặt hộ họ là
	# đánh nhau với chính cái replicator đó.
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


## Dọn sân VÀ trả người chơi về đúng chỗ cũ. Gọi được nhiều lần.
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


## Giây kể từ lúc ván bắt đầu. Mọi chướng ngại phải là hàm của con số này.
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
	_luat_moi_nhip()
	if con_song(NetManager.local_id()) and _toi_thua():
		xin_chet()
	if not NetManager.is_master():
		return
	if so_con_song() <= 1 or (giay_van > 0.0 and gio() >= giay_van):
		_chot_ket_qua()


# ───────────────────────── lớp con cài ba hàm này ─────────────────────────

## Dựng phần sân riêng của trò. Sân đã nằm trong cây rồi.
func _dung_san() -> void:
	pass


## Chạy mỗi khung hình khi ván đang diễn ra: tính chướng ngại từ `gio()` và `hat_giong`.
func _luat_moi_nhip() -> void:
	pass


## Nhân vật CỦA MÁY NÀY có vừa dính đòn không. Mặc định: rơi khỏi sàn.
##
## Mỗi máy chỉ kiểm nhân vật của chính mình — không trọng tài, không gì để tranh chấp.
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	return p != null and p.global_position.y < san.global_position.y - ROI_KHOI_SAN


# ───────────────────────────── chết và xếp hạng ─────────────────────────────

## Tôi vừa thua. Tự khai, không đợi ai phán.
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


## Lớp con nghe nếu cần (hiệu ứng, đổi luật khi còn ít người).
func _khi_ai_do_chet(_id: int) -> void:
	pass


## CHỈ master. Chốt bảng rồi phát — mọi máy dùng bảng của master, không ai tự sắp.
func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var het := gio()
	var xep: Array = []
	for id in _song:
		xep.append(int(id))
	# Sống lâu hơn đứng trên; bằng nhau thì ai bị master ghi nhận chết SAU đứng trên.
	xep.sort_custom(func(a: int, b: int) -> bool:
		var sa := float(_song[a]) if float(_song[a]) >= 0.0 else het
		var sb := float(_song[b]) if float(_song[b]) >= 0.0 else het
		if not is_equal_approx(sa, sb):
			return sa > sb
		return _thu_tu_chet.find(a) > _thu_tu_chet.find(b))
	Fusion.rpc(_net_xep_hang, xep)


@rpc("any_peer", "call_local")
func _net_xep_hang(xep: Array) -> void:
	_chay = false
	set_process(false)
	xong.emit(xep)


# ───────────────────────────── người chơi ─────────────────────────────

## Chỗ vào sân: rải đều trên một vòng tròn quanh tâm.
##
## Đặt ai cũng vào giữa thì sáu người chồng thành một cục — đã thấy đúng lỗi đó ở bàn party.
func _cho_vao(i: int, tong: int) -> Vector3:
	if tong <= 1:
		return Vector3.ZERO
	var a := TAU * i / float(tong)
	return Vector3(cos(a), 0.0, sin(a)) * ban_kinh_vao_san()


## Bán kính vòng tròn xuất phát. Lớp con có sân to nhỏ khác nhau thì ghi đè.
##
## Sân rộng 23 m nên vòng xuất phát 7 m: đủ tách người ra mà vẫn cách mép 4,5 m.
func ban_kinh_vao_san() -> float:
	return 7.0


## Bật/tắt chế độ sân: camera cố định của sân thay camera người chơi, WASD theo trục thế giới.
## Chỉ đụng `is_mine` — máy này không có camera của người khác.
func _che_do_san(bat: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not p.is_mine:
			continue
		p.che_do_san = bat
		if bat:
			var c := _cam_san()
			if c != null:
				c.make_current()
		elif p.rig != null and is_instance_valid(p.rig):
			p.rig.camera.make_current()


## Tìm theo TÊN xuống cả cây con: sân của mỗi trò bọc `san_dau.tscn` vào một node riêng, nên
## camera nằm ở `SanDau/Cam` chứ không nằm ngay dưới gốc.
func _cam_san() -> Camera3D:
	return san.find_child("Cam", true, false) as Camera3D if san != null else null


func _nguoi(id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == id:
			return p
	return null


func _gio_may() -> float:
	return Time.get_ticks_msec() / 1000.0


# ───────────────────────── luật dùng chung, hàm thuần ─────────────────────────

## Góc của một vật quay mà tốc độ tăng đều từ `toc_dau` lên `toc_cuoi` trong `tang_het` giây.
##
## Đây là TÍCH PHÂN của tốc độ, KHÔNG phải `toc_do(t) * t`. Nhân thẳng thì mỗi lúc tốc độ đổi,
## góc nhảy giật một cái — vật quay dịch chuyển tức thời qua chỗ người chơi đang đứng và hạ họ
## mà không ai kịp thấy gì.
##
## ponytail: giờ chỉ còn Laser Leap gọi — Snowy Spin (người dùng thứ hai) đã bị xoá khỏi trò.
## Để nguyên ở lớp cha vì nó là toán thuần và trò nào có vật quay cũng cần; dồn vào `laser_leap.gd`
## khi chắc là sẽ không có trò quay nào nữa.
static func goc_quay(pha: float, t: float, toc_dau: float, toc_cuoi: float, tang_het: float) -> float:
	var k := minf(t, tang_het)
	var quet := toc_dau * k + (toc_cuoi - toc_dau) * k * k / (2.0 * tang_het)
	if t > tang_het:
		quet += toc_cuoi * (t - tang_het)
	return pha + quet
