class_name Player
extends CharacterBody3D

## Nhân vật — chạy trên mọi máy cho mọi người chơi. Chỉ máy sở hữu xử lý input và có camera;
## máy khác nhận vị trí từ replicator.

## Viền stencil khi ngắm vật (màu, độ dày chỉnh trong shader): hai lượt ghi + vành.
const VIEN_GHI := preload("res://player/vien_ghi.gdshader")
const VIEN_VANH := preload("res://player/vien_vanh.gdshader")

## Thân quay theo hướng chạy nhanh cỡ nào (rad/s).
const XOAY_THEO_HUONG := 12.0

## Tốc độ rẽ khi tự lái (rad/s).
const RE_LAI := 2.6

## Lực đẩy tắt dần (m/s mỗi giây).
const DAY_TAT_DAN := 9.0

## Độ cao mắt — khớp CameraRig; máy khác dựng lại camera từ số này.
const MAT_CAO := 1.65

## Lớp va chạm của người chơi (vật nhặt được không va với lớp này).
const LOP_NGUOI := 1 << 1

## Lớp chỉ để tia ngắm trúng (nút bấm, ghế).
const LOP_NGAM := 1 << 4

## Camera lùi ít hơn chừng này thì giấu thân (góc nhìn thứ nhất).
const GAN_GAY := 1.0

## Các scene nhân vật (`player/characters/`), chọn bằng `model_index`.
@export var models: Array[PackedScene] = []

## Tầm với để nhặt/bấm, cũng là độ dài tia ngắm.
@export var pick_range := 3.2

## Ném tích lực: giữ E để nạp, thả để ném.
@export var luc_nem_min := 3.0
@export var luc_nem_max := 15.0
@export var giay_nap_day := 1.2
@export var speed := 6.0
@export var jump_height := 1.2

## 2 = nhảy đôi.
@export var so_lan_nhay := 2
@export var gravity := 20.0

## Góc cúi/ngửa camera (rad), replicate để vật đang cầm nằm đúng trước mắt ở mọi máy.
@export var nhin_doc := 0.0

## Tên người chơi. Phải là @export thì Fusion mới replicate được.
@export var player_name: String = "":
	set(value):
		player_name = value
		if is_node_ready():
			_apply_name()
@export var color_index: int = 0:
	set(value):
		color_index = value
		if is_node_ready():
			_apply_tint()
@export var accent_index: int = 1:
	set(value):
		accent_index = value
		if is_node_ready():
			_apply_tint()
@export var accessory_enabled: bool = true:
	set(value):
		accessory_enabled = value
		if is_node_ready():
			_apply_accessory()

## Người chơi tự bật cờ sẵn sàng của mình.
@export var is_ready: bool = false

## Điểm hiện tại; khi thoát, master chép sang MatchState.
@export var score: int = 0
@export var model_index: int = 0:
	set(value):
		model_index = value
		if is_node_ready():
			_apply_model()

## Kiểu bong bóng chat (`SpeechBubble.Kieu`), replicate để máy khác vẽ đúng.
@export var bubble_shape: int = 0

var is_mine := false

## Bàn party khoá WASD (đi theo xúc xắc).
var khoa_di_chuyen := false

## Chế độ sân đấu (minigame): WASD theo trục thế giới, thân tự quay theo hướng chạy.
var che_do_san := false

## Chế độ tự lái (Temporal Trails): chạy thẳng, A/D để rẽ.
var lai_tu_dong := false
var toc_lai := 6.0

## Vận tốc bị đẩy, giữ riêng rồi cộng vào cuối và tắt dần.
var _day := Vector3.ZERO

## Các lưới đang được phủ viền sáng.
var _vien: Array[MeshInstance3D] = []
var _dang_ngam: Node3D = null
var _lan_nhay := 0

## Ghế đang ngồi (null = đứng). Chỉ máy sở hữu dùng.
var _ghe: CardSeat = null

## Hướng xoay (yaw) của ghế ở khung trước, để xoay người theo ghế chạy.
var _ghe_yaw := 0.0

## Lúc bắt đầu giữ E để nạp lực; -1 = không nạp.
var _nap_tu := -1.0
var _anim: AnimationPlayer = null
var _meshes: Array[MeshInstance3D] = []
var _dang_giau := false
var _playing := ""
var _loaded_model := -1

@onready var sync: FusionSharedReplicator = $Replicator
@onready var rig: CameraRig = $CameraRig
@onready var name_tag: Label3D = $NameTag
@onready var model_root: Node3D = $ModelRoot


## Đẩy nhân vật. Chỉ gọi cho nhân vật của máy mình.
func day(xung: Vector3) -> void:
	_day.x += xung.x
	_day.z += xung.z
	if xung.y > 0.0:
		velocity.y = maxf(velocity.y, xung.y)


## Chỗ cầm đồ trước camera, lệch theo `offset` (toạ độ camera). Máy khác dựng lại từ
## vị trí + góc thân + `nhin_doc`.
func diem_cam(offset: Vector3) -> Transform3D:
	var cam: Transform3D
	if is_mine and rig != null and is_instance_valid(rig):
		cam = rig.camera.global_transform
	else:
		var b := global_transform.basis.orthonormalized() * Basis(Vector3.RIGHT, nhin_doc)
		cam = Transform3D(b, global_position + Vector3.UP * MAT_CAO)
	return Transform3D(cam.basis, cam * offset)


## Tên hiện của người chơi theo id.
static func ten_theo_id(tree: SceneTree, id: int) -> String:
	for n in tree.get_nodes_in_group("players"):
		if n is Player and n.player_id() == id:
			return n.player_name if n.player_name != "" else "#%d" % id
	return "#%d" % id


## Mức nạp lực 0..1; -1 = không nạp.
func muc_nap() -> float:
	if _nap_tu < 0.0 or carried() == null:
		return -1.0
	return clampf((Time.get_ticks_msec() / 1000.0 - _nap_tu) / giay_nap_day, 0.0, 1.0)


func luc_dang_nap() -> float:
	return lerpf(luc_nem_min, luc_nem_max, maxf(muc_nap(), 0.0))


## Đổi nhân vật của chính mình (property replicate, Fusion tự gửi đi).
func next_model() -> void:
	if is_mine:
		model_index = (model_index + 1) % models.size()


func _ready() -> void:
	add_to_group("players")
	collision_layer = LOP_NGUOI
	is_mine = sync.has_authority()

	if is_mine:
		player_name = NetManager.player_name
		color_index = NetManager.color_index
		accent_index = NetManager.accent_index
		accessory_enabled = NetManager.accessory_enabled
		model_index = NetManager.model_index

	_apply_model()
	_apply_name()

	if not is_mine:
		# Camera và input chỉ có trên máy sở hữu.
		rig.queue_free()
		set_physics_process(false)
		return

	rig.make_current()
	_apply_tint()


## Id người sở hữu, lấy từ replicator.
func player_id() -> int:
	return sync.get_owner_id()


## Gỡ viền sáng trên vật khác khi người chơi rời đi.
func _exit_tree() -> void:
	_tat_vien()


func _unhandled_input(event: InputEvent) -> void:
	if not is_mine:
		return

	# Đang gõ chat thì M là chữ.
	if event.is_action_pressed("change_model") \
			and not (get_viewport().gui_get_focus_owner() is LineEdit):
		next_model()
		return

	# Đang ngồi: Q là xin đứng dậy (mỗi loại ghế tự biết xin ai).
	if _ghe != null:
		if event.is_action_pressed("drop"):
			_ghe.xin_dung_day()
		return

	var held := carried()

	# Thả E: ném với lực đã nạp (bắt trước mọi thứ).
	if event.is_action_released("interact") and _nap_tu >= 0.0:
		var toc_do := luc_dang_nap()
		_nap_tu = -1.0
		if held != null:
			held.throw(-rig.camera.global_transform.basis.z, toc_do)
		return

	# Q: đặt xuống dưới chân.
	if event.is_action_pressed("drop"):
		_nap_tu = -1.0
		if held != null:
			held.drop()
		return

	if not event.is_action_pressed("interact"):
		return

	if held != null:
		# Bắt đầu nạp; ném lúc thả phím.
		_nap_tu = Time.get_ticks_msec() / 1000.0
		return

	# Bấm đúng cái đang được tô sáng (`_cap_nhat_muc_tieu` quyết định).
	if _dang_ngam == null or not is_instance_valid(_dang_ngam):
		return
	if _dang_ngam is Pressable:
		(_dang_ngam as Pressable).press()
	elif _dang_ngam is Pickable:
		(_dang_ngam as Pickable).request_pick()
	elif _dang_ngam is CardSeat and (_dang_ngam as CardSeat).con_trong():
		# Chỉ xin ngồi; ghế bài và ghế lái đợi master đồng ý mới được đặt lên ghế.
		(_dang_ngam as CardSeat).xin_ngoi()


## Vật đang cầm, suy ra từ `holder_id` đã replicate.
## ponytail: quét cả nhóm mỗi lần gọi — đổi sang signal nếu đo thấy tốn.
func carried() -> Pickable:
	var me := player_id()
	for p: Pickable in get_tree().get_nodes_in_group("pickable"):
		if p.holder_id == me:
			return p
	return null


## Vật đang ngắm: bắn một tia từ camera, trúng gì ngắm nấy (tường chắn tia).
func _ngam() -> Node3D:
	if rig == null or not is_instance_valid(rig):
		return null
	var cam := rig.camera.global_transform
	var q := PhysicsRayQueryParameters3D.create(cam.origin, cam.origin - cam.basis.z * pick_range,
			Pickable.LOP_THE_GIOI | Pickable.LOP_VAT | LOP_NGAM)
	# Nút và ghế là Area3D.
	q.collide_with_areas = true
	q.exclude = [get_rid()]
	var trung := get_world_3d().direct_space_state.intersect_ray(q)
	if trung.is_empty():
		return null
	return _chu_cua(trung["collider"], cam.origin)


## Từ thứ tia trúng đi lên tìm chủ của nó; null = không ngắm được.
func _chu_cua(va_cham: Object, mat: Vector3) -> Node3D:
	var n := va_cham as Node
	while n != null:
		if n is Pickable:
			return n if (n as Pickable).holder_id == 0 else null
		if n is Pressable:
			# Mỗi nút có tầm bấm riêng.
			var nut := n as Pressable
			return nut if mat.distance_to(nut.diem_ngam()) <= nut.press_range else null
		if n is CardSeat:
			return n
		n = n.get_parent()
	return null


func _physics_process(delta: float) -> void:
	# Đang ngồi/bị khoá: đứng yên hẳn.
	if _ghe != null or khoa_di_chuyen:
		velocity = Vector3.ZERO
		return
	if lai_tu_dong:
		_lai(delta)
		return
	# Đang gõ chat thì WASD và Space là chữ.
	var dang_go := get_viewport().gui_get_focus_owner() is LineEdit
	if is_on_floor():
		_lan_nhay = 0
	else:
		velocity.y -= gravity * delta
		# Bước hụt khỏi mép mà không nhảy thì coi như đã dùng lần nhảy đầu.
		_lan_nhay = maxi(_lan_nhay, 1)
	if not dang_go and Input.is_action_just_pressed("jump") and _lan_nhay < so_lan_nhay:
		velocity.y = sqrt(2.0 * gravity * jump_height)
		_lan_nhay += 1

	var input := Vector2.ZERO if dang_go else Input.get_vector(
			"move_left", "move_right", "move_forward", "move_back")
	var tho := Vector3(input.x, 0.0, input.y)
	# Sân đấu theo trục thế giới; phòng chờ theo hướng thân.
	var dir := (tho if che_do_san else transform.basis * tho).normalized()
	velocity.x = dir.x * speed + _day.x
	velocity.z = dir.z * speed + _day.z
	_day = _day.move_toward(Vector3.ZERO, DAY_TAT_DAN * delta)

	# -Z là hướng trước.
	if che_do_san and dir.length_squared() > 0.01:
		rotation.y = rotate_toward(rotation.y, atan2(-dir.x, -dir.z), XOAY_THEO_HUONG * delta)

	move_and_slide()


## Tự lái: chạy thẳng theo hướng thân, A/D xoay thân.
func _lai(delta: float) -> void:
	var dang_go := get_viewport().gui_get_focus_owner() is LineEdit
	var re := 0.0 if dang_go else Input.get_axis("move_right", "move_left")
	rotation.y += re * RE_LAI * delta
	var truoc := -global_basis.z
	velocity.x = truoc.x * toc_lai
	velocity.z = truoc.z * toc_lai
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()


## Animation mỗi máy tự suy ra từ velocity, không cần đồng bộ.
func _process(_delta: float) -> void:
	var holding := carried() != null
	if is_mine:
		nhin_doc = rig.rotation.x
		_theo_ghe()
		if _ghe != null and _ghe.di_dong:
			_bam_ghe()
		_cap_nhat_muc_tieu(holding)
		# Sân đấu nhìn từ trên xuống: không giấu thân.
		_giau_than(rig.lui_xa < GAN_GAY and not che_do_san)
	else:
		_bam_ghe_cua_nguoi_khac()

	if _anim == null:
		return
	var want := "holding-right" if holding else _pick_anim()
	if want != _playing:
		_playing = want
		_anim.play(want, 0.15)


## Chọn vật đang ngắm và phủ viền sáng lên nó.
func _cap_nhat_muc_tieu(holding: bool) -> void:
	var muc_tieu: Node3D = null
	# Đang cầm thì E là ném, không ngắm cái khác.
	if not holding and _ghe == null:
		muc_tieu = _ngam()

	if muc_tieu != _dang_ngam:
		_tat_vien()
		_dang_ngam = muc_tieu
		if muc_tieu != null:
			_bat_vien((muc_tieu as CardSeat).vat_vien() if muc_tieu is CardSeat else muc_tieu)


## Phủ viền stencil (`material_overlay` ghi stencil + `next_pass` vẽ vành) lên mọi lưới của vật.
## Mọi lưới ghi trước (priority 0), vành vẽ sau (priority 1) nên vật nhiều mảnh chỉ có viền ngoài.
func _bat_vien(node: Node3D) -> void:
	for m in _luoi_cua(node):
		var ghi := ShaderMaterial.new()
		ghi.shader = VIEN_GHI
		var vanh := ShaderMaterial.new()
		vanh.shader = VIEN_VANH
		vanh.render_priority = 1
		# Hướng nở của vành tính từ hộp bao của lưới.
		var hop := m.get_aabb()
		vanh.set_shader_parameter("tam", hop.get_center())
		vanh.set_shader_parameter("nua", hop.size * 0.5)
		ghi.next_pass = vanh
		m.material_overlay = ghi
		_vien.append(m)


func _luoi_cua(node: Node3D) -> Array[MeshInstance3D]:
	var ds: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		ds.append(node)
	for m: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if m.mesh != null:
			ds.append(m)
	return ds


func _tat_vien() -> void:
	for v in _vien:
		if v != null and is_instance_valid(v):
			v.material_overlay = null
	_vien.clear()


## Ngồi/đứng theo trạng thái ghế do master quyết.
func _theo_ghe() -> void:
	var ghe: CardSeat = null
	for n in get_tree().get_nodes_in_group("card_seat"):
		if n is CardSeat and n.toi_dang_ngoi:
			ghe = n
	if ghe == _ghe:
		return
	if ghe == null and _ghe != null and is_instance_valid(_ghe):
		global_position = _ghe.diem_dung_day()
	_ghe = ghe
	velocity = Vector3.ZERO
	if _ghe != null:
		var diem := _ghe.diem_ngoi()
		global_transform = diem
		_ghe_yaw = diem.basis.get_euler().y
	rig.set_ngoi(_ghe != null)


## Ghế gắn trên vật chạy (tàu): theo ghế mỗi khung, hướng nhìn riêng của người chơi xoay theo xe.
func _bam_ghe() -> void:
	var diem := _ghe.diem_ngoi()
	var yaw := diem.basis.get_euler().y
	rotate_y(angle_difference(_ghe_yaw, yaw))
	_ghe_yaw = yaw
	global_position = diem.origin


## Máy khác: người đang lái thì vẽ đúng tại ghế (vị trí replicate trễ hơn xe chạy cục bộ).
func _bam_ghe_cua_nguoi_khac() -> void:
	var id := player_id()
	for n: CardSeat in get_tree().get_nodes_in_group("card_seat"):
		if n.di_dong and n.nguoi == id:
			global_position = n.diem_ngoi().origin
			return


func _pick_anim() -> String:
	# Mọi máy tự suy ra từ trạng thái ghế.
	for n in get_tree().get_nodes_in_group("card_seat"):
		if n is CardSeat and n.nguoi != 0 and n.nguoi == player_id():
			return "sit"
	if absf(velocity.y) > 1.0:
		return "jump" if velocity.y > 0.0 else "fall"
	return "sprint" if Vector2(velocity.x, velocity.z).length() > 0.3 else "idle"


## Dựng model. Fusion có thể ghi lại giá trị replicate sau `_ready` — chặn dựng lần hai.
func _apply_model() -> void:
	if _loaded_model == model_index and _anim != null:
		return
	_loaded_model = model_index
	_playing = ""
	for c in model_root.get_children():
		c.queue_free()
	_meshes.clear()
	_anim = null

	var inst := models[model_index % models.size()].instantiate() as Node3D
	model_root.add_child(inst)

	_anim = CharacterVisual.hoat_anh_cua(inst)

	for m: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(m)
		if is_mine:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# Ép `_giau_than` áp lại ở khung sau.
	_dang_giau = false
	_apply_tint()
	_apply_accessory()


## Góc nhìn thứ nhất: giấu thân nhưng vẫn đổ bóng. Chỉ chạy khi trạng thái đổi.
func _giau_than(giau: bool) -> void:
	if giau == _dang_giau:
		return
	_dang_giau = giau
	for m in _meshes:
		m.cast_shadow = (GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if giau
				else GeometryInstance3D.SHADOW_CASTING_SETTING_ON)


## Nhuộm màu bằng bản sao material gốc (giữ texture atlas).
func _apply_tint() -> void:
	var primary := NetManager.color_for(color_index)
	name_tag.modulate = primary
	CharacterVisual.apply_customization(model_root, primary,
			NetManager.color_for(accent_index), accessory_enabled)


func _apply_accessory() -> void:
	CharacterVisual.set_accessory_enabled(model_root, accessory_enabled)


func _apply_name() -> void:
	name_tag.text = player_name
	# Không cần thấy tên của chính mình.
	name_tag.visible = not is_mine
