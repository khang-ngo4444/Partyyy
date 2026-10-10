extends Control

## Menu chính: điều hướng, kiểm tra nhập, cài đặt cục bộ; việc mạng phát signal cho Main.

signal host_requested
signal join_requested(room_name: String)
signal refresh_requested
signal camera_motion_changed(enabled: bool)
signal gameplay_confirmed(settings: Dictionary)
signal setup_leave_requested

const SETTINGS_PATH := "user://party_settings.cfg"
const NETWORK_TIMEOUT := 12.0
const GRAPHICS_AUTO := 0
const GRAPHICS_QUALITY := 3

@export var nut_dong_scene: PackedScene = null

var _gameplay_controls: Dictionary = {}
var _connected := false
var _busy := false
var _request_token := 0
var _rooms: Array = []
var _saved_player_name := ""

@onready var main_screen: VBoxContainer = %MainScreen
@onready var online_screen: VBoxContainer = %OnlineScreen
@onready var setup_screen: VBoxContainer = %SetupScreen
@onready var play_btn: Button = %PlayBtn
@onready var how_to_btn: Button = %HowToBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var quit_btn: Button = %QuitBtn
@onready var online_back_btn: Button = %OnlineBackBtn
@onready var name_edit: LineEdit = %NameEdit
@onready var host_btn: Button = %HostBtn
@onready var code_edit: LineEdit = %CodeEdit
@onready var join_code_btn: Button = %JoinCodeBtn
@onready var refresh_btn: Button = %RefreshBtn
@onready var status: Label = %Status
@onready var main_status: Label = %MainStatus
@onready var room_list: VBoxContainer = %RoomList
@onready var empty_hint: Label = %EmptyHint
@onready var settings_overlay: ColorRect = %SettingsOverlay
@onready var how_to_overlay: HowToGuide = %HowToOverlay
@onready var quit_overlay: ColorRect = %QuitOverlay
@onready var back_btn: Button = %BackBtn
@onready var quit_cancel_btn: Button = %QuitCancelBtn
@onready var quit_confirm_btn: Button = %QuitConfirmBtn
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var camera_motion_check: CheckButton = %CameraMotionCheck
@onready var graphics_option: OptionButton = %GraphicsOption
@onready var performance_manager: Node = get_node("/root/PerformanceManager")
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var character_creator: CharacterCreator = %CharacterCreator
@onready var setup_room: Label = %SetupRoom
@onready var setup_role: Label = %SetupRole
@onready var setup_controls: Control = %SetupControls
@onready var setup_status: Label = %SetupStatus
@onready var setup_confirm_btn: Button = %SetupConfirmBtn
@onready var setup_leave_btn: Button = %SetupLeaveBtn
@onready var tile_land: SpinBox = %TileLand
@onready var tile_health: SpinBox = %TileHealth
@onready var tile_money: SpinBox = %TileMoney
@onready var tile_equipment: SpinBox = %TileEquipment
@onready var max_health: SpinBox = %MaxHealth
@onready var start_gold: SpinBox = %StartGold
@onready var health_gain: SpinBox = %HealthGain
@onready var money_gain: SpinBox = %MoneyGain
@onready var chest_cost: SpinBox = %ChestCost
@onready var respawn_steps: SpinBox = %RespawnSteps
@onready var tax_health: SpinBox = %TaxHealth
@onready var tax_money: SpinBox = %TaxMoney
@onready var so_vong: SpinBox = %SoVong


func _ready() -> void:
	_load_settings()
	name_edit.text = (_saved_player_name if not _saved_player_name.is_empty()
			else "Player%d" % (randi() % 1000))
	name_edit.text_changed.connect(func(t): NetManager.player_name = t.strip_edges())
	NetManager.player_name = name_edit.text

	play_btn.pressed.connect(_open_character_creator)
	online_back_btn.pressed.connect(_show_main)
	how_to_btn.pressed.connect(_open_how_to)
	settings_btn.pressed.connect(_open_settings)
	quit_btn.pressed.connect(_open_quit_confirm)
	host_btn.pressed.connect(_request_host)
	join_code_btn.pressed.connect(_request_join_code)
	code_edit.text_submitted.connect(func(_text): _request_join_code())
	refresh_btn.pressed.connect(_refresh_rooms)
	back_btn.pressed.connect(_close_settings)
	how_to_overlay.close_requested.connect(_close_how_to)
	quit_cancel_btn.pressed.connect(_close_quit_confirm)
	quit_confirm_btn.pressed.connect(_confirm_quit)
	volume_slider.value_changed.connect(_set_volume)
	fullscreen_check.toggled.connect(_set_fullscreen)
	camera_motion_check.toggled.connect(_set_camera_motion)
	graphics_option.item_selected.connect(_set_graphics_mode)
	character_creator.confirmed.connect(_on_character_confirmed)
	character_creator.cancelled.connect(func(): play_btn.grab_focus())
	setup_confirm_btn.pressed.connect(_confirm_gameplay)
	setup_leave_btn.pressed.connect(func(): setup_leave_requested.emit())

	NetManager.connected.connect(_on_connected)
	NetManager.connect_failed.connect(_on_connect_failed)
	NetManager.room_joined.connect(_on_room_joined)
	NetManager.room_left.connect(func(): _show_main(false))
	NetManager.room_list_changed.connect(_rebuild_room_list)

	_gameplay_controls = {
		"tile_land": tile_land,
		"tile_health": tile_health,
		"tile_money": tile_money,
		"tile_equipment": tile_equipment,
		"max_health": max_health,
		"start_gold": start_gold,
		"health_gain": health_gain,
		"money_gain": money_gain,
		"chest_cost": chest_cost,
		"respawn_steps": respawn_steps,
		"tax_health": tax_health,
		"tax_money": tax_money,
		"so_vong": so_vong,
	}
	for control: SpinBox in _gameplay_controls.values():
		control.value_changed.connect(func(_value): _refresh_gameplay_total())
	_set_gameplay_values(GameplaySettings.defaults())

	_show_main(false)
	_set_connection_text("Đang kết nối tới máy chủ…")
	_set_online_controls()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if quit_overlay.visible:
		_close_quit_confirm()
	elif character_creator.visible:
		character_creator.close()
	elif how_to_overlay.visible:
		_close_how_to()
	elif settings_overlay.visible:
		_close_settings()
	elif online_screen.visible and not _busy:
		_show_main()
	elif setup_screen.visible:
		setup_leave_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func _show_main(play_sound := true) -> void:
	if play_sound:
		_play_click()
	main_screen.visible = true
	online_screen.visible = false
	setup_screen.visible = false
	settings_overlay.visible = false
	how_to_overlay.visible = false
	quit_overlay.visible = false
	character_creator.visible = false
	_busy = false
	_request_token += 1
	_set_online_controls()
	play_btn.grab_focus()


func _show_online(play_sound := true) -> void:
	if play_sound:
		_play_click()
	main_screen.visible = false
	online_screen.visible = true
	setup_screen.visible = false
	_set_online_controls()
	_refresh_rooms(false)
	host_btn.grab_focus()


func _open_character_creator() -> void:
	_play_click()
	character_creator.open()


func _on_character_confirmed() -> void:
	_play_click()
	_save_settings()
	_show_online(false)


func _request_host() -> void:
	if not _validate_name():
		return
	_play_click()
	_begin_network_request("Đang tạo phòng…")
	host_requested.emit()


func _request_join_code() -> void:
	if _busy:
		return
	if not _validate_name():
		return
	var room_code := code_edit.text.strip_edges()
	if room_code.is_empty():
		_set_status("Nhập đúng mã phòng mà chủ phòng đã chia sẻ.", true)
		code_edit.grab_focus()
		return
	_play_click()
	_begin_network_request("Đang vào phòng %s…" % room_code)
	join_requested.emit(room_code)


func _join_room(room_id: String) -> void:
	if _busy or not _validate_name():
		return
	_play_click()
	_begin_network_request("Đang vào phòng %s…" % room_id)
	join_requested.emit(room_id)


func _validate_name() -> bool:
	if name_edit.text.strip_edges().is_empty():
		_set_status("Hãy nhập tên người chơi trước.", true)
		name_edit.grab_focus()
		return false
	NetManager.player_name = name_edit.text.strip_edges()
	_save_settings()
	return true


func _begin_network_request(message: String) -> void:
	_busy = true
	_request_token += 1
	var token := _request_token
	_set_status(message, false)
	_set_online_controls()
	await get_tree().create_timer(NETWORK_TIMEOUT).timeout
	if token != _request_token or not _busy or not is_inside_tree():
		return
	_busy = false
	_set_status("Yêu cầu mất quá nhiều thời gian. Hãy kiểm tra mã phòng hoặc thử lại.", true)
	_set_online_controls()


func _on_room_joined() -> void:
	_busy = false
	_request_token += 1
	_save_settings()


func show_room_setup(is_host: bool, current: Dictionary = {}) -> void:
	main_screen.visible = false
	online_screen.visible = false
	setup_screen.visible = true
	settings_overlay.visible = false
	setup_room.text = "PHÒNG %s" % NetManager.room_name
	setup_role.text = ("Chọn luật rồi xác nhận để mở sảnh." if is_host
			else "Đang chờ chủ phòng chốt luật chơi…")
	setup_controls.visible = is_host
	setup_confirm_btn.visible = is_host
	if not current.is_empty():
		_set_gameplay_values(current)
	_refresh_gameplay_total()
	(setup_confirm_btn if is_host else setup_leave_btn).grab_focus()


func _set_gameplay_values(values: Dictionary) -> void:
	var clean := GameplaySettings.sanitize(values)
	for key in _gameplay_controls:
		(_gameplay_controls[key] as SpinBox).value = int(clean[key])


func _gameplay_values() -> Dictionary:
	var values := GameplaySettings.defaults()
	for key in _gameplay_controls:
		values[key] = int((_gameplay_controls[key] as SpinBox).value)
	return GameplaySettings.sanitize(values)


func _refresh_gameplay_total() -> void:
	if not is_node_ready():
		return
	var total := GameplaySettings.percent_total(_gameplay_values())
	setup_status.text = "Tổng tỷ lệ ô: %d%% %s" % [total,
			"— sẵn sàng" if total == 100 else "— phải bằng 100%"]
	setup_status.modulate = Color("#9ff4d8") if total == 100 else Color("#ff9b93")
	setup_confirm_btn.disabled = total != 100


func _confirm_gameplay() -> void:
	var values := _gameplay_values()
	if not GameplaySettings.valid(values):
		_refresh_gameplay_total()
		return
	_play_click()
	setup_confirm_btn.disabled = true
	setup_status.text = "Đang đồng bộ luật chơi…"
	gameplay_confirmed.emit(values)


func _on_connected() -> void:
	_connected = true
	_set_connection_text("Đã kết nối • Sẵn sàng chơi online.")
	_set_status("Chọn phòng đang mở, nhập mã hoặc tạo phòng mới.", false)
	_set_online_controls()


func _on_connect_failed(reason: String) -> void:
	_connected = false
	_busy = false
	_request_token += 1
	_set_connection_text("Không thể kết nối online.")
	_set_status("Lỗi kết nối: %s" % reason, true)
	_set_online_controls()


func _set_connection_text(text: String) -> void:
	main_status.text = text


func _set_status(text: String, is_error: bool) -> void:
	status.text = text
	status.modulate = Color("#ff9b93") if is_error else Color("#b9d8d3")


func _set_online_controls() -> void:
	var enabled := _connected and not _busy
	host_btn.disabled = not enabled
	join_code_btn.disabled = not enabled
	refresh_btn.disabled = not enabled
	code_edit.editable = not _busy
	name_edit.editable = not _busy
	online_back_btn.disabled = _busy
	for child in room_list.get_children():
		if child is Button:
			child.disabled = not enabled or bool(child.get_meta("room_full", false))


func _refresh_rooms(play_sound := true) -> void:
	if not _connected or _busy:
		return
	if play_sound:
		_play_click()
	_set_status("Đang cập nhật danh sách phòng…", false)
	refresh_requested.emit()


func _rebuild_room_list(rooms: Array) -> void:
	_rooms = rooms
	for child in room_list.get_children():
		child.queue_free()
	empty_hint.visible = rooms.is_empty()
	for room in rooms:
		var button := nut_dong_scene.instantiate() as Button
		var full := int(room["players"]) >= int(room["max"])
		button.text = "%s    ·    %d/%d%s" % [
			room["label"], room["players"], room["max"], "    ĐẦY" if full else ""]
		button.set_meta("room_full", full)
		button.disabled = full or _busy or not _connected
		button.tooltip_text = ("Phòng đã đầy" if full
				else "Tham gia phòng %s" % room["label"])
		var room_id: String = room["id"]
		button.pressed.connect(func(): _join_room(room_id))
		room_list.add_child(button)
	if not _busy:
		_set_status(("Chưa có phòng mở. Bạn có thể tạo phòng đầu tiên." if rooms.is_empty()
				else "Chọn một phòng để tham gia."), false)


func _open_settings() -> void:
	_play_click()
	settings_overlay.visible = true
	back_btn.grab_focus()


func _close_settings() -> void:
	_play_click()
	settings_overlay.visible = false
	_save_settings()
	settings_btn.grab_focus()


func _open_how_to() -> void:
	_play_click()
	how_to_overlay.open()


func _close_how_to() -> void:
	_play_click()
	how_to_overlay.close()
	how_to_btn.grab_focus()


func _open_quit_confirm() -> void:
	_play_click()
	quit_overlay.visible = true
	quit_cancel_btn.grab_focus()


func _close_quit_confirm() -> void:
	_play_click()
	quit_overlay.visible = false
	quit_btn.grab_focus()


func _confirm_quit() -> void:
	_play_click()
	_save_settings()
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


func _set_graphics_mode(index: int) -> void:
	performance_manager.call("set_graphics_mode", graphics_option.get_item_id(index))


func _load_settings() -> void:
	var config := ConfigFile.new()
	var volume := 80.0
	var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var motion := true
	var graphics_mode := GRAPHICS_AUTO
	if config.load(SETTINGS_PATH) == OK:
		volume = float(config.get_value("audio", "master_volume", volume))
		fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
		motion = bool(config.get_value("display", "menu_camera_motion", motion))
		graphics_mode = int(config.get_value("display", "graphics_mode", graphics_mode))
		_saved_player_name = String(config.get_value("profile", "player_name", ""))
		NetManager.model_index = int(config.get_value("profile", "model_index", 0))
		NetManager.color_index = int(config.get_value("profile", "color_index", 0))
		NetManager.accent_index = int(config.get_value("profile", "accent_index", 1))
		NetManager.accessory_enabled = bool(
				config.get_value("profile", "accessory_enabled", true))
	graphics_mode = clampi(graphics_mode, GRAPHICS_AUTO, GRAPHICS_QUALITY)
	volume_slider.value = volume
	fullscreen_check.button_pressed = fullscreen
	camera_motion_check.button_pressed = motion
	graphics_option.select(graphics_option.get_item_index(graphics_mode))
	_set_volume(volume)
	_set_fullscreen(fullscreen)
	performance_manager.call("set_graphics_mode", graphics_mode)
	# Node cha nối signal sau `_ready` của con — gọi trễ để giữ trạng thái đã lưu.
	camera_motion_changed.emit.bind(motion).call_deferred()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", volume_slider.value)
	config.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("display", "menu_camera_motion", camera_motion_check.button_pressed)
	config.set_value("display", "graphics_mode",
			graphics_option.get_item_id(graphics_option.selected))
	config.set_value("profile", "player_name", name_edit.text.strip_edges())
	config.set_value("profile", "model_index", NetManager.model_index)
	config.set_value("profile", "color_index", NetManager.color_index)
	config.set_value("profile", "accent_index", NetManager.accent_index)
	config.set_value("profile", "accessory_enabled", NetManager.accessory_enabled)
	config.save(SETTINGS_PATH)


func _play_click() -> void:
	click_sound.play()
