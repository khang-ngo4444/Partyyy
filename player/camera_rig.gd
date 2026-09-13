class_name CameraRig
extends Node3D

## Camera góc nhìn thứ nhất. Chuột ngang xoay THÂN người chơi (để hướng đi bám theo
## hướng nhìn, và người khác thấy mình quay), chuột dọc chỉ xoay camera.
##
## Cũng giữ cánh tay góc-nhìn-thứ-nhất. Chỗ đặt vật đang cầm thì do `Player.diem_cam` tính —
## máy khác cũng phải tính ra được, mà chúng không có node này.
##
## Node này chỉ tồn tại trên máy sở hữu; máy khác đã queue_free() nó.

## Node bị xoay ngang. Mặc định là node cha, tức thân người chơi.
##
## Dùng NodePath chứ KHÔNG dùng `@export var body: Node3D`: kiểu Node export chỉ phân giải
## khi gán bằng node-picker trong editor. Viết tay `body = NodePath("..")` vào .tscn thì nó
## về null, và trước đây code bỏ qua im lặng nên camera không xoay ngang được.
@export var body_path: NodePath = ^".."
@export var sensitivity := 0.0012
@export var pitch_limit_deg := 85.0

@onready var camera: Camera3D = $Camera3D
@onready var arm: MeshInstance3D = $Arm

## Góc ngồi ghế bàn bài: mắt thấp xuống, cúi nhìn mặt bàn, tầm nhìn hẹp lại một chút.
@export var mat_ngoi := 1.2
@export var cui_ngoi_deg := -15.0
@export var fov_ngoi := 68.0

var _body: Node3D = null
## Độ cao mắt và FOV lúc đứng — đọc từ scene lúc khởi động, không chép cứng số ở đây.
var _mat_dung := 0.0
var _fov_dung := 0.0
var _tween: Tween = null


func _ready() -> void:
	_mat_dung = position.y
	_fov_dung = camera.fov
	_body = get_node_or_null(body_path) as Node3D
	if _body == null:
		push_error("CameraRig: không tìm thấy body ở '%s' — sẽ không xoay ngang được." % body_path)


func make_current() -> void:
	camera.current = true


## Tay chỉ hiện khi đang cầm gì đó. Một cánh tay lơ lửng suốt ngày thì kỳ hơn là không có.
func set_holding(holding: bool) -> void:
	arm.visible = holding


## Chuyển giữa góc đứng và góc ngồi. Lúc ngồi đặt sẵn góc cúi để nhìn thấy bàn ngay; lúc
## đứng dậy thì giữ nguyên góc đang nhìn.
func set_ngoi(ngoi: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position:y", mat_ngoi if ngoi else _mat_dung, 0.35)
	_tween.tween_property(camera, "fov", fov_ngoi if ngoi else _fov_dung, 0.35)
	if ngoi:
		_tween.tween_property(self, "rotation:x", deg_to_rad(cui_ngoi_deg), 0.35)


func tint_arm(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	arm.material_override = mat


## Dùng _input chứ không phải _unhandled_input: khi chuột đang bị khoá thì việc nhìn quanh
## không nên bị bất kỳ Control nào chặn.
## KHÔNG đụng vào `Input.mouse_mode` ở đây. Màn hình Esc (`ui/pause_menu.gd`) giữ quyền đó.
## Trước kia node này cũng bắt Esc, nên mở menu ra là camera khoá chuột lại ngay, không bấm
## được nút nào — hai bên tranh nhau một biến toàn cục.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _body != null:
			_body.rotate_y(-event.relative.x * sensitivity)
		var limit := deg_to_rad(pitch_limit_deg)
		rotation.x = clampf(rotation.x - event.relative.y * sensitivity, -limit, limit)
