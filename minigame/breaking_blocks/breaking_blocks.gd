extends MiniGame3D

## BREAKING BLOCKS — đứng lâu trên ô nào thì ô đó nứt, nứt đủ thì vỡ. Còn một người là xong.
##
## Khuôn T2. **Không có đòn, không có dash, không có chướng ngại** — sàn CHÍNH LÀ trò chơi. Cái
## người chơi phải nghĩ suốt ván chỉ có một câu: "không đứng đây mãi được."
##
## ## Hư thuộc về Ô, không thuộc về NGƯỜI
##
## `_hu[i]` nằm trên ô thứ `i`, không nằm trên người. Rời ô (kể cả NHẢY lên) thì vết nứt **ở lại
## nguyên** — ô đang SẮP VỠ vẫn sắp vỡ, và **không bao giờ tự lành**. Người sau bước vào gặp đúng
## vết nứt đó. Ô chỉ về LÀNH khi đã vỡ rồi mọc lại.
##
## Hệ quả: sàn ăn mòn dần theo cả ván, ai cũng đang ăn dần chỗ đứng an toàn của người khác, và hai
## người chung một ô thì ô đó hư nhanh hơn hẳn.
##
## (Có một bản cho ô lành ngay khi vắng người — nhảy khỏi ô là ô về bình thường, hiểu nhầm yêu
## cầu. Bản đó cũng không chơi được: mô phỏng 4 người biết né thì 60 giây không vỡ ô nào.)
##
## ## Vì sao bản này thay hẳn bản cũ
##
## Bản đầu cho ô tan theo ĐỒNG HỒ: `trang_thai_o(pha, gio(), chu_ky)` — hàm thuần, 0 gói tin,
## rất gọn. Nhưng nó không phải Breaking Blocks: ô tan dù có ai đứng hay không, nên người chơi
## chỉ đang đọc một cái đồng hồ vô hình chứ không gây ra điều gì. Đứng yên cũng chết, chạy loạn
## cũng chết, và không quyết định nào của người chơi đổi được kết quả.
##
## ## Ai phán ô vỡ
##
## Vết nứt thì **mọi máy tự tính** từ vị trí mà replicator đã gửi sẵn — 0 gói tin cho toàn bộ
## phần hình ảnh. Nhưng lúc VỠ thì **master phán rồi phát đi**, vì vỡ là thứ giết người: hai máy
## lệch nhau vài khung hình mà một bên ô đã mất thì có người chết oan.
##
## Gói chỉ bay khi có ô ĐỔI trạng thái, không bay mỗi khung hình — vài gói một giây, không phải
## sáu mươi.
##
## ## Cảnh báo phải đọc được
##
## Thứ tự LÀNH → NỨT NHẸ → NỨT NẶNG → SẮP VỠ → VỠ là bắt buộc, không được rút gọn. Cửa sổ "sắp
## vỡ" rộng 30% thanh hư, nên kể cả cuối ván (hư nhanh gấp `KHO_CUOI`, lại thêm người chung ô)
## vẫn còn hơn nửa giây để kịp nhảy đi. `kiem_luat.gd` quét mọi tổ hợp (số người × độ khó) và
## chặn bản nào phá điều đó.

enum { LANH, NHE, NANG, SAP_VO }

## Lưới vuông bao nhiêu ô mỗi cạnh.
const CANH := 8
## Bề ngang một ô, mét. Khớp `o_vo.tscn`.
const RONG_O := 2.8
## Khe giữa hai ô. Người chơi nhảy cao 1,2 m nên bay 0,69 s, tầm ngang ~4,2 m, lại còn nhảy đôi
## — 1,2 m là nhảy chắc tới, không phải nhảy chính xác từng centimet.
const KHE := 1.2
## Tâm hai ô kề nhau cách nhau bao xa.
const BUOC := RONG_O + KHE

## Một người đứng yên thì ô vỡ sau bao lâu, lúc ĐẦU ván. Cuối ván nhanh gấp `KHO_CUOI`.
const GIAY_VO_MOT_NGUOI := 3.0
## Người thứ hai trở đi, mỗi người cộng thêm bao nhiêu phần tốc hư. Đây là chỗ "chung ô thì
## nguy hiểm nhanh hơn" — không cần đòn nào mà vẫn tranh nhau chỗ đứng.
const THEM_MOI_NGUOI := 0.75
## Ô vỡ rồi nằm trống bao lâu mới mọc lại, lúc ĐẦU ván. Không cho mọc lại thì 64 ô bay hết trong
## nửa phút và ván kết thúc vì hết sàn chứ không vì ai giỏi hơn.
##
## Cuối ván con số này DÃN ra theo `kho()`: ô vỡ nằm trống lâu hơn, sàn teo dần, và đó là cách
## "cuối ván ít chỗ an toàn" xảy ra. Để nguyên một nhịp thì đo được: 4 người chạy 60 giây chỉ vỡ
## 10 ô và sàn không bao giờ tụt dưới 61/64 — cả ván không ai chết, luôn hết giờ.
const GIAY_MOC_LAI := 4.5

## Cuối ván hư nhanh gấp mấy lần đầu ván. Cũng là hệ số dãn của thời gian mọc lại — một núm cho
## cả hai.
const KHO_CUOI := 4.0
## Khó hết cỡ sau chừng này giây. Phải NGẮN hơn `giay_van` (60) kha khá, không thì ván hết trước
## lúc độ khó kịp cắn và trận nào cũng kết thúc bằng tiếng còi.
const GIAY_KHO_HET := 30.0

## Mốc chuyển trạng thái trên thanh hư 0..1.
const MOC_NHE := 0.25
const MOC_NANG := 0.5
const MOC_SAP_VO := 0.7

## Ô đã vào trạng thái SẮP VỠ thì phải CHỜ ít nhất chừng này giây mới được vỡ, bất kể thanh hư
## đã đầy từ lúc nào.
##
## Không có sàn này thì công bằng vỡ ở chỗ đông người: ba người chung một ô lúc cuối ván làm
## tốc hư lên 1,09/giây, cửa sổ cảnh báo co còn 0,27 giây — ô vỡ gần như cùng lúc với lúc nó
## chuyển màu, không ai kịp đọc. Kẹp ở đây là cách duy nhất chặn được mọi tổ hợp (số người) ×
## (độ khó) trong một dòng, thay vì đi dò lại ba hằng số mỗi lần đổi một cái.
const GIAY_BAO_TOI_THIEU := 0.6

## Ô sắp vỡ thì rung. Biên độ, mét.
const RUNG := 0.045
## Người chơi phải nằm trong khoảng này phía trên mặt ô mới tính là ĐANG ĐỨNG trên nó. Cao hơn
## đỉnh NHẢY ĐÔI (~2,4 m): nhảy tại chỗ vẫn tính là đứng, không thì nhảy liên tục là ô ngừng hư.
const CAO_TINH := 3.0

@export var o_scene: PackedScene = null

var _o: Array[OSan] = []
## Tâm từng ô, toạ độ cục bộ trong `san`. Giữ riêng để còn chỗ trả về sau khi rung.
var _tam: PackedVector3Array = PackedVector3Array()
## Mức hư từng ô, 0..1. Mọi máy tự tính, dùng cho HÌNH ẢNH.
var _hu: PackedFloat32Array = PackedFloat32Array()
## Ô còn hay đã vỡ. Do MASTER phán, phát qua `_net_doi`.
var _con: Array[bool] = []
## `gio()` lúc ô vỡ. Chỉ master dùng, để biết khi nào cho mọc lại.
var _vo_luc: PackedFloat32Array = PackedFloat32Array()
## `gio()` lúc ô bước vào SẮP VỠ; -1 nếu chưa. Dùng để ép đủ `GIAY_BAO_TOI_THIEU`.
var _bao_tu: PackedFloat32Array = PackedFloat32Array()
## Vật liệu cho bốn trạng thái, pha trong `_ready()` từ hai vật liệu sẵn có.
var _mau: Array[StandardMaterial3D] = []


func _ready() -> void:
	super()
	ten = "BREAKING BLOCKS"
	luat = "WASD chạy · Space nhảy · đứng lâu là sàn nứt rồi vỡ · đừng rơi"
	_mau = _thang_mau()


func _dung_san() -> void:
	_o.clear()
	var tong := CANH * CANH
	_tam.resize(tong)
	_hu.resize(tong)
	_vo_luc.resize(tong)
	_bao_tu.resize(tong)
	_con.resize(tong)
	if o_scene == null:
		push_error("BreakingBlocks: thieu o_scene (o_vo.tscn)")
		return
	# Dựng lưới bằng code chứ không bày 64 node trong `.tscn`: đổi `CANH` một chỗ là xong, và
	# không ai phải sửa 64 transform bằng tay khi muốn thử lưới khác.
	for r in CANH:
		for c in CANH:
			var i := r * CANH + c
			var o := o_scene.instantiate() as OSan
			san.add_child(o)
			_tam[i] = Vector3(_toa_do(c), 0.0, _toa_do(r))
			o.position = _tam[i]
			_o.append(o)
			_hu[i] = 0.0
			_vo_luc[i] = 0.0
			_bao_tu[i] = -1.0
			_con[i] = true
			o.dat(true)
			o.son(_mau[LANH])


func _luat_moi_nhip() -> void:
	var d := get_process_delta_time()
	var t := gio()
	var dong := _dem_nguoi()

	for i in _o.size():
		if not _con[i]:
			continue
		var n := int(dong.get(i, 0))
		# Vắng người thì vết nứt GIỮ NGUYÊN — xem ghi chú đầu file.
		if n > 0:
			_hu[i] = minf(_hu[i] + toc_hu(n, t) * d, 1.0)
		# Mốc bắt đầu báo: đặt khi vừa vào SẮP VỠ, xoá khi lành lại xuống dưới mốc đó.
		if trang_thai(_hu[i]) == SAP_VO:
			if _bao_tu[i] < 0.0:
				_bao_tu[i] = t
		else:
			_bao_tu[i] = -1.0
		_ve_o(i)

	if NetManager.is_master():
		_master_phan(t)


## Ô nào đang có bao nhiêu người ĐỨNG trên.
##
## Người đã chết không tính: họ không được ăn tiếp chỗ đứng của người còn sống. (Họ cũng đang
## rơi ở đâu đó dưới sàn, nhưng dựa vào điều đó là dựa vào một thứ tình cờ.)
func _dem_nguoi() -> Dictionary:
	var dong := {}
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not con_song(p.player_id()):
			continue
		var i := _o_duoi_chan(p.global_position)
		if i >= 0:
			dong[i] = int(dong.get(i, 0)) + 1
	return dong


## CHỈ master. Ô nào đủ hư thì vỡ, ô nào vỡ đủ lâu thì mọc lại. Chỉ phát khi CÓ đổi.
func _master_phan(t: float) -> void:
	# Array thường, KHÔNG PackedInt32Array: Fusion không tuần tự hoá được kiểu packed (type 30),
	# máy nhận được NIL và `_net_doi` gãy — ô không bao giờ vỡ ở máy khác.
	var vo: Array = []
	var moc: Array = []
	for i in _o.size():
		if _con[i]:
			# Đủ hư VÀ đã báo đủ lâu. Thiếu điều kiện thứ hai là vỡ không kịp báo.
			if _hu[i] >= 1.0 and _bao_tu[i] >= 0.0 and t - _bao_tu[i] >= GIAY_BAO_TOI_THIEU:
				vo.append(i)
		elif t - _vo_luc[i] >= giay_moc_lai(t):
			moc.append(i)
	if not vo.is_empty() or not moc.is_empty():
		Fusion.rpc(_net_doi, vo, moc, t)


@rpc("any_peer", "call_local")
func _net_doi(vo: Array, moc: Array, t: float) -> void:
	for v in vo:
		var i := int(v)
		if i < 0 or i >= _o.size() or not _con[i]:
			continue
		_con[i] = false
		_vo_luc[i] = t
		_hu[i] = 1.0
		_bao_tu[i] = -1.0
		_o[i].position = _tam[i]
		_o[i].dat(false)
	for v in moc:
		var i := int(v)
		if i < 0 or i >= _o.size() or _con[i]:
			continue
		_con[i] = true
		_hu[i] = 0.0
		_bao_tu[i] = -1.0
		_o[i].position = _tam[i]
		_o[i].dat(true)
		_o[i].son(_mau[LANH])


## Sơn ô theo mức hư, và rung nếu sắp vỡ.
func _ve_o(i: int) -> void:
	var tt := trang_thai(_hu[i])
	_o[i].son(_mau[tt])
	if tt == SAP_VO:
		_o[i].position = _tam[i] + Vector3(
				randf_range(-RUNG, RUNG), randf_range(-RUNG, RUNG), randf_range(-RUNG, RUNG))
	else:
		_o[i].position = _tam[i]


# ───────────────────────────── chỗ vào sân ─────────────────────────────

## Rải người quanh sân, cách bờ hai ô. Dùng vòng tròn của lớp cha rồi KÉO VỀ TÂM Ô gần nhất —
## không kéo thì có người sinh ra đúng cái khe giữa hai ô và rơi trước khi ván kịp bắt đầu.
func _cho_vao(i: int, tong: int) -> Vector3:
	var o := _o_gan_nhat(super(i, tong))
	return Vector3(_toa_do(o.y), 1.0, _toa_do(o.x))


## Bán kính vòng sinh. Lưới 8 ô nên bờ ở ~14 m; 8 m là vào hẳn trong, cách bờ hai ô.
func ban_kinh_vao_san() -> float:
	return BUOC * 2.0


## Ô gần điểm `v` nhất, dưới dạng `(hang, cot)`.
func _o_gan_nhat(v: Vector3) -> Vector2i:
	return Vector2i(
			clampi(roundi(v.z / BUOC + (CANH - 1) * 0.5), 0, CANH - 1),
			clampi(roundi(v.x / BUOC + (CANH - 1) * 0.5), 0, CANH - 1))


## Ô nào ở ngay dưới chân người này; -1 nếu đang trên khe, ngoài sân, hay trên ô đã vỡ.
##
## Tính thẳng bằng chỉ số lưới chứ không quét 64 ô: mỗi khung hình, mỗi người, một phép chia.
func _o_duoi_chan(v: Vector3) -> int:
	if san == null:
		return -1
	var l := v - san.global_position
	if l.y < -0.5 or l.y > CAO_TINH:
		return -1
	var o := _o_gan_nhat(l)
	# Phải trong MẶT ô, không phải trong khe. Thiếu phép này thì đứng giữa khe cũng làm hư ô
	# bên cạnh, và người chơi không hiểu vì sao ô mình không đứng lại nứt.
	if absf(l.x - _toa_do(o.y)) > RONG_O * 0.5 or absf(l.z - _toa_do(o.x)) > RONG_O * 0.5:
		return -1
	var i := o.x * CANH + o.y
	return i if _con[i] else -1


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Toạ độ tâm của ô thứ `k` trên một cạnh, lấy giữa lưới làm gốc.
static func _toa_do(k: int) -> float:
	return (float(k) - (CANH - 1) * 0.5) * BUOC


## Hư nhanh gấp mấy lần so với đầu ván. Đầu ván chậm cho người chơi học luật, cuối ván nhanh để
## ván tự kết thúc kể cả khi ai cũng giỏi.
static func kho(t: float) -> float:
	return lerpf(1.0, KHO_CUOI, clampf(t / GIAY_KHO_HET, 0.0, 1.0))


## Ô vỡ nằm trống bao lâu mới mọc lại, tại giây `t`. Dãn theo độ khó: cuối ván sàn teo thật.
static func giay_moc_lai(t: float) -> float:
	return GIAY_MOC_LAI * kho(t)


## Tốc hư của một ô đang có `n` người đứng, tại giây `t`. Đơn vị: phần thanh hư mỗi giây.
static func toc_hu(n: int, t: float) -> float:
	if n <= 0:
		return 0.0
	return (1.0 + THEM_MOI_NGUOI * float(n - 1)) * kho(t) / GIAY_VO_MOT_NGUOI


## Trạng thái hiện trên mặt ô theo mức hư.
static func trang_thai(hu: float) -> int:
	if hu >= MOC_SAP_VO:
		return SAP_VO
	if hu >= MOC_NANG:
		return NANG
	if hu >= MOC_NHE:
		return NHE
	return LANH


## Bốn vật liệu LÀNH → SẮP VỠ, pha từ `mat_san_thuong` sang `mat_san_canh_bao`.
##
## Pha bằng code chứ không thêm hai file `.tres`: cả bốn mức là MỘT dải màu, tách ra bốn file
## thì sửa dải phải mở bốn chỗ và rất dễ lệch nhau.
static func _thang_mau() -> Array[StandardMaterial3D]:
	var lanh := load("res://materials/mat_san_thuong.tres") as StandardMaterial3D
	var bao := load("res://materials/mat_san_canh_bao.tres") as StandardMaterial3D
	var ds: Array[StandardMaterial3D] = []
	for k in 4:
		var m := lanh.duplicate() as StandardMaterial3D
		var u := float(k) / 3.0
		m.albedo_color = lanh.albedo_color.lerp(bao.albedo_color, u)
		m.emission = m.albedo_color
		m.emission_energy_multiplier = lerpf(
				lanh.emission_energy_multiplier, bao.emission_energy_multiplier, u)
		ds.append(m)
	return ds
