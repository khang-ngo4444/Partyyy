extends Node3D

## Camera nền của màn hình chính. Dùng chính bàn PartyBash thay vì một ảnh chụp tĩnh,
## nhưng giữ toàn bộ node này tách khỏi SceneRoot để không dính vào gameplay/network.

@export var orbit_speed := 0.025
@export var orbit_radius := 67.0
@export var base_height := 27.0
@export var look_height := 3.5

@onready var camera: Camera3D = $CameraRig/MenuCamera
@onready var map_model: Node3D = $BanPartyPreview/MapModel

var _time := -0.65
var _motion_enabled := true
var _menu_active := true
var _world_environment: WorldEnvironment
var _menu_environment: Environment
var _previous_environment: Environment


func _ready() -> void:
	# Preview chỉ để nhìn: vô hiệu hóa physics để các collider ẩn không chặn người chơi
	# khi lobby/gameplay thật được nạp vào cùng World3D.
	for node in $BanPartyPreview.find_children("*", "CollisionObject3D", true, false):
		var body := node as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0
	_capture_environments()
	camera.current = true
	_update_camera()


func _process(delta: float) -> void:
	if not _menu_active:
		return
	if _motion_enabled:
		_time += delta * orbit_speed
	_update_camera()


func set_menu_active(active: bool) -> void:
	_menu_active = active
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	camera.current = active
	_apply_environment(active)
	if active:
		_update_camera()


func set_motion_enabled(enabled: bool) -> void:
	_motion_enabled = enabled


func _capture_environments() -> void:
	_world_environment = map_model.get("_world_env") as WorldEnvironment
	_previous_environment = map_model.get("_previous_env") as Environment
	if _world_environment != null:
		_menu_environment = _world_environment.environment


func _apply_environment(active: bool) -> void:
	if _world_environment == null or not is_instance_valid(_world_environment):
		return
	_world_environment.environment = _menu_environment if active else _previous_environment


func _update_camera() -> void:
	# Quỹ đạo không tròn tuyệt đối để khung cảnh có cảm giác “bay” tự nhiên,
	# nhưng biên độ rất nhỏ để người dùng vẫn đọc UI thoải mái.
	var angle := _time
	var radius := orbit_radius + sin(_time * 0.61) * 5.5
	var height := base_height + sin(_time * 0.83) * 3.0
	var pos := Vector3(cos(angle) * radius, height, sin(angle) * radius)
	camera.global_position = pos
	var target := Vector3(4.0 + sin(_time * 0.37) * 4.0, look_height, cos(_time * 0.44) * 3.0)
	camera.look_at(target, Vector3.UP)
