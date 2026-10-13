extends MiniGame3D

## SEARING SPOTLIGHTS — sàn sáng/tối theo chu kỳ, đèn rọi quét sàn; đứng trong đèn thì mất máu.
## Không chết vì rơi (bị kẹp trong sàn). Đèn và độ sáng là hàm của `gio()` — 0 gói tin.

## Máu mất mỗi giây trong đèn (máu đầy 100).
const MAT_MAU_MOI_GIAY := 40.0

## Biên độ quỹ đạo Lissajous của đèn (giữ vệt sáng trong sàn và đèn chậm hơn người chạy).
const TAM_QUET := 6.2

## Bốn chặng của một chu kỳ (giây).
const GIAY_SANG := 2.5
const GIAY_MO := 1.6
const GIAY_TOI := 6.5
const GIAY_SANG_LAI := 1.4
const CHU_KY := GIAY_SANG + GIAY_MO + GIAY_TOI + GIAY_SANG_LAI

## Số đèn chu kỳ đầu và trần.
const DEN_DAU := 2
const DEN_TOI_DA := 8

## Kẹp người chơi trong bán kính này.
const BAN_KINH_GIU := 11.0

## Độ sáng đèn trời lúc sáng hẳn.
const DEN_TROI_SANG := 1.1
## Lớp 3D 20: ánh sáng của sảnh/bàn không được chiếu vào sân ghi nhớ.
const LOP_SAN := 1 << 19
const BAN_KINH_DEN := 2.66

## Môi trường sàn tối/sáng — luôn duplicate trước khi sửa.
@export var env_toi: Environment = null
@export var env_sang: Environment = null

var _den: Array[Node3D] = []

## Pha và nhịp của từng đèn, gieo từ hạt giống chung của ván.
var _pha: PackedFloat32Array = PackedFloat32Array()
var _nhip: PackedFloat32Array = PackedFloat32Array()
var _troi: DirectionalLight3D = null
var _env: Environment = null

## Viền sàn tắt dần theo độ sáng.
var _vien: GeometryInstance3D = null

## Giữ mask gốc của đèn ngoài và hình nhân vật để khôi phục chính xác khi rời ván.
var _den_ngoai: Dictionary = {}
var _lop_hinh: Dictionary = {}
var _hien_phu: Dictionary = {}
var _cam_mask := 0
var _dau_toi: Node3D = null

@onready var _thanh: ThanhMau = $ThanhMau
@onready var _trang_thai: Label = $Pha/Nhan


func _ready() -> void:
	super()
	ten = "SEARING SPOTLIGHTS"
	luat = "WASD chạy · né spotlight"
	giay_van = MAX_ROUND_SECONDS


func bat_dau(nguoi_choi: Array, giong: int) -> void:
	# Chơi thử một mình vẫn phải thấy đủ chu kỳ sáng/tối.
	ket_thuc_khi_con_mot = nguoi_choi.size() > 1
	super(nguoi_choi, giong)


func _dung_san() -> void:
	_den.assign(san.find_children("Den*", "Node3D", false, false))
	_vien = san.get_node_or_null("VienSan") as GeometryInstance3D
	_dau_toi = san.get_node_or_null("DauToi") as Node3D
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

	# Camera dùng môi trường riêng, không nhận ambient / phản xạ trời của sảnh.
	var cam := _cam_san()
	if cam != null:
		_env = env_toi.duplicate() as Environment if env_toi != null else Environment.new()
		_env.background_mode = Environment.BG_COLOR
		_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		_env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
		cam.environment = _env
		_cam_mask = cam.cull_mask
		cam.cull_mask = LOP_SAN
	_troi = san.find_child("Den", true, false) as DirectionalLight3D
	_co_lap_anh_sang()
	$Pha.visible = true
	# Ván mở ở chặng sáng — đặt độ sáng ngay khung đầu.
	_ve_nhip(0.0)


func dung_som() -> void:
	_thanh.dong()
	$Pha.visible = false
	for l in _den_ngoai:
		if is_instance_valid(l):
			l.light_cull_mask = int(_den_ngoai[l])
	_den_ngoai.clear()
	for geometry in _lop_hinh:
		if is_instance_valid(geometry):
			geometry.layers = int(_lop_hinh[geometry])
	_lop_hinh.clear()
	for node in _hien_phu:
		if is_instance_valid(node):
			node.visible = bool(_hien_phu[node])
	_hien_phu.clear()
	var cam := _cam_san()
	if cam != null:
		cam.cull_mask = _cam_mask
	super()


func _co_lap_anh_sang() -> void:
	_den_ngoai.clear()
	_lop_hinh.clear()
	_hien_phu.clear()
	for geometry: GeometryInstance3D in san.find_children("*", "GeometryInstance3D", true, false):
		_dat_lop(geometry)
	for p: Player in get_tree().get_nodes_in_group("players"):
		for geometry: GeometryInstance3D in p.find_children("*", "GeometryInstance3D", true, false):
			_dat_lop(geometry)
		_hien_phu[p.model_root] = p.model_root.visible
		_hien_phu[p.name_tag] = p.name_tag.visible
		for path: String in ["VatCam", "SpeechBubble", "VongTam"]:
			var node := p.get_node_or_null(path) as Node3D
			if node != null:
				_hien_phu[node] = node.visible
				node.visible = false
	for light: Light3D in get_tree().root.find_children("*", "Light3D", true, false):
		if light.get_world_3d() != san.get_world_3d():
			continue
		if san.is_ancestor_of(light):
			_dat_lop(light)
			light.light_cull_mask = LOP_SAN
		else:
			_den_ngoai[light] = light.light_cull_mask
			light.light_cull_mask &= ~LOP_SAN


func _dat_lop(geometry: VisualInstance3D) -> void:
	_lop_hinh[geometry] = geometry.layers
	geometry.layers = LOP_SAN


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
	_ve_nhip(t)
	# Kẹp cả người đã hết máu.
	giu_trong_san(BAN_KINH_GIU)
	if con_song(NetManager.local_id()) and co_nguy_hiem(t):
		_an_mau(so_den(t))


func _ve_nhip(t: float) -> void:
	_dat_sang(do_sang(t))
	var n := so_den(t)
	for i in _den.size():
		var v := cho_den(_pha[i], _nhip[i], t)
		_den[i].position = Vector3(v.x, _den[i].position.y, v.y)
		# Đèn chưa tới lượt thì tắt hẳn.
		_den[i].visible = i < n
	_trang_thai.text = "%d spotlight" % n
	if _dau_toi != null:
		var p := _nguoi(NetManager.local_id())
		_dau_toi.visible = p != null and con_song(NetManager.local_id()) and do_sang(t) > 0.01
		if p != null:
			var cho := san.to_local(p.global_position)
			_dau_toi.position = Vector3(cho.x, 0.26, cho.z)
			_dau_toi.scale = Vector3.ONE * do_sang(t)


## Trừ máu nếu đứng trong vùng sáng của đèn đang bật.
func _an_mau(n: int) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	var local_position := san.to_local(p.global_position)
	for i in mini(n, _den.size()):
		var light_position := _den[i].position
		if cham_den(Vector2(local_position.x, local_position.z), Vector2(light_position.x, light_position.z)):
			_thanh.tru(MAT_MAU_MOI_GIAY, get_process_delta_time())
			return


## Độ sáng chung: 0 = tối hẳn (đen), 1 = sáng hẳn. Nội suy giữa `env_toi` và `env_sang`.
func _dat_sang(s: float) -> void:
	if _troi != null:
		_troi.light_energy = DEN_TROI_SANG * s
	if _vien != null:
		_vien.transparency = 1.0 - s
	_hien_ten(s > 0.5)
	if _env == null:
		return
	_env.ambient_light_energy = (env_sang.ambient_light_energy if env_sang != null else 0.7) * s
	_env.ambient_light_color = env_sang.ambient_light_color if env_sang != null else Color(0.45, 0.48, 0.58)
	_env.background_color = Color.BLACK.lerp(env_sang.background_color if env_sang != null else Color(0.06, 0.07, 0.11), s)


## Ẩn tên người khác lúc tối, và tên người đã bị loại.
func _hien_ten(hien: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not p.is_mine:
			p.name_tag.visible = hien and con_song(p.player_id()) and bool(_hien_phu.get(p.name_tag, true))
		for path: String in ["VatCam", "SpeechBubble", "VongTam"]:
			var node := p.get_node_or_null(path) as Node3D
			if node != null:
				node.visible = false


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
	return int(maxf(t, 0.0) / CHU_KY)


## Số đèn bật tại giây `t` (thêm một mỗi chu kỳ).
static func so_den(t: float) -> int:
	return mini(DEN_DAU + chu_ky_thu(t), DEN_TOI_DA)


## 1 = sáng hẳn, 0 = tối hẳn.
static func do_sang(t: float) -> float:
	var u := fposmod(maxf(t, 0.0), CHU_KY)
	if u < GIAY_SANG:
		return 1.0
	u -= GIAY_SANG
	if u < GIAY_MO:
		return 1.0 - u / GIAY_MO
	u -= GIAY_MO
	if u < GIAY_TOI:
		return 0.0
	return (u - GIAY_TOI) / GIAY_SANG_LAI


static func co_nguy_hiem(t: float) -> bool:
	return t >= GIAY_SANG


static func cham_den(player: Vector2, center: Vector2) -> bool:
	return player.distance_squared_to(center) <= BAN_KINH_DEN * BAN_KINH_DEN + 0.00001


static func ten_pha(t: float) -> String:
	var u := fposmod(maxf(t, 0.0), CHU_KY)
	if u < GIAY_SANG:
		return "GHI NHỚ VỊ TRÍ"
	if u < GIAY_SANG + GIAY_MO:
		return "ĐÈN ĐANG TẮT"
	if u < GIAY_SANG + GIAY_MO + GIAY_TOI:
		return "NÉ SPOTLIGHT"
	return "ĐÈN ĐANG BẬT"


## Tính cùng danh sách chỗ vào trên mọi máy, tránh đèn và chỗ của người trước.
static func cho_vao_an_toan(index: int, total: int, lights: Array[Vector2]) -> Vector3:
	var selected: Array[Vector2] = []
	for player_index in range(index + 1):
		var angle := TAU * player_index / float(maxi(total, 1))
		var ideal := Vector2(cos(angle), sin(angle)) * 7.0
		var best := ideal
		var best_score := -INF
		for candidate_index in range(129):
			var candidate := ideal
			if candidate_index > 0:
				var radius := 7.0 if candidate_index <= 64 else 9.0
				var a := TAU * float((candidate_index - 1) % 64) / 64.0
				candidate = Vector2(cos(a), sin(a)) * radius
			var safe := true
			for light: Vector2 in lights:
				if candidate.distance_to(light) < BAN_KINH_DEN + 0.9:
					safe = false
					break
			if not safe:
				continue
			var separation := 20.0
			for previous: Vector2 in selected:
				separation = minf(separation, candidate.distance_to(previous))
			var score := separation - candidate.distance_to(ideal) * 0.15
			if score > best_score:
				best_score = score
				best = candidate
		selected.append(best)
	var point := selected[index]
	return Vector3(point.x, 0.0, point.y)


func _cho_vao(index: int, total: int) -> Vector3:
	var lights: Array[Vector2] = []
	for i in mini(DEN_DAU, _pha.size()):
		lights.append(cho_den(_pha[i], _nhip[i], 0.0))
	return cho_vao_an_toan(index, total, lights)
