class_name Pickable
extends RigidBody3D

## Vật nhặt được (quân cờ, xúc xắc, bóng rổ, phi tiêu, lá bài): RigidBody3D thật do master
## sở hữu và quyết định; máy khác vẫn chạy vật lý, replicator nắn về trạng thái master.
## ⚠️ `root_forecast_gravity = false` trong .tscn, không thì vật lún sàn.
## ⚠️ Giữ owner_mode TRANSACTION; MASTER_CLIENT làm hỏng replicate vị trí.
## Hai kiểu cầm: siêu linh (lò xo vật lý, mặc định) và trong tay (`sieu_linh = false`, tắt vật lý).

## Lớp va chạm của vật; không va với người chơi (Player.LOP_NGUOI).
const LOP_VAT := 1 << 3
const LOP_THE_GIOI := 1

## Rơi dưới độ cao này thì trả về chỗ để sẵn.
const DAY_VUC := -5.0

## Đứng yên trên cao quá chừng này giây (kẹt trên nóc) thì trả về chỗ cũ.
const CAO_KET := 1.5
const GIAY_KET := 2.0

## Số điểm tối đa đưa vào hình lồi.
const DIEM_LOI_TOI_DA := 256

## Cache hình lồi theo khoá (loại quân + góc xoay).
static var _hinh_da_dung := {}

## Ai đang cầm, 0 = không ai. Chỉ master ghi.
@export var holder_id: int = 0

## Chỗ cầm kiểu trong tay, hệ toạ độ camera (+X phải, +Y lên, -Z trước).
@export var cam_offset := Vector3(0.27, -0.24, -0.6)

## 0 = xoay khớp camera ngay; > 0 = xoay đuổi theo với tốc độ này.
@export var do_tre_xoay := 0.0

## Cầm siêu linh: lò xo mềm giới hạn lực (Catto, "Soft Constraints", GDC 2011).
## Tắt cho dụng cụ cầm tay.
@export var sieu_linh := true

## Tần số lò xo (Hz); giữ dưới nửa nhịp vật lý.
@export var sieu_linh_hz := 5.0

## 1 = tắt dần tới hạn (không vượt, không rung).
@export var sieu_linh_tat_dan := 1.0

## Lực tay tối đa = số này × trọng lượng vật.
@export var sieu_linh_luc := 4.0

## Khoảng cách vật lơ lửng trước mặt, mét.
@export var sieu_linh_xa := 1.3

## Hãm xoay khi lơ lửng.
@export var sieu_linh_ham_xoay := 4.0

## Chỉ số vật lý; lớp con đặt trong `_init`.
@export var nay := 0.2
@export var ma_sat := 0.6

## Hãm khi chạm mặt; trên không luôn bằng 0.
@export var ham_mat_dat := 0.8
@export var ham_xoay := 0.5

## Khoá vật lý (lá bài trong ô nhà cái, phi tiêu cắm bia). Replicate để máy khác cũng khoá.
@export var dinh_co_dinh := false

## Master ghi lúc thả: ai thả (bóng rổ tính 2 hay 3 điểm).
var nguoi_nem := 0
var cho_nem := Vector3.ZERO

## Chỗ để sẵn; rơi hoặc kẹt thì về đây.
var cho_mac_dinh := Vector3.ZERO

## Góc xoay đuổi theo camera, giữ riêng ở máy này (replicator ghi đè `global_transform`).
var _xoay_tay := Basis.IDENTITY

## Đang đuổi theo tay ai (0 = không).
var _tay_cua := 0
var _dung_yen := 0.0

@onready var sync: FusionSharedReplicator = $Replicator


func _ready() -> void:
	add_to_group("pickable")
	# Vật siêu linh không cần _process.
	set_process(not sieu_linh)
	# Chạy sau replicator, không thì vật bị kéo về vị trí cũ mỗi nhịp.
	process_priority = 1
	continuous_cd = true
	# REPLACE: COMBINE cộng thêm hãm mặc định, ném hụt.
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp = ham_xoay
	var vat_lieu := PhysicsMaterial.new()
	vat_lieu.bounce = nay
	vat_lieu.friction = ma_sat
	physics_material_override = vat_lieu
	# Để biết đang chạm mặt hay đang bay.
	contact_monitor = true
	max_contacts_reported = 4
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	# Khoá tới nhịp vật lý đầu, lúc đó mới biết có phải master.
	freeze = true
	collision_layer = LOP_VAT
	collision_mask = LOP_THE_GIOI | LOP_VAT


## Người chơi gọi ở máy họ; master quyết.
func request_pick() -> void:
	if holder_id != 0:
		return
	Fusion.rpc(_net_pick, NetManager.local_id())


## Thả rơi tại chỗ.
func drop() -> void:
	if holder_id != NetManager.local_id():
		return
	Fusion.rpc(_net_drop)


## Ném theo hướng nhìn, `toc_do` m/s; master đặt vận tốc.
func throw(direction: Vector3, toc_do: float) -> void:
	if holder_id != NetManager.local_id():
		return
	Fusion.rpc(_net_throw, direction, toc_do)


@rpc("any_peer", "call_local")
func _net_pick(by_id: int) -> void:
	# Chỉ master; RPC tới theo thứ tự nên người sau thấy `holder_id` khác 0.
	if not sync.has_authority() or holder_id != 0:
		return
	holder_id = by_id
	dinh_co_dinh = false
	_khi_duoc_nhat()


@rpc("any_peer", "call_local")
func _net_throw(direction: Vector3, toc_do: float) -> void:
	if not sync.has_authority() or holder_id == 0:
		return
	_tha(direction.normalized() * toc_do)


@rpc("any_peer", "call_local")
func _net_drop() -> void:
	if not sync.has_authority() or holder_id == 0:
		return
	# Giữ vận tốc đang có: vật siêu linh bay tiếp theo quán tính.
	_tha(linear_velocity)


## Master thả vật với vận tốc; mở khoá ngay để vận tốc có tác dụng nhịp này.
func _tha(van_toc: Vector3) -> void:
	nguoi_nem = holder_id
	var p := _find_player(holder_id)
	cho_nem = p.global_position if p != null else global_position
	holder_id = 0
	_mo_khoa()
	sleeping = false
	angular_velocity = Vector3.ZERO
	linear_velocity = van_toc
	_khi_bat_dau_bay()


func _process(delta: float) -> void:
	# Vật siêu linh do vật lý kéo đi (xem `_keo_sieu_linh`).
	if sieu_linh:
		_tay_cua = 0
		return
	if not sync.has_authority():
		# Máy người cầm tự đặt vật theo camera mình; máy khác tính cùng công thức (Player.diem_cam).
		if holder_id != 0 and holder_id == NetManager.local_id():
			_theo_tay(delta)
		else:
			_tay_cua = 0
		return
	if holder_id == 0:
		_tay_cua = 0
		return
	if not _theo_tay(delta):
		# Người cầm đã rời phòng.
		_tha(Vector3.ZERO)


func _physics_process(delta: float) -> void:
	var la_master := sync.has_authority()
	if la_master and cho_mac_dinh == Vector3.ZERO:
		cho_mac_dinh = global_position
	if holder_id != 0 and sieu_linh:
		# Lơ lửng nhưng vẫn là vật lý động, vẫn va chạm.
		_mo_khoa()
		linear_damp = 0.0
		angular_damp = sieu_linh_ham_xoay
		if la_master:
			_keo_sieu_linh()
		return
	angular_damp = ham_xoay
	if holder_id != 0 or dinh_co_dinh:
		_khoa(holder_id != 0)
		return
	_mo_khoa()
	# Trên không không hãm.
	linear_damp = ham_mat_dat if get_contact_count() > 0 else 0.0
	if not la_master:
		return

	if global_position.y < DAY_VUC:
		_ve_cho_cu()
		return
	if global_position.y > CAO_KET and linear_velocity.length() < 0.05:
		_dung_yen += delta
		if _dung_yen > GIAY_KET:
			_ve_cho_cu()
			return
	else:
		_dung_yen = 0.0
	_khi_bay_vat_ly(delta)


## Tay siêu linh (master): F = m(w²·lệch − 2ζw·v), w = 2πf, cắt ở `sieu_linh_luc` × trọng lượng.
## Đặt lực thay vì ghi thẳng `linear_velocity` để vật lý mô phỏng đúng.
## ponytail: chưa tính vận tốc điểm giữ, chạy nhanh vật trễ ~2ζv/w;
## thêm vào số hạng giảm chấn nếu cần bám sát hơn.
func _keo_sieu_linh() -> void:
	var p := _find_player(holder_id)
	if p == null:
		_tha(linear_velocity)  # người cầm rời phòng
		return
	var dich := p.diem_cam(Vector3(0.0, -0.15, -sieu_linh_xa)).origin
	var w := TAU * sieu_linh_hz
	var luc := mass * ((dich - global_position) * w * w
			- linear_velocity * 2.0 * sieu_linh_tat_dan * w)
	var trong_luc := maxf(get_gravity().length(), 9.8)
	sleeping = false
	apply_central_force(luc.limit_length(sieu_linh_luc * mass * trong_luc))


func _mo_khoa() -> void:
	if not freeze:
		return
	freeze = false
	collision_layer = LOP_VAT
	collision_mask = LOP_THE_GIOI | LOP_VAT


## Cầm trong tay thì tắt va chạm.
func _khoa(dang_cam: bool) -> void:
	if not freeze:
		freeze = true
	var lop := 0 if dang_cam else LOP_VAT
	if collision_layer != lop:
		collision_layer = lop
		collision_mask = 0 if dang_cam else (LOP_THE_GIOI | LOP_VAT)


func _ve_cho_cu() -> void:
	_dung_yen = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = Transform3D(Basis.IDENTITY, cho_mac_dinh)


## Đặt vật theo camera người cầm, lệch `cam_offset`.
func _theo_tay(delta: float) -> bool:
	var p := _find_player(holder_id)
	if p == null:
		return false
	var dich := p.diem_cam(cam_offset)
	if _tay_cua != holder_id or do_tre_xoay <= 0.0:
		_xoay_tay = dich.basis
		_tay_cua = holder_id
	else:
		_xoay_tay = _xoay_tay.slerp(dich.basis, clampf(delta * do_tre_xoay, 0.0, 1.0))
	global_transform = Transform3D(_xoay_tay, dich.origin)
	return true


## Lớp con gọi sau khi dựng hình; gán hình cho `HinhVaCham` (có sẵn trong scene mỗi vật).
func _dat_hinh(hinh: Shape3D, vi_tri := Vector3.ZERO) -> void:
	if hinh == null:
		return
	var cs := $HinhVaCham as CollisionShape3D
	cs.shape = hinh
	cs.position = vi_tri


## Hình lồi bao mọi lưới dưới `goc`, toạ độ của vật; bỏ lưới đang chờ xoá.
## ⚠️ Không dùng `Mesh.create_convex_shape()`: 64–119 ms mỗi model,
## chặn luồng chính làm Photon ngắt kết nối.
func _hinh_loi_tu_luoi(goc: Node3D, khoa: String) -> ConvexPolygonShape3D:
	if _hinh_da_dung.has(khoa):
		return _hinh_da_dung[khoa]
	var diem := PackedVector3Array()
	for m in goc.find_children("*", "MeshInstance3D", true, false):
		var luoi := m as MeshInstance3D
		if luoi.mesh == null or luoi.is_queued_for_deletion():
			continue
		var t := _bien_doi_toi_goc(luoi)
		for mat in luoi.mesh.get_surface_count():
			for p in luoi.mesh.surface_get_arrays(mat)[Mesh.ARRAY_VERTEX]:
				diem.append(t * p)
	if diem.is_empty():
		return null
	var buoc := maxi(1, ceili(diem.size() / float(DIEM_LOI_TOI_DA)))
	var gon := PackedVector3Array()
	for i in range(0, diem.size(), buoc):
		gon.append(diem[i])
	var hinh := ConvexPolygonShape3D.new()
	hinh.points = gon
	_hinh_da_dung[khoa] = hinh
	return hinh


func _bien_doi_toi_goc(n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var x: Node = n
	while x != null and x != self:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t


## Móc cho lớp con, chỉ chạy trên master.
func _khi_duoc_nhat() -> void:
	pass


func _khi_bat_dau_bay() -> void:
	pass


func _khi_bay_vat_ly(_delta: float) -> void:
	pass


func _find_player(player_id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == player_id:
			return p
	return null
