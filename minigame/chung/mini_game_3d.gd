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

## HAI đòn tay không — trò nào cần thì bật `co_danh` trong `.tscn`. Lớp con nghe `_khi_bi_danh()`
## để thêm luật riêng (rơi vương miện...).
##
##   - ĐÁNH (CHUỘT TRÁI hoặc F, action `danh`): tầm NGẮN, nạn nhân bị CHOÁNG — đứng sững,
##     không đi, không nhảy — nhưng không bị hất. Dùng để giữ chân người ta tại chỗ.
##   - CHƯỞNG (CHUỘT PHẢI hoặc G, action `chuong`): tầm xa hơn, HẤT nạn nhân văng ra, không
##     choáng. Nghỉ lâu hơn.
##
## Tầm tính từ TÂM người đánh tới TÂM nạn nhân. Hai thân người (bán kính 0,4) chạm nhau đã cách
## 0,8 m, nên tầm đánh 1,7 m là "sát người, chìa tay ra là tới"; chưởng 2,8 m là "cách một bước".
const NUT_DANH := "danh"
const NUT_CHUONG := "chuong"
enum { DON_DANH, DON_CHUONG }
const TAM_DON := [1.7, 2.8]
## Nạn nhân phải nằm PHÍA TRƯỚC: tích vô hướng giữa hướng mặt và hướng tới họ lớn hơn số này.
## Đánh 0,2 (≈ nón 155°, đứng sát thì hơi lệch mặt vẫn trúng), chưởng 0,5 (nón 120°, phải nhắm).
const GOC_DON := [0.2, 0.5]
## Nghỉ giữa hai đòn CÙNG LOẠI, giây.
const NGHI_DON := [0.55, 1.1]
## Choáng bao lâu khi trúng ĐÁNH.
const GIAY_CHOANG := 0.9
## Trúng CHƯỞNG bị hất mạnh cỡ nào — ngang và dốc lên.
const CHUONG_NGANG := 10.0
const CHUONG_LEN := 3.5
## Nhân vật trong sân to hơn ở phòng chờ chừng này lần — CHỈ hình, không đổi thân va chạm, nên
## không đổi luật trò nào. Camera sân đứng xa hơn camera người chơi nhiều, nhân vật cỡ thường
## nhìn như hạt gạo.
const TO_HON := 1.3
## Sống tới cuối ván (hoặc còn sống lúc hết giờ) được cộng thêm chừng này điểm.
const THUONG_SONG_CUOI := 10.0

## Scene sân của trò này. Lớp con trỏ export này sang scene của nó trong `.tscn`.
@export var san_scene: PackedScene = null
## Ván dài bao lâu. 0 = không giới hạn, chạy tới khi còn một người.
@export var giay_van := 60.0
## Bật hai đòn tay không (xem `NUT_DANH` / `NUT_CHUONG`).
@export var co_danh := false

var san: Node3D = null
var hat_giong := 0
## player_id -> giây sống được. Người còn sống mang -1 cho tới lúc chết.
var _song: Dictionary = {}
## player_id theo ĐÚNG thứ tự master nhận tin chết. Dùng để phá hoà.
var _thu_tu_chet: Array = []
## Chỗ đứng trước khi lên sân, để còn đường về. Xem ghi chú đầu file.
var _cho_cu := Transform3D.IDENTITY
var _co_cho_cu := false
## `khoa_di_chuyen` của nhân vật máy này trước khi vào sân. Xem `_che_do_san()`.
var _khoa_cu := false
var _bat_dau_luc := 0.0
var _chay := false
var _rng := RandomNumberGenerator.new()
## `gio()` lúc ra đòn gần nhất, theo loại đòn.
var _don_luc := [-99.0, -99.0]
## Nhân vật CỦA MÁY NÀY bị choáng tới `gio()` này.
var _choang_toi := -99.0
var _dang_choang := false
## Đã chốt bảng — điểm sinh tồn cộng thưởng sống cuối từ lúc này.
var _da_chot := false
var _het_luc := 0.0


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
	if co_danh:
		_nhip_choang()
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


# ───────────────────────────── đánh tay không ─────────────────────────────

## Đọc ở `_input`, không ở `_unhandled_input`: trong minigame chuột đang thả tự do, và cú bấm
## chuột trái rơi vào HUD/chat sẽ bị GUI ăn mất trước khi tới `_unhandled_input` — cùng lý do
## súng ở bàn party (`PhaBanCo._input`) đọc chuột ở đây.
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


## Người gần nhất trong tầm của đòn `loai`, phía trước mặt `toi`, còn sống. Null nếu trượt.
##
## Máy NGƯỜI ĐÁNH phán trúng hay trượt theo vị trí replicator đã gửi — trễ vài chục ms, chấp
## nhận được cho một trò party. Có trọng tài thì phải đợi một vòng gói tin mới thấy đòn ăn.
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


## Một gói cho một cú trúng. CHỈ máy của nạn nhân tự áp hậu quả lên mình — đẩy hộ người khác là
## đánh nhau với replicator đang gửi vị trí của họ.
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


## Chạy trên MỌI máy khi có cú trúng. Lớp con thêm luật riêng ở đây.
func _khi_bi_danh(_ke_danh: int, _nan: int, _loai: int) -> void:
	pass


## Nhân vật của máy này đang choáng.
func dang_choang() -> bool:
	return gio() < _choang_toi


## Choáng = khoá WASD + nhảy của chính mình. Chỉ đụng khoá lúc VÀO và RA khỏi choáng, để trò nào
## tự khoá vì luật riêng (chưa có trò có đòn nào làm vậy) không bị gỡ khoá mỗi khung hình.
func _nhip_choang() -> void:
	var choang := dang_choang()
	if choang == _dang_choang:
		return
	_dang_choang = choang
	var p := _nguoi(NetManager.local_id())
	if p != null:
		p.khoa_di_chuyen = choang
		p.velocity = Vector3.ZERO


## Kẹp nhân vật CỦA MÁY NÀY trong bán kính `r` quanh tâm sân — cho trò không có đường chết vì
## rơi, để cú đánh không hất ai xuống vực. Chỉ `is_mine`: kéo người khác là đánh nhau với
## replicator.
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
	if not _da_chot:
		_da_chot = true
		_het_luc = gio()
	xong.emit(xep)


# ───────────────────────── ô điểm: mặc định là điểm SINH TỒN ─────────────────────────

## Trò sinh tồn: mỗi giây còn sống là một điểm; còn sống lúc chốt bảng thì cộng
## `THUONG_SONG_CUOI`. Mọi máy tính ra cùng một con số vì giây chết đi qua `_net_chet`.
##
## Trò tích điểm (Crown, Word Wars...) ghi đè hàm này bằng con số riêng của mình.
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
		# Phóng to HÌNH của mọi người trên máy này (việc cục bộ, không replicate). Xem `TO_HON`.
		p.model_root.scale = Vector3.ONE * (TO_HON if bat else 1.0)
		if not p.is_mine:
			continue
		p.che_do_san = bat
		# Bàn cờ khoá WASD (`PhaBanCo._che_do_ban_co`) và không ai mở khoá khi minigame chen vào
		# — nhân vật đứng trơ trên sân. Mở lúc vào, trả lại đúng như cũ lúc ra (bàn vẫn đang mở).
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
static func goc_quay(pha: float, t: float, toc_dau: float, toc_cuoi: float,
		tang_het: float) -> float:
	var k := minf(t, tang_het)
	var quet := toc_dau * k + (toc_cuoi - toc_dau) * k * k / (2.0 * tang_het)
	if t > tang_het:
		quet += toc_cuoi * (t - tang_het)
	return pha + quet
