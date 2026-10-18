class_name CameraTuDo
extends Camera3D

## Camera tự do ở bàn party — chỉ tồn tại trên máy này, không replicate, không ai khác điều khiển.
## Chuột (đang khoá) xoay nhìn · WASD/mũi tên bay ngang · lăn chuột tiến/lùi theo hướng nhìn ·
## Shift đi nhanh. (Chọn hướng / mục tiêu trên bàn dùng Z/X nên không đụng WASD.)

@export var toc_do := 16.0
@export var nhanh := 2.6
@export var do_nhay_chuot := 0.0024
@export var buoc_lan := 2.5
## Giới hạn bay quanh tâm bàn (m).
@export var ban_kinh := 90.0
@export var cao_min := 1.5
@export var cao_max := 60.0

## Tắt nếu cần nhường WASD cho việc khác.
var cho_wasd := true
## Mặt bàn (y) và tâm giới hạn bay.
var tam := Vector3.ZERO

var _yaw := 0.0
var _pitch := deg_to_rad(-45.0)


func _ready() -> void:
	fov = 58.0
	_ap_goc()


## Đặt camera ở `vi_tri`, quay nhìn vào `diem`.
func dat_nhin(vi_tri: Vector3, diem: Vector3) -> void:
	global_position = vi_tri
	var huong := (diem - vi_tri).normalized()
	_yaw = atan2(-huong.x, -huong.z)
	_pitch = clampf(asin(huong.y), deg_to_rad(-88.0), deg_to_rad(10.0))
	_ap_goc()


func _ap_goc() -> void:
	global_basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0))


func _input(event: InputEvent) -> void:
	if not current:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * do_nhay_chuot
		_pitch = clampf(_pitch - event.relative.y * do_nhay_chuot,
				deg_to_rad(-88.0), deg_to_rad(10.0))
		_ap_goc()
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_di(-global_basis.z * buoc_lan)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_di(global_basis.z * buoc_lan)


func _process(delta: float) -> void:
	if not current or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var tien := 0.0
	var ngang := 0.0
	if Input.is_key_pressed(KEY_UP) or (cho_wasd and Input.is_action_pressed("move_forward")):
		tien += 1.0
	if Input.is_key_pressed(KEY_DOWN) or (cho_wasd and Input.is_action_pressed("move_back")):
		tien -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or (cho_wasd and Input.is_action_pressed("move_right")):
		ngang += 1.0
	if Input.is_key_pressed(KEY_LEFT) or (cho_wasd and Input.is_action_pressed("move_left")):
		ngang -= 1.0
	if tien == 0.0 and ngang == 0.0:
		return
	# Bay song song mặt bàn để không chúi xuống đất khi đang nhìn xuống.
	var truoc := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var phai := Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var v := (truoc * tien + phai * ngang).normalized() * toc_do
	if Input.is_key_pressed(KEY_SHIFT):
		v *= nhanh
	_di(v * delta)


func _di(buoc: Vector3) -> void:
	var p := global_position + buoc
	var lech := Vector2(p.x - tam.x, p.z - tam.z)
	if lech.length() > ban_kinh:
		lech = lech.normalized() * ban_kinh
		p.x = tam.x + lech.x
		p.z = tam.z + lech.y
	p.y = clampf(p.y, tam.y + cao_min, tam.y + cao_max)
	global_position = p
