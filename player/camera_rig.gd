class_name CameraRig
extends Node3D

## Camera của người chơi (chỉ có trên máy sở hữu). Chuột ngang xoay thân, chuột dọc xoay camera.

## Node bị xoay ngang (mặc định là thân người chơi). Dùng NodePath vì export Node viết tay
## trong .tscn sẽ ra null.
@export var body_path: NodePath = ^".."
@export var sensitivity := 0.0012
@export var pitch_limit_deg := 85.0

## Camera lùi ra sau bao xa; 0 = góc nhìn thứ nhất.
@export var lui_xa := 4.2

## Camera cao hơn điểm ngắm chừng này.
@export var nang_cao := 1.1

## Chừa mép khi camera bị tường chắn.
@export var chua_tuong := 0.35

## Góc ngồi ghế bàn bài.
@export var mat_ngoi := 1.2
@export var cui_ngoi_deg := -15.0
@export var fov_ngoi := 68.0

## Góc bàn party: lùi ra sau, nâng cao, chúc xuống.
@export var lui_ban := 11.0
@export var cao_ban := 2.8
@export var cui_ban_deg := -48.0
@export var fov_ban := 65.0

## Góc ngắm vật phẩm trên bàn: camera dán vào mắt để tâm màn hình trùng tia.
@export var lui_ngam := 0.0
@export var cao_ngam := 0.0
@export var cui_ngam_deg := -8.0
@export var fov_ngam := 72.0

var _body: Node3D = null

## Thông số góc đứng, đọc từ scene lúc khởi động.
var _mat_dung := 0.0
var _fov_dung := 0.0
var _lui_dung := 0.0
var _cao_dung := 0.0
var _ban_co := false
var _ngam_sung := false
var _tween: Tween = null

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_mat_dung = position.y
	_fov_dung = camera.fov
	_lui_dung = lui_xa
	_cao_dung = nang_cao
	_body = get_node_or_null(body_path) as Node3D
	if _body == null:
		push_error("CameraRig: không tìm thấy body ở '%s' — sẽ không xoay ngang được." % body_path)


## Đặt camera sau điểm ngắm, kéo sát lại nếu đâm tường (mỗi khung hình).
func _process(_delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	if lui_xa <= 0.01:
		camera.position = Vector3.ZERO
		return

	var muon := Vector3(0.0, nang_cao, lui_xa)
	var goc := global_position
	var dich := global_transform * muon
	var q := PhysicsRayQueryParameters3D.create(goc, dich, Pickable.LOP_THE_GIOI)
	q.exclude = [_body.get_rid()] if _body is CollisionObject3D else []
	var trung := get_world_3d().direct_space_state.intersect_ray(q)
	if trung.is_empty():
		camera.position = muon
		return
	var xa := goc.distance_to(trung["position"]) - chua_tuong
	camera.position = muon.normalized() * maxf(xa, 0.0)


func make_current() -> void:
	camera.current = true


## Vào/ra góc ngồi; lúc ngồi đặt sẵn góc cúi nhìn bàn.
func set_ngoi(ngoi: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position:y", mat_ngoi if ngoi else _mat_dung, 0.35)
	_tween.tween_property(camera, "fov", fov_ngoi if ngoi else _fov_dung, 0.35)
	if ngoi:
		_tween.tween_property(self, "rotation:x", deg_to_rad(cui_ngoi_deg), 0.35)


## Vào/ra góc bàn party (bỏ qua nếu không đổi để tween không khởi động lại liên tục).
func set_ban_co(bat: bool) -> void:
	if _ban_co == bat:
		return
	_ban_co = bat
	if not bat:
		_ngam_sung = false
	_chuyen_camera_ban()


## Góc ngắm vật phẩm, chỉ có hiệu lực trên bàn.
func set_ngam_sung(bat: bool) -> void:
	var moi := bat and _ban_co
	if _ngam_sung == moi:
		return
	_ngam_sung = moi
	_chuyen_camera_ban()


func _chuyen_camera_ban() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	var lui := lui_ngam if _ngam_sung else (lui_ban if _ban_co else _lui_dung)
	var cao := cao_ngam if _ngam_sung else (cao_ban if _ban_co else _cao_dung)
	var fov := fov_ngam if _ngam_sung else (fov_ban if _ban_co else _fov_dung)
	var thoi_gian := 0.3 if _ngam_sung else 0.5
	_tween.tween_property(self, "lui_xa", lui, thoi_gian)
	_tween.tween_property(self, "nang_cao", cao, thoi_gian)
	_tween.tween_property(camera, "fov", fov, thoi_gian)
	if _ban_co:
		var goc := cui_ngam_deg if _ngam_sung else cui_ban_deg
		_tween.tween_property(self, "rotation:x", deg_to_rad(goc), thoi_gian)


## Nhìn quanh bằng `_input` để không Control nào chặn. Không đụng `mouse_mode` (menu Esc giữ).
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _body != null:
			_body.rotate_y(-event.relative.x * sensitivity)
		var limit := deg_to_rad(pitch_limit_deg)
		rotation.x = clampf(rotation.x - event.relative.y * sensitivity, -limit, limit)
