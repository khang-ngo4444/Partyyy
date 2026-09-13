extends Control

## Màn hình Esc. NƠI DUY NHẤT được đổi `Input.mouse_mode`.
##
## Trước đây CameraRig tự bắt Esc để nhả/khoá chuột. Giờ có menu thì hai bên tranh nhau: mở
## menu ra là camera lập tức khoá chuột lại, bấm nút không được. Nên quyền đó chuyển hết về
## đây, CameraRig chỉ còn việc xoay khi chuột đang bị khoá.

@onready var leave_button: Button = %LeaveButton


func _ready() -> void:
	# `visible = false` nam trong .tscn chu KHONG nam o day. Neu script lai roi ra khoi root
	# (da dinh ba lan, xem muc 1q) thi menu van sinh ra o trang thai an, khong che man hinh.
	%ResumeButton.pressed.connect(_dong)
	leave_button.pressed.connect(func():
		_dong()
		NetManager.leave_room())
	%QuitButton.pressed.connect(get_tree().quit)
	NetManager.room_joined.connect(func(): leave_button.disabled = false)
	NetManager.room_left.connect(func(): leave_button.disabled = true)
	leave_button.disabled = true


## _input chứ không phải _unhandled_input: menu phải mở được kể cả khi có Control nào đó
## đang giữ phím.
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Đang gõ chat thì Esc là HUỶ TIN — để Chat xử lý. PauseMenu đứng sau HUD trong cây nên
	# nhận Esc trước; không nhường thì Esc mở menu, còn ô chat vẫn nằm đó giữ phím.
	if not visible and get_viewport().gui_get_focus_owner() is LineEdit:
		return
	# Chưa vào phòng thì Esc không có việc gì làm — đang ở màn hình chính rồi.
	if leave_button.disabled and not visible:
		return
	get_viewport().set_input_as_handled()
	if visible:
		_dong()
	else:
		_mo()


func _mo() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _dong() -> void:
	visible = false
	# Chua vao phong thi tra chuot lai cho menu chinh, dung khoa vao game.
	Input.mouse_mode = (Input.MOUSE_MODE_VISIBLE if leave_button.disabled
			else Input.MOUSE_MODE_CAPTURED)
