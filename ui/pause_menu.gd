extends Control

## Màn Esc — nơi duy nhất đổi `Input.mouse_mode`.

@onready var leave_button: Button = %LeaveButton


func _ready() -> void:
	# `visible = false` đặt trong .tscn.
	%ResumeButton.pressed.connect(_dong)
	leave_button.pressed.connect(func(): %LeaveConfirm.popup_centered())
	%LeaveConfirm.confirmed.connect(func():
		_dong()
		NetManager.leave_room())
	%QuitButton.pressed.connect(func(): %QuitConfirm.popup_centered())
	%QuitConfirm.confirmed.connect(get_tree().quit)
	NetManager.room_joined.connect(func(): leave_button.disabled = false)
	NetManager.room_left.connect(func(): leave_button.disabled = true)
	leave_button.disabled = true


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Đang gõ chat thì Esc là huỷ tin (để Chat xử lý).
	if not visible and get_viewport().gui_get_focus_owner() is LineEdit:
		return
	# Chưa vào phòng thì Esc không làm gì.
	if leave_button.disabled and not visible:
		return
	# Đang chọn mục tiêu vật phẩm trong thế giới: Esc huỷ lựa chọn, chưa mở menu.
	if not visible:
		for n in get_tree().get_nodes_in_group("esc_huy"):
			if n.huy_bang_esc():
				get_viewport().set_input_as_handled()
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
	# Chưa vào phòng thì trả chuột cho menu chính.
	Input.mouse_mode = (Input.MOUSE_MODE_VISIBLE if leave_button.disabled
			else Input.MOUSE_MODE_CAPTURED)
