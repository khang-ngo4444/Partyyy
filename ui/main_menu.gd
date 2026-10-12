extends Control

## Menu chính: điều hướng, kiểm tra nhập, hồ sơ cục bộ; việc mạng phát signal cho Main.
## Cài đặt / Cách chơi là scene riêng trong UILayer (group bang_cai_dat / bang_huong_dan).
## Phím: ←/→ chọn thẻ, Enter mở, 1–5 mở nhanh, Esc quay lại.

signal host_requested
signal join_requested(room_name: String)
signal refresh_requested
signal gameplay_confirmed(settings: Dictionary)
signal setup_leave_requested

const SETTINGS_PATH := "user://party_settings.cfg"
const NETWORK_TIMEOUT := 12.0

## [khoá, nhãn, min, max, hậu tố, loại ô (màu) hoặc ""]
const O_TI_LE := [
	["tile_land", "Ô Đất", "dat"], ["tile_health", "Ô Máu", "mau"],
	["tile_money", "Ô Tiền", "tien"], ["tile_equipment", "Ô Trang bị", "trang_bi"],
]
const O_LUAT := [
	["max_health", "Máu tối đa", 1, 100], ["start_gold", "Vàng đầu", 0, 9999],
	["health_gain", "Máu từ ô", 1, 100], ["money_gain", "Vàng từ ô", 1, 999],
	["chest_cost", "Giá rương", 1, 9999], ["respawn_steps", "Hồi sinh", 1, 999],
	["tax_health", "Thuế máu", 1, 100], ["tax_money", "Thuế vàng", 1, 999],
	["so_vong", "Số vòng", 0, 99],
]
const PRESET := {
	"CÂN BẰNG": [40, 20, 25, 15],
	"ĐẤT ĐAI": [55, 15, 20, 10],
	"GIÀU TO": [30, 15, 40, 15],
	"HỖN LOẠN": [25, 25, 20, 30],
}

@export var nut_dong_scene: PackedScene = null

var _gameplay_controls: Dictionary = {}
var _connected := false
var _busy := false
var _request_token := 0
var _rooms: Array = []
var _saved_player_name := ""
var _chi_sua_nhan_vat := false
var _thanh_ti_le := ThanhTiLe.new()

@onready var main_screen: Control = %MainScreen
@onready var online_screen: Control = %OnlineScreen
@onready var setup_screen: Control = %SetupScreen
@onready var logo: Control = %Logo
@onready var tile_row: HBoxContainer = %TileRow
@onready var play_btn: Button = %PlayBtn
@onready var character_btn: Button = %CharacterBtn
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
@onready var status_dot: Panel = %StatusDot
@onready var room_list: VBoxContainer = %RoomList
@onready var empty_hint: Label = %EmptyHint
@onready var quit_overlay: ColorRect = %QuitOverlay
@onready var quit_panel: Control = %QuitPanel
@onready var quit_cancel_btn: Button = %QuitCancelBtn
@onready var quit_confirm_btn: Button = %QuitConfirmBtn
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var character_creator: CharacterCreator = %CharacterCreator
@onready var setup_room: Label = %SetupRoom
@onready var setup_role: Label = %SetupRole
@onready var setup_controls: Control = %SetupControls
@onready var setup_status: Label = %SetupStatus
@onready var setup_confirm_btn: Button = %SetupConfirmBtn
@onready var setup_leave_btn: Button = %SetupLeaveBtn
@onready var percent_grid: VBoxContainer = %PercentGrid
@onready var rule_grid: GridContainer = %RuleGrid
@onready var preset_row: HBoxContainer = %PresetRow


func _ready() -> void:
	_load_profile()
	name_edit.text = (_saved_player_name if not _saved_player_name.is_empty()
			else "Player%d" % (randi() % 1000))
	name_edit.text_changed.connect(func(t): NetManager.player_name = t.strip_edges())
	NetManager.player_name = name_edit.text

	UIKit.the_nut(play_btn, "CHƠI ONLINE", "multiplayer", &"NutVang", Vector2(340, 208), 96, 36)
	UIKit.the_nut(character_btn, "NHÂN VẬT", "singleplayer", &"NutHong", Vector2(170, 190))
	UIKit.the_nut(how_to_btn, "CÁCH CHƠI", "question", &"NutTroi", Vector2(170, 190))
	UIKit.the_nut(settings_btn, "CÀI ĐẶT", "gear", &"NutLa", Vector2(170, 190))
	UIKit.the_nut(quit_btn, "THOÁT", "power", &"NutDo", Vector2(170, 190))
	var the := [play_btn, character_btn, how_to_btn, settings_btn, quit_btn]
	for i in the.size():
		UIKit.gan_phim(the[i], str(i + 1))
		(the[i] as Button).size_flags_vertical = Control.SIZE_SHRINK_END
	UIKit.noi_hang(the)
	UINav.lo_lung(logo, 5.0, 2.4)

	play_btn.pressed.connect(_open_character_creator.bind(false))
	character_btn.pressed.connect(_open_character_creator.bind(true))
	online_back_btn.pressed.connect(_show_main)
	how_to_btn.pressed.connect(_open_how_to)
	settings_btn.pressed.connect(_open_settings)
	quit_btn.pressed.connect(_open_quit_confirm)
	host_btn.pressed.connect(_request_host)
	join_code_btn.pressed.connect(_request_join_code)
	code_edit.text_submitted.connect(func(_text): _request_join_code())
	name_edit.text_submitted.connect(func(_text): host_btn.grab_focus())
	refresh_btn.pressed.connect(_refresh_rooms)
	quit_cancel_btn.pressed.connect(_close_quit_confirm)
	quit_confirm_btn.pressed.connect(_confirm_quit)
	character_creator.confirmed.connect(_on_character_confirmed)
	character_creator.cancelled.connect(_on_character_cancelled)
	setup_confirm_btn.pressed.connect(_confirm_gameplay)
	setup_leave_btn.pressed.connect(func(): setup_leave_requested.emit())

	NetManager.connected.connect(_on_connected)
	NetManager.connect_failed.connect(_on_connect_failed)
	NetManager.room_joined.connect(_on_room_joined)
	NetManager.room_left.connect(func(): _show_main(false))
	NetManager.room_list_changed.connect(_rebuild_room_list)

	_build_setup_controls()
	_set_gameplay_values(GameplaySettings.defaults())

	_show_main(false)
	_set_connection_text("Đang kết nối tới máy chủ…", Color("F5B041"))
	_set_online_controls()


# ---------- Bàn phím ----------

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if quit_overlay.visible:
			_close_quit_confirm()
		elif character_creator.visible:
			character_creator.close()
		elif online_screen.visible and not _busy:
			_show_main()
		elif setup_screen.visible:
			setup_leave_requested.emit()
		elif main_screen.visible:
			_open_quit_confirm()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	# Phím số mở nhanh thẻ ở màn chính.
	if main_screen.visible and not quit_overlay.visible and not character_creator.visible \
			and event is InputEventKey and event.pressed and not event.echo:
		var i: int = event.keycode - KEY_1
		var the := [play_btn, character_btn, how_to_btn, settings_btn, quit_btn]
		if i >= 0 and i < the.size():
			(the[i] as Button).grab_focus()
			(the[i] as Button).pressed.emit()
			get_viewport().set_input_as_handled()


# ---------- Chuyển màn ----------

func _show_main(play_sound := true) -> void:
	if play_sound:
		_play_click()
	main_screen.visible = true
	$Footer.visible = true
	online_screen.visible = false
	setup_screen.visible = false
	quit_overlay.visible = false
	character_creator.visible = false
	_busy = false
	_request_token += 1
	_set_online_controls()
	UINav.xuat_hien([logo] + tile_row.get_children(), 0.05)
	play_btn.grab_focus()


func _show_online(play_sound := true) -> void:
	if play_sound:
		_play_click()
	main_screen.visible = false
	$Footer.visible = false
	online_screen.visible = true
	setup_screen.visible = false
	_set_online_controls()
	_refresh_rooms(false)
	UINav.xuat_hien([%NameCard, %CodeCard, %RoomCard], 0.06)
	host_btn.grab_focus()


func _open_character_creator(chi_sua: bool) -> void:
	_play_click()
	_chi_sua_nhan_vat = chi_sua
	main_screen.visible = false
	character_creator.open()


func _on_character_confirmed() -> void:
	_play_click()
	_save_profile()
	if _chi_sua_nhan_vat:
		_show_main(false)
		character_btn.grab_focus()
	else:
		_show_online(false)


func _on_character_cancelled() -> void:
	main_screen.visible = true
	(character_btn if _chi_sua_nhan_vat else play_btn).grab_focus()


func _open_settings() -> void:
	_play_click()
	var bang := get_tree().get_first_node_in_group("bang_cai_dat") as BangCaiDat
	if bang == null:
		return
	if not bang.closed.is_connected(_on_settings_closed):
		bang.closed.connect(_on_settings_closed)
	bang.mo()


func _on_settings_closed() -> void:
	if visible and main_screen.visible:
		_play_click()
		settings_btn.grab_focus()


func _open_how_to() -> void:
	_play_click()
	var bang := get_tree().get_first_node_in_group("bang_huong_dan") as HowToGuide
	if bang == null:
		return
	if not bang.close_requested.is_connected(_on_how_to_closed):
		bang.close_requested.connect(_on_how_to_closed)
	bang.open()


func _on_how_to_closed() -> void:
	if visible and main_screen.visible:
		_play_click()
		how_to_btn.grab_focus()


func _open_quit_confirm() -> void:
	_play_click()
	quit_overlay.visible = true
	UINav.xuat_hien([quit_panel], 0.0, 0.7)
	quit_cancel_btn.grab_focus()


func _close_quit_confirm() -> void:
	_play_click()
	quit_overlay.visible = false
	quit_btn.grab_focus()


func _confirm_quit() -> void:
	_play_click()
	_save_profile()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()


# ---------- Online ----------

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
		UINav.lac(code_edit)
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
		UINav.lac(name_edit)
		name_edit.grab_focus()
		return false
	NetManager.player_name = name_edit.text.strip_edges()
	_save_profile()
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
	_save_profile()


func _on_connected() -> void:
	_connected = true
	_set_connection_text("Đã kết nối · sẵn sàng chơi!", UIKit.LA)
	_set_status("Chọn phòng đang mở, nhập mã hoặc tạo phòng mới.", false)
	_set_online_controls()


func _on_connect_failed(reason: String) -> void:
	_connected = false
	_busy = false
	_request_token += 1
	_set_connection_text("Không kết nối được máy chủ", UIKit.DO)
	_set_status("Lỗi kết nối: %s" % reason, true)
	_set_online_controls()


func _set_connection_text(text: String, mau: Color) -> void:
	main_status.text = text
	status_dot.add_theme_stylebox_override("panel", UIKit.hop(mau, 999, 0, 3, 0))


func _set_status(text: String, is_error: bool) -> void:
	status.text = text
	status.add_theme_color_override("font_color", UIKit.DO if is_error else UIKit.MUC)
	if is_error:
		UINav.lac(status.get_parent())


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
	var cu: Control = null
	for room in rooms:
		var button := nut_dong_scene.instantiate() as Button
		var full := int(room["players"]) >= int(room["max"])
		button.theme_type_variation = &"NutTrang" if full else &"NutVang"
		button.custom_minimum_size = Vector2(0, 68)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon = UIKit.icon("multiplayer")
		button.add_theme_constant_override("icon_max_width", 40)
		button.text = "%s     %d/%d%s" % [
			room["label"], room["players"], room["max"], "  · ĐẦY" if full else ""]
		button.set_meta("room_full", full)
		button.disabled = full or _busy or not _connected
		button.tooltip_text = ("Phòng đã đầy" if full
				else "Tham gia phòng %s" % room["label"])
		var room_id: String = room["id"]
		button.pressed.connect(func(): _join_room(room_id))
		room_list.add_child(button)
		cu = button
	if cu != null:
		UINav.xuat_hien(room_list.get_children(), 0.04, 0.8)
	if not _busy:
		_set_status(("Chưa có phòng mở. Bạn có thể tạo phòng đầu tiên." if rooms.is_empty()
				else "Chọn một phòng để tham gia."), false)


# ---------- Luật phòng ----------

func _build_setup_controls() -> void:
	percent_grid.add_child(_thanh_ti_le)
	for muc in O_TI_LE:
		var b := BuocSo.new(muc[1], UIKit.MAU_O[muc[2]].lerp(Color.WHITE, 0.55))
		b.min_value = 0
		b.max_value = 100
		b.step = 5
		b.suffix = "%"
		percent_grid.add_child(b)
		_gameplay_controls[muc[0]] = b
	for muc in O_LUAT:
		var b := BuocSo.new(muc[1])
		b.min_value = muc[2]
		b.max_value = muc[3]
		b.custom_minimum_size = Vector2(320, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if muc[0] == "so_vong":
			b.tooltip_text = "0 = tự tính theo số người"
		rule_grid.add_child(b)
		_gameplay_controls[muc[0]] = b
	for b: BuocSo in _gameplay_controls.values():
		b.value_changed.connect(func(_v): _refresh_gameplay_total())
	for ten in PRESET:
		var nut := Button.new()
		nut.text = ten
		nut.theme_type_variation = &"NutTrang"
		nut.add_theme_font_size_override("font_size", 18)
		nut.custom_minimum_size = Vector2(0, 44)
		nut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var gia: Array = PRESET[ten]
		nut.pressed.connect(func():
			_play_click()
			for i in 4:
				(_gameplay_controls[O_TI_LE[i][0]] as BuocSo).dat(gia[i])
			_refresh_gameplay_total()
			UINav.nay(_thanh_ti_le, 1.06))
		preset_row.add_child(nut)


func show_room_setup(is_host: bool, current: Dictionary = {}) -> void:
	main_screen.visible = false
	$Footer.visible = false
	online_screen.visible = false
	setup_screen.visible = true
	setup_room.text = "PHÒNG %s" % NetManager.room_name
	setup_role.text = ("Chọn luật rồi bấm VÀO SẢNH." if is_host
			else "Đang chờ chủ phòng chốt luật chơi…")
	setup_controls.visible = is_host
	setup_confirm_btn.visible = is_host
	if not current.is_empty():
		_set_gameplay_values(current)
	_refresh_gameplay_total()
	UINav.xuat_hien([%Body, setup_confirm_btn, setup_leave_btn], 0.06)
	(setup_confirm_btn if is_host else setup_leave_btn).grab_focus()


func _set_gameplay_values(values: Dictionary) -> void:
	var clean := GameplaySettings.sanitize(values)
	for key in _gameplay_controls:
		(_gameplay_controls[key] as BuocSo).dat(int(clean[key]))


func _gameplay_values() -> Dictionary:
	var values := GameplaySettings.defaults()
	for key in _gameplay_controls:
		values[key] = int((_gameplay_controls[key] as BuocSo).value)
	return GameplaySettings.sanitize(values)


func _refresh_gameplay_total() -> void:
	if not is_node_ready():
		return
	var values := _gameplay_values()
	var ti_le: Array = []
	for muc in O_TI_LE:
		ti_le.append(values[muc[0]])
	_thanh_ti_le.dat(ti_le)
	var total := GameplaySettings.percent_total(values)
	setup_status.text = ("Tổng tỷ lệ ô: %d%% — sẵn sàng!" % total if total == 100
			else "Tổng tỷ lệ ô: %d%% — phải đúng 100%%" % total)
	setup_status.add_theme_color_override("font_color", UIKit.MUC if total == 100 else UIKit.DO)
	setup_confirm_btn.disabled = total != 100


func _confirm_gameplay() -> void:
	var values := _gameplay_values()
	if not GameplaySettings.valid(values):
		_refresh_gameplay_total()
		UINav.lac(_thanh_ti_le)
		return
	_play_click()
	setup_confirm_btn.disabled = true
	setup_status.text = "Đang đồng bộ luật chơi…"
	gameplay_confirmed.emit(values)


# ---------- Hồ sơ ----------

func _load_profile() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	_saved_player_name = String(config.get_value("profile", "player_name", ""))
	NetManager.model_index = int(config.get_value("profile", "model_index", 0))
	NetManager.color_index = int(config.get_value("profile", "color_index", 0))
	NetManager.accent_index = int(config.get_value("profile", "accent_index", 1))
	NetManager.accessory_enabled = bool(config.get_value("profile", "accessory_enabled", true))


func _save_profile() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("profile", "player_name", name_edit.text.strip_edges())
	config.set_value("profile", "model_index", NetManager.model_index)
	config.set_value("profile", "color_index", NetManager.color_index)
	config.set_value("profile", "accent_index", NetManager.accent_index)
	config.set_value("profile", "accessory_enabled", NetManager.accessory_enabled)
	config.save(SETTINGS_PATH)


func _play_click() -> void:
	click_sound.play()
