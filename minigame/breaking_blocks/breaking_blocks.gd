extends MiniGame3D

## BREAKING BLOCKS — đứng lâu trên ô nào thì ô đó nứt rồi vỡ; còn một người là xong.
## Vết nứt thuộc về ô (không tự lành). Mọi máy tự tính vết nứt; master phán ô vỡ rồi phát đi.

enum { LANH, NHE, NANG, SAP_VO }

const CANH := 8
## Khớp `o_vo.tscn`.
const RONG_O := 2.8
## Khe giữa hai ô (nhảy chắc tới).
const KHE := 1.2
const BUOC := RONG_O + KHE

## Một người đứng yên thì ô vỡ sau bao lâu (đầu ván).
const GIAY_VO_MOT_NGUOI := 3.0
## Mỗi người thêm trên cùng ô cộng chừng này phần tốc hư.
const THEM_MOI_NGUOI := 0.75
## Ô vỡ nằm trống bao lâu mới mọc lại (đầu ván; cuối ván dãn ra theo `kho()`).
const GIAY_MOC_LAI := 4.5

## Cuối ván hư nhanh gấp mấy lần (cũng là hệ số dãn thời gian mọc lại).
const KHO_CUOI := 4.0
## Khó hết cỡ sau chừng này giây.
const GIAY_KHO_HET := 30.0

## Mốc trạng thái trên thanh hư 0..1.
const MOC_NHE := 0.25
const MOC_NANG := 0.5
const MOC_SAP_VO := 0.7

## Ô SẮP VỠ phải chờ ít nhất chừng này giây mới vỡ (luôn kịp đọc cảnh báo).
const GIAY_BAO_TOI_THIEU := 0.6

## Biên độ rung khi sắp vỡ (m).
const RUNG := 0.045
## Trong khoảng cao này trên mặt ô thì tính là đang đứng (kể cả đang nhảy).
const CAO_TINH := 3.0

@export var o_scene: PackedScene = null
## Hai đầu dải màu ô lành → sắp vỡ.
@export var mat_lanh: StandardMaterial3D = null
@export var mat_bao: StandardMaterial3D = null

var _o: Array[OSan] = []
## Tâm từng ô (toạ độ trong sân).
var _tam: PackedVector3Array = PackedVector3Array()
## Mức hư từng ô 0..1 (mọi máy tự tính).
var _hu: PackedFloat32Array = PackedFloat32Array()
## Ô còn hay đã vỡ (master phán).
var _con: Array[bool] = []
## Chỉ master: lúc ô vỡ, để biết khi nào mọc lại.
var _vo_luc: PackedFloat32Array = PackedFloat32Array()
## Lúc ô vào SẮP VỠ; -1 = chưa.
var _bao_tu: PackedFloat32Array = PackedFloat32Array()
## Vật liệu bốn trạng thái.
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
	# Dựng lưới theo `CANH` (đổi một chỗ là đổi cả lưới).
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
		# Vắng người thì vết nứt giữ nguyên.
		if n > 0:
			_hu[i] = minf(_hu[i] + toc_hu(n, t) * d, 1.0)
		if trang_thai(_hu[i]) == SAP_VO:
			if _bao_tu[i] < 0.0:
				_bao_tu[i] = t
		else:
			_bao_tu[i] = -1.0
		_ve_o(i)

	if NetManager.is_master():
		_master_phan(t)


## Số người đang đứng trên từng ô (người đã chết không tính).
func _dem_nguoi() -> Dictionary:
	var dong := {}
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not con_song(p.player_id()):
			continue
		var i := _o_duoi_chan(p.global_position)
		if i >= 0:
			dong[i] = int(dong.get(i, 0)) + 1
	return dong


## CHỈ master: ô đủ hư thì vỡ, vỡ đủ lâu thì mọc lại; chỉ phát khi có đổi.
func _master_phan(t: float) -> void:
	# Array thường: Fusion không gửi được PackedInt32Array.
	var vo: Array = []
	var moc: Array = []
	for i in _o.size():
		if _con[i]:
			# Đủ hư và đã báo đủ lâu.
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


func _ve_o(i: int) -> void:
	var tt := trang_thai(_hu[i])
	_o[i].son(_mau[tt])
	if tt == SAP_VO:
		_o[i].position = _tam[i] + Vector3(
				randf_range(-RUNG, RUNG), randf_range(-RUNG, RUNG), randf_range(-RUNG, RUNG))
	else:
		_o[i].position = _tam[i]


# ─── chỗ vào sân ───

## Rải người quanh sân rồi kéo về tâm ô gần nhất (không rơi vào khe).
func _cho_vao(i: int, tong: int) -> Vector3:
	var o := _o_gan_nhat(super(i, tong))
	return Vector3(_toa_do(o.y), 1.0, _toa_do(o.x))


func ban_kinh_vao_san() -> float:
	return BUOC * 2.0


## Ô gần nhất dạng (hàng, cột).
func _o_gan_nhat(v: Vector3) -> Vector2i:
	return Vector2i(
			clampi(roundi(v.z / BUOC + (CANH - 1) * 0.5), 0, CANH - 1),
			clampi(roundi(v.x / BUOC + (CANH - 1) * 0.5), 0, CANH - 1))


## Ô dưới chân; -1 = trên khe, ngoài sân hoặc ô đã vỡ.
func _o_duoi_chan(v: Vector3) -> int:
	if san == null:
		return -1
	var l := v - san.global_position
	if l.y < -0.5 or l.y > CAO_TINH:
		return -1
	var o := _o_gan_nhat(l)
	# Phải đứng trong mặt ô, không phải trong khe.
	if absf(l.x - _toa_do(o.y)) > RONG_O * 0.5 or absf(l.z - _toa_do(o.x)) > RONG_O * 0.5:
		return -1
	var i := o.x * CANH + o.y
	return i if _con[i] else -1


# ─── luật: hàm thuần ───

static func _toa_do(k: int) -> float:
	return (float(k) - (CANH - 1) * 0.5) * BUOC


## Hư nhanh gấp mấy lần so với đầu ván.
static func kho(t: float) -> float:
	return lerpf(1.0, KHO_CUOI, clampf(t / GIAY_KHO_HET, 0.0, 1.0))


static func giay_moc_lai(t: float) -> float:
	return GIAY_MOC_LAI * kho(t)


## Phần thanh hư mỗi giây với `n` người đứng.
static func toc_hu(n: int, t: float) -> float:
	if n <= 0:
		return 0.0
	return (1.0 + THEM_MOI_NGUOI * float(n - 1)) * kho(t) / GIAY_VO_MOT_NGUOI


static func trang_thai(hu: float) -> int:
	if hu >= MOC_SAP_VO:
		return SAP_VO
	if hu >= MOC_NANG:
		return NANG
	if hu >= MOC_NHE:
		return NHE
	return LANH


## Bốn vật liệu pha dần từ `mat_lanh` sang `mat_bao`.
func _thang_mau() -> Array[StandardMaterial3D]:
	var lanh := mat_lanh
	var bao := mat_bao
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
