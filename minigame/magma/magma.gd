extends MiniGame3D

## MAGMA & MAGES — dung nham dâng quanh nền dốc, cuối cùng phủ cả đỉnh ở tâm.
## Người bắn gửi một gói (điểm, hướng); mỗi máy tự kiểm cầu lửa với nhân vật của mình.

## Nút bắn (cùng action với đòn đánh ở trò khác).
const NUT_BAN := "danh"

## Nghỉ giữa hai phát (giây).
const NGHI_BAN := 0.55

## Điểm xuất phát ở tầm ngực; đạn ngắm đón cả chênh cao trên nền dốc.
const CAO_BAN := 1.0

## Lực hất (ngang, lên).
const DAY_NGANG := 11.0
const DAY_LEN := 4.5

const BAN_KINH_SAN := 11.5
const BAN_KINH_DINH := 0.8
const CAO_MEP := 0.2
const CAO_DINH := 2.0
const CHO_TRUOC_KHI_NGAP := 10.0
const NGAP_HET_LUC := 65.0
const GOC_HO_TRO := 0.9781476 # 12 độ; chỉ hỗ trợ quanh hướng con trỏ.

## Máu mất mỗi giây trong nham (máu đầy 100).
const MAT_MAU_MOI_GIAY := 22.0

@export var cau_lua_scene: PackedScene = null

var _san_tron: Node3D = null
var _nham: Node3D = null
var _tam_ngam: Node3D = null
var _cau: Array[CauLua] = []
var _ban_luc := -99.0
var _cho_nguoi: Dictionary = {}
var _toc_nguoi: Dictionary = {}

@onready var _thanh: ThanhMau = $ThanhMau


func _ready() -> void:
	super()
	ten = "MAGMA & MAGES"
	luat = "WASD chạy · rê chuột ngắm, giữ chuột trái bắn · dung nham dâng tới tâm · hất nhau vào vùng ngập"
	giay_van = 75.0


func _dung_san() -> void:
	_san_tron = san.get_node_or_null("SanTron") as Node3D
	_nham = san.get_node_or_null("DungNham") as Node3D
	_tam_ngam = san.get_node_or_null("TamNgam") as Node3D
	_cau.clear()
	_cho_nguoi.clear()
	_toc_nguoi.clear()
	_ban_luc = -99.0
	_thanh.mo()
	if _san_tron == null or _nham == null or _tam_ngam == null:
		push_error("Magma: san thieu SanTron / DungNham / TamNgam")
		return
	_ve_vung(0.0)


func dung_som() -> void:
	_thanh.dong()
	super()


func _luat_moi_nhip() -> void:
	var t := gio()
	_ve_vung(t)
	_cap_nhat_van_toc(get_process_delta_time())
	# Lambda không kiểu: quả đã free không ép được sang CauLua.
	_cau.assign(_cau.filter(func(c) -> bool: return is_instance_valid(c) and not c.is_queued_for_deletion()))
	if con_song(NetManager.local_id()):
		_an_mau(t)
		var p := _nguoi(NetManager.local_id())
		if p != null:
			_ve_ngam(p)
			if Input.is_action_pressed(NUT_BAN):
				_thu_ban()
	else:
		_tam_ngam.visible = false


## Nhân vật remote chỉ replicate vị trí; lấy vận tốc từ các vị trí đã nội suy.
func _cap_nhat_van_toc(delta: float) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		var id := p.player_id()
		if _cho_nguoi.has(id):
			_toc_nguoi[id] = uoc_luong_van_toc(_cho_nguoi[id], p.global_position,
				_toc_nguoi.get(id, Vector3.ZERO), delta)
		_cho_nguoi[id] = p.global_position


## Một mặt dung nham nâng lên; đường ngập là giao tuyến với nền dốc thật.
func _ve_vung(t: float) -> void:
	if _nham != null:
		_nham.position.y = muc_nham(t)


## Vùng nền bị ngập gây cháy, kể cả tâm sau khi mực nham vượt đỉnh.
func _an_mau(t: float) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	var l := p.global_position - san.global_position
	if bi_ngap(Vector2(l.x, l.z).length(), t):
		_thanh.tru(MAT_MAU_MOI_GIAY, get_process_delta_time())


## Cầu lửa hất chứ không giết; hết máu hoặc rơi khỏi sàn mới thua.
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	if p != null:
		for c in _cau:
			if c.nguoi_ban == NetManager.local_id() or c.is_queued_for_deletion() or not c.trung(p):
				continue
			var huong := c.huong_bay()
			huong.y = 0.0
			p.day(huong.normalized() * DAY_NGANG + Vector3.UP * DAY_LEN)
			c.queue_free()
			break
	return _thanh.het() or super()


## Đọc chuột ở `_input` vì GUI có thể nuốt click.
func _input(event: InputEvent) -> void:
	if not _chay or not event.is_action_pressed(NUT_BAN):
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	get_viewport().set_input_as_handled()
	_thu_ban()


func _thu_ban() -> void:
	if not _chay or get_viewport().gui_get_focus_owner() is LineEdit:
		return
	if gio() - _ban_luc < NGHI_BAN:
		return
	var p := _nguoi(NetManager.local_id())
	if p == null or not con_song(NetManager.local_id()):
		return
	_ban_luc = gio()
	var huong := _huong_ngam(p)
	p.rotation.y = atan2(-huong.x, -huong.z)
	Fusion.rpc(_net_ban, NetManager.local_id(),
			p.global_position + Vector3.UP * CAO_BAN + huong * 0.7, huong)


func _huong_ngam(p: Player) -> Vector3:
	var origin := p.global_position + Vector3.UP * CAO_BAN
	var camera := _cam_san()
	var direction := -p.global_basis.z
	if camera != null:
		var mouse := get_viewport().get_mouse_position()
		var hit: Variant = Plane(Vector3.UP, origin.y).intersects_ray(
			camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
		if hit is Vector3 and origin.distance_squared_to(hit) > 0.04:
			direction = (hit - origin).normalized()
	var best: Player = null
	var best_dot := GOC_HO_TRO
	for target: Player in get_tree().get_nodes_in_group("players"):
		if target == p or not con_song(target.player_id()):
			continue
		var offset := target.global_position + Vector3.UP * CAO_BAN - origin
		var horizontal := Vector3(offset.x, 0, offset.z)
		if horizontal.length() < 0.1 or offset.length() > CauLua.TOC_DO * CauLua.SONG:
			continue
		var alignment := direction.dot(horizontal.normalized())
		if alignment > best_dot:
			best_dot = alignment
			best = target
	if best != null:
		var velocity: Vector3 = _toc_nguoi.get(best.player_id(), best.velocity)
		return ngam_don(origin, best.global_position + Vector3.UP * CAO_BAN, velocity)
	return direction.normalized()


func _ve_ngam(p: Player) -> void:
	var origin := p.global_position + Vector3.UP * CAO_BAN
	var direction := _huong_ngam(p)
	var camera := _cam_san()
	var distance := 7.0
	if camera != null:
		var hit: Variant = Plane(Vector3.UP, origin.y).intersects_ray(
			camera.project_ray_origin(get_viewport().get_mouse_position()),
			camera.project_ray_normal(get_viewport().get_mouse_position()))
		if hit is Vector3:
			distance = clampf(origin.distance_to(hit), 1.0, 23.0)
	var position := san.to_local(origin + direction * distance)
	var radius := Vector2(position.x, position.z).length()
	position.y = maxf(cao_san(radius), muc_nham(gio())) + 0.08
	_tam_ngam.position = position
	_tam_ngam.visible = radius <= BAN_KINH_SAN + 1.0


## Một gói cho cả đời quả cầu; mọi máy tự cho nó bay.
@rpc("any_peer", "call_local")
func _net_ban(id: int, tu: Vector3, huong: Vector3) -> void:
	if not _chay or san == null or cau_lua_scene == null or not con_song(id):
		return
	var c := cau_lua_scene.instantiate() as CauLua
	san.add_child(c)
	# Bù nửa RTT cho cầu của người khác (tối đa 0,15 s).
	var tre := 0.0 if id == NetManager.local_id() else minf(NetManager.rtt_ms() / 2000.0, 0.15)
	c.ban(tu, huong, id, tre)
	_cau.append(c)


# ─── luật: hàm thuần ───


## Mực dung nham liên tục, từ dưới chân sân đến cao hơn cả đỉnh.
static func muc_nham(t: float) -> float:
	if t <= CHO_TRUOC_KHI_NGAP:
		return lerpf(-1.4, 0.18, clampf(t / CHO_TRUOC_KHI_NGAP, 0.0, 1.0))
	return lerpf(0.18, 2.12, clampf((t - CHO_TRUOC_KHI_NGAP)
		/ (NGAP_HET_LUC - CHO_TRUOC_KHI_NGAP), 0.0, 1.0))


static func cao_san(radius: float) -> float:
	return lerpf(CAO_DINH, CAO_MEP, clampf((radius - BAN_KINH_DINH)
		/ (BAN_KINH_SAN - BAN_KINH_DINH), 0.0, 1.0))


static func bi_ngap(radius: float, t: float) -> bool:
	return muc_nham(t) >= cao_san(radius)


## Giữ tên hàm cho công cụ kiểm tra vùng an toàn; cuối ván bán kính bằng 0.
static func ti_le_san(t: float) -> float:
	var height := muc_nham(t)
	if height >= CAO_DINH:
		return 0.0
	return clampf((BAN_KINH_DINH + (BAN_KINH_SAN - BAN_KINH_DINH)
		* (CAO_DINH - height) / (CAO_DINH - CAO_MEP)) / BAN_KINH_SAN, 0.0, 1.0)


## Ngắm đón vị trí đang di chuyển; giải thời gian chặn, không chỉ bắn vào vị trí cũ.
static func ngam_don(origin: Vector3, target: Vector3, velocity: Vector3) -> Vector3:
	var offset := target - origin
	var a := velocity.length_squared() - CauLua.TOC_DO * CauLua.TOC_DO
	var b := 2.0 * offset.dot(velocity)
	var c := offset.length_squared()
	var lead := offset.length() / CauLua.TOC_DO
	var discriminant := b * b - 4.0 * a * c
	if absf(a) > 0.0001 and discriminant >= 0.0:
		var t1 := (-b - sqrt(discriminant)) / (2.0 * a)
		var t2 := (-b + sqrt(discriminant)) / (2.0 * a)
		if t1 > 0.0:
			lead = t1
		if t2 > 0.0:
			lead = minf(lead, t2) if t1 > 0.0 else t2
	return (offset + velocity * clampf(lead, 0.0, 0.65)).normalized()


static func uoc_luong_van_toc(previous: Vector3, current: Vector3,
		previous_velocity: Vector3, delta: float) -> Vector3:
	var distance := current - previous
	if delta <= 0.0001 or distance.length_squared() > 25.0:
		return Vector3.ZERO # Đổi sân / teleport không phải chuyển động để ngắm đón.
	var measured := (distance / delta).limit_length(18.0)
	return previous_velocity.lerp(measured, 1.0 - exp(-12.0 * delta))


## Người chơi xuất hiện trên nền dốc, không nằm trong collider của đảo.
func _cho_vao(i: int, tong: int) -> Vector3:
	var position := super(i, tong)
	position.y = cao_san(Vector2(position.x, position.z).length())
	return position
