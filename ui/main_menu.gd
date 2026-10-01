extends Control

## Menu chỉ phát yêu cầu phòng; phần mạng vẫn do Main/NetManager điều phối.

signal host_requested
signal join_requested(room_name: String)
signal camera_motion_changed(enabled: bool)

const SETTINGS_PATH := "user://party_settings.cfg"

@onready var name_edit: LineEdit = %NameEdit
@onready var host_btn: Button = %HostBtn
@onready var status: Label = %Status
@onready var room_list: VBoxContainer = %RoomList
@onready var empty_hint: Label = %EmptyHint
@onready var settings_btn: Button = %SettingsBtn
@onready var quit_btn: Button = %QuitBtn
@onready var settings_overlay: ColorRect = %SettingsOverlay
@onready var back_btn: Button = %BackBtn
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var camera_motion_check: CheckButton = %CameraMotionCheck
@onready var click_sound: AudioStreamPlayer = $ClickSound


func _ready() -> void:
	_load_settings()
	name_edit.text = "Player%d" % (randi() % 1000)
	name_edit.text_changed.connect(func(t): NetManager.player_name = t.strip_edges())
	NetManager.player_name = name_edit.text

	host_btn.pressed.connect(_request_host)
	settings_btn.pressed.connect(_open_settings)
	quit_btn.pressed.connect(_quit_game)
	back_btn.pressed.connect(_close_settings)
	volume_slider.value_changed.connect(_set_volume)
	fullscreen_check.toggled.connect(_set_fullscreen)
	camera_motion_check.toggled.connect(_set_camera_motion)

	NetManager.connected.connect(func(): _set_status(
			"Đã kết nối • Tạo phòng mới hoặc chọn một phòng bên trên.", false))
	NetManager.connect_failed.connect(func(r): _set_status("Không thể kết nối: %s" % r, true))
	NetManager.room_list_changed.connect(_rebuild_room_list)

	_set_status("Đang kết nối tới máy chủ…", false)
	_set_buttons_enabled(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_overlay.visible:
		_close_settings()
		get_viewport().set_input_as_handled()


func _request_host() -> void:
	if name_edit.text.strip_edges().is_empty():
		name_edit.grab_focus()
		_set_status("Hãy nhập tên trước khi tạo phòng.", true)
		return
	_play_click()
	host_requested.emit()


func _set_status(text: String, is_error: bool) -> void:
	status.text = text
	status.modulate = Color("#ff8b83") if is_error else Color("#b9d8d3")
	_set_buttons_enabled(not is_error and not text.begins_with("Đang"))


func _set_buttons_enabled(enabled: bool) -> void:
	host_btn.disabled = not enabled
	name_edit.editable = enabled or name_edit.text.is_empty()


func _rebuild_room_list(rooms: Array) -> void:
	for child in room_list.get_children():
		child.queue_free()
	empty_hint.visible = rooms.is_empty()
	for room in rooms:
		var button := Button.new()
		button.text = "%s                                      %d / %d" % [
			room["label"], room["players"], room["max"]]
		button.custom_minimum_size.y = 42
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = room["players"] >= room["max"]
		button.tooltip_text = "Tham gia phòng %s" % room["label"]
		var room_id: String = room["id"]
		button.pressed.connect(func():
			_play_click()
			join_requested.emit(room_id))
		room_list.add_child(button)


func _open_settings() -> void:
	_play_click()
	settings_overlay.visible = true
	back_btn.grab_focus()


func _close_settings() -> void:
	_play_click()
	settings_overlay.visible = false
	_save_settings()
	settings_btn.grab_focus()


func _quit_game() -> void:
	_play_click()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()


func _set_volume(value: float) -> void:
	var linear := value / 100.0
	AudioServer.set_bus_volume_db(0, linear_to_db(linear) if linear > 0.0 else -80.0)
	AudioServer.set_bus_mute(0, value <= 0.0)
	volume_value.text = "%d%%" % roundi(value)


func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled
			else DisplayServer.WINDOW_MODE_WINDOWED)


func _set_camera_motion(enabled: bool) -> void:
	camera_motion_changed.emit(enabled)


func _load_settings() -> void:
	var config := ConfigFile.new()
	var volume := 80.0
	var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var motion := true
	if config.load(SETTINGS_PATH) == OK:
		volume = float(config.get_value("audio", "master_volume", volume))
		fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
		motion = bool(config.get_value("display", "menu_camera_motion", motion))
	volume_slider.value = volume
	fullscreen_check.button_pressed = fullscreen
	camera_motion_check.button_pressed = motion
	_set_volume(volume)
	_set_fullscreen(fullscreen)
	# Main kết nối signal sau khi các child chạy _ready; defer để trạng thái lưu được áp dụng.
	camera_motion_changed.emit.bind(motion).call_deferred()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", volume_slider.value)
	config.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("display", "menu_camera_motion", camera_motion_check.button_pressed)
	config.save(SETTINGS_PATH)


func _play_click() -> void:
	click_sound.play()
