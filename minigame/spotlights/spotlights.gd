extends MiniGame3D

## SEARING SPOTLIGHTS — sàn sáng/tối theo chu kỳ, đèn rọi quét sàn; đứng trong đèn thì mất máu.
## Không chết vì rơi (bị kẹp trong sàn). Đèn và độ sáng là hàm của `gio()` — 0 gói tin.

## Máu mất mỗi giây trong đèn (máu đầy 100).
const MAT_MAU_MOI_GIAY := 40.0

## Biên độ quỹ đạo Lissajous của đèn (giữ vệt sáng trong sàn và đèn chậm hơn người chạy).
const TAM_QUET := 6.2

## Bốn chặng của một chu kỳ (giây).
const GIAY_SANG := 4.0
const GIAY_MO := 1.6
const GIAY_TOI := 6.5
const GIAY_SANG_LAI := 1.4
const CHU_KY := GIAY_SANG + GIAY_MO + GIAY_TOI + GIAY_SANG_LAI

## Số đèn chu kỳ đầu và trần.
const DEN_DAU := 3
const DEN_TOI_DA := 8

## Kẹp người chơi trong bán kính này.
const BAN_KINH_GIU := 11.0

## Độ sáng đèn trời lúc sáng hẳn.
const DEN_TROI_SANG := 1.1

## Môi trường sàn tối/sáng — luôn duplicate trước khi sửa.
@export var env_toi: Environment = null
@export var env_sang: Environment = null

var _den: Array[Node3D] = []

## Vùng sáng của từng đèn, cùng thứ tự `_den`.
var _vung: Array[Area3D] = []
var _pha: PackedFloat32Array = PackedFloat32Array()
var _nhip: PackedFloat32Array = PackedFloat32Array()
var _troi: DirectionalLight3D = null
var _env: Environment = null
var _troi_toi := 0.0

## Viền sàn tắt dần theo độ sáng.
var _vien: GeometryInstance3D = null

## Mặt trời phòng chờ/bàn cờ: đèn hướng không có tầm nên rọi cả sân trên cao — tắt suốt ván.
var _mat_troi: Array[DirectionalLight3D] = []

@onready var _thanh: ThanhMau = $ThanhMau


func _ready() -> void:
	super()
	ten = "SEARING SPOTLIGHTS"
	luat = "WASD chạy · nhớ chỗ mình lúc còn sáng · tránh vùng sáng khi tối"
	giay_van = 75.0


func _dung_san() -> void:
	_den.assign(san.find_children("Den*", "Node3D", false, false))
	_vung.clear()
	for d in _den:
		_vung.append(d.get_node("Vung") as Area3D)
	_vien = san.get_node_or_null("VienSan") as GeometryInstance3D
	_pha.resize(_den.size())
	_nhip.resize(_den.size())
	for i in _den.size():
		_pha[i] = _rng.randf() * TAU
		# Nhịp lệch nhau để hai đèn không đi song song mãi.
		_nhip[i] = _rng.randf_range(0.28, 0.52)
	_thanh.mo()
	if _den.is_empty():
		push_error("Spotlights: san khong co node ten Den*")
		return

	# Duplicate môi trường, kẻo sửa thẳng file .tres trên đĩa.
	var cam := _cam_san()
	if cam != null:
		_env = env_toi.duplicate() as Environment
		cam.environment = _env
	_troi = san.find_child("Den", true, false) as DirectionalLight3D
	if _troi != null:
		_troi_toi = _troi.light_energy
	_mat_troi.clear()
	for l: DirectionalLight3D in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		if l.visible and not san.is_ancestor_of(l) and l.get_world_3d() == san.get_world_3d():
			l.visible = false
			_mat_troi.append(l)
	# Ván mở ở chặng sáng — đặt độ sáng ngay khung đầu.
	_dat_sang(1.0)


func dung_som() -> void:
	_thanh.dong()
	for l in _mat_troi:
		if is_instance_valid(l):
			l.visible = true
	_mat_troi.clear()
	for p: Player in get_tree().get_nodes_in_group("players"):
		p.model_root.visible = true
		p.name_tag.visible = not p.is_mine
	super()


## Hết máu là bị loại: biến khỏi sân, đứng yên tới hết ván.
func _khi_ai_do_chet(id: int) -> void:
	var p := _nguoi(id)
	if p == null:
		return
	p.model_root.visible = false
	if id == NetManager.local_id():
		p.khoa_di_chuyen = true


func _luat_moi_nhip() -> void:
	var t := gio()
	_dat_sang(do_sang(t))
	var n := so_den(t)
	for i in _den.size():
		var v := cho_den(_pha[i], _nhip[i], t)
		_den[i].position = Vector3(v.x, _den[i].position.y, v.y)
		# Đèn chưa tới lượt thì tắt hẳn.
		_den[i].visible = i < n
	# Kẹp cả người đã hết máu.
	giu_trong_san(BAN_KINH_GIU)
	if con_song(NetManager.local_id()):
		_an_mau(n)


## Trừ máu nếu đứng trong vùng sáng của đèn đang bật.
func _an_mau(n: int) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	for i in mini(n, _vung.size()):
		if _vung[i] != null and _vung[i].overlaps_body(p):
			_thanh.tru(MAT_MAU_MOI_GIAY, get_process_delta_time())
			return


## Độ sáng chung: 0 = tối hẳn (đen), 1 = sáng hẳn. Nội suy giữa `env_toi` và `env_sang`.
func _dat_sang(s: float) -> void:
	if _troi != null:
		_troi.light_energy = lerpf(_troi_toi, DEN_TROI_SANG, s)
	if _vien != null:
		_vien.transparency = 1.0 - s
	_hien_ten(s > 0.5)
	if _env == null:
		return
	_env.ambient_light_energy = lerpf(
			env_toi.ambient_light_energy, env_sang.ambient_light_energy, s)
	_env.ambient_light_color = env_toi.ambient_light_color.lerp(
			env_sang.ambient_light_color, s)
	_env.background_color = env_toi.background_color.lerp(env_sang.background_color, s)


## Ẩn tên người khác lúc tối, và tên người đã bị loại.
func _hien_ten(hien: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not p.is_mine:
			p.name_tag.visible = hien and con_song(p.player_id())


## Không gọi `super()`: hết máu là đường thua duy nhất.
func _toi_thua() -> bool:
	return _thanh.het()


# ─── luật: hàm thuần ───


## Vị trí đèn tại giây `t` (Lissajous).
static func cho_den(pha: float, nhip: float, t: float) -> Vector2:
	return Vector2(
			sin(t * nhip + pha) * TAM_QUET,
			sin(t * nhip * 1.37 + pha * 2.0) * TAM_QUET)


static func chu_ky_thu(t: float) -> int:
	return int(t / CHU_KY)


## Số đèn bật tại giây `t` (thêm một mỗi chu kỳ).
static func so_den(t: float) -> int:
	return mini(DEN_DAU + chu_ky_thu(t), DEN_TOI_DA)


## 1 = sáng hẳn, 0 = tối hẳn.
static func do_sang(t: float) -> float:
	var u := fposmod(t, CHU_KY)
	if u < GIAY_SANG:
		return 1.0
	u -= GIAY_SANG
	if u < GIAY_MO:
		return 1.0 - u / GIAY_MO
	u -= GIAY_MO
	if u < GIAY_TOI:
		return 0.0
	return (u - GIAY_TOI) / GIAY_SANG_LAI
