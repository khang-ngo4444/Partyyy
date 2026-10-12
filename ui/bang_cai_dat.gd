class_name BangCaiDat
extends ColorRect

## Cài đặt dùng chung (menu chính + Esc trong game). Tự nạp/lưu phần audio/display
## của `user://party_settings.cfg` (phần profile do MainMenu lưu).
## Mở: get_tree().get_first_node_in_group("bang_cai_dat").mo()

signal camera_motion_changed(enabled: bool)
signal closed

const SETTINGS_PATH := "user://party_settings.cfg"
const CHAT_LUONG := [
	[0, "TỰ ĐỘNG", "Giữ 60 FPS", "wrench"],
	[1, "MƯỢT", "Ưu tiên FPS", "fastForward"],
	[2, "CÂN BẰNG", "Vừa đẹp vừa nhanh", "contrast"],
	[3, "ĐẸP", "Ưu tiên hình ảnh", "star"],
]
const PHIM := [
	["W A S D", "Di chuyển"], ["Space", "Nhảy / tung xúc xắc"], ["E", "Tương tác / dùng đồ"],
	["Chuột trái", "Đánh / bắn trong minigame"], ["Z / X", "Đổi hướng, đổi mục tiêu (bàn)"],
	["1 – 5", "Dùng đồ ô nhanh / chọn nhanh"], ["Tab", "Kho đồ (bàn party)"], ["C", "Cam tự do / gắn nhân vật"], ["V", "Đổi người theo dõi"], ["M", "Đổi nhân vật (sảnh)"], ["Enter", "Chat"],
	["Esc", "Menu / quay lại"], ["Tab / Q · E", "Đổi tab"],
]

var _chat_luong_nut: Array[Button] = []
var _dang_nap := false

@onready var tabs: TabContainer = %Tabs
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var camera_motion_check: CheckButton = %CameraMotionCheck
@onready var reduce_motion_check: CheckButton = %ReduceMotionCheck
@onready var ui_scale_slider: HSlider = %UiScaleSlider
@onready var ui_scale_value: Label = %UiScaleValue
@onready var chat_luong_hang: HBoxContainer = %ChatLuongHang
@onready var bang_phim: GridContainer = %BangPhim
@onready var xong_btn: Button = %XongBtn
@onready var mac_dinh_btn: Button = %MacDinhBtn
@onready var panel: Control = %Panel
@onready var performance_manager: Node = get_node("/root/PerformanceManager")


func _ready() -> void:
	add_to_group("bang_cai_dat")
	visible = false
	var nhom := ButtonGroup.new()
	for muc in CHAT_LUONG:
		var b := UIKit.the_nut(Button.new(), "%s\n%s" % [muc[1], muc[2]], muc[3],
				&"NutTrang", Vector2(150, 150), 52, 20)
		b.toggle_mode = true
		b.button_group = nhom
		b.set_meta("id", muc[0])
		b.toggled.connect(func(on): if on: _dat_chat_luong(int(muc[0])))
		chat_luong_hang.add_child(b)
		_chat_luong_nut.append(b)
	UIKit.noi_hang(_chat_luong_nut)
	for p in PHIM:
		var k := UIKit.chip_phim(p[0], "", false)
		bang_phim.add_child(k)
		var lb := Label.new()
		lb.text = p[1]
		bang_phim.add_child(lb)
	volume_slider.value_changed.connect(_set_volume)
	ui_scale_slider.value_changed.connect(_set_ui_scale)
	fullscreen_check.toggled.connect(_set_fullscreen)
	camera_motion_check.toggled.connect(func(on): camera_motion_changed.emit(on); _luu())
	reduce_motion_check.toggled.connect(func(on): UINav.giam_chuyen_dong = on; _luu())
	xong_btn.pressed.connect(dong)
	mac_dinh_btn.pressed.connect(_mac_dinh)
	tabs.tab_changed.connect(func(_i): _focus_dau_tab())
	_nap()


func mo() -> void:
	visible = true
	tabs.current_tab = 0
	UINav.xuat_hien([panel], 0.0, 0.8)
	_focus_dau_tab()


func dong() -> void:
	if not visible:
		return
	visible = false
	_luu()
	closed.emit()


func _focus_dau_tab() -> void:
	var trang := tabs.get_current_tab_control()
	var dau := trang.find_next_valid_focus() if trang != null else null
	if dau != null and trang.is_ancestor_of(dau):
		dau.grab_focus()
	else:
		xong_btn.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		dong()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k == KEY_TAB or k == KEY_E or k == KEY_Q:
			var lui: bool = k == KEY_Q or (k == KEY_TAB and event.shift_pressed)
			tabs.current_tab = posmod(tabs.current_tab + (-1 if lui else 1), tabs.get_tab_count())
			get_viewport().set_input_as_handled()


func _set_volume(value: float) -> void:
	var linear := value / 100.0
	AudioServer.set_bus_volume_db(0, linear_to_db(linear) if linear > 0.0 else -80.0)
	AudioServer.set_bus_mute(0, value <= 0.0)
	volume_value.text = "%d%%" % roundi(value)
	if not _dang_nap:
		UINav.nay(volume_value, 1.15)


func _set_ui_scale(value: float) -> void:
	ui_scale_value.text = "%d%%" % roundi(value)
	UINav.ap_co_ui(value / 100.0)


func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled
			else DisplayServer.WINDOW_MODE_WINDOWED)


func _dat_chat_luong(id: int) -> void:
	performance_manager.call("set_graphics_mode", id)
	if not _dang_nap:
		_luu()


func _chat_luong_hien_tai() -> int:
	for b in _chat_luong_nut:
		if b.button_pressed:
			return int(b.get_meta("id"))
	return 0


func _mac_dinh() -> void:
	volume_slider.value = 80
	ui_scale_slider.value = 100
	fullscreen_check.button_pressed = false
	camera_motion_check.button_pressed = true
	reduce_motion_check.button_pressed = false
	_chat_luong_nut[0].button_pressed = true


func _nap() -> void:
	_dang_nap = true
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	var volume := float(cfg.get_value("audio", "master_volume", 80.0))
	var fullscreen := bool(cfg.get_value("display", "fullscreen",
			DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN))
	var motion := bool(cfg.get_value("display", "menu_camera_motion", true))
	var giam := bool(cfg.get_value("display", "reduce_motion", false))
	var co := float(cfg.get_value("display", "ui_scale", 1.0))
	var mode := clampi(int(cfg.get_value("display", "graphics_mode", 0)), 0, 3)
	volume_slider.value = volume
	_set_volume(volume)
	ui_scale_slider.value = co * 100.0
	fullscreen_check.button_pressed = fullscreen
	_set_fullscreen(fullscreen)
	camera_motion_check.set_pressed_no_signal(motion)
	reduce_motion_check.set_pressed_no_signal(giam)
	UINav.giam_chuyen_dong = giam
	_chat_luong_nut[mode].button_pressed = true
	performance_manager.call("set_graphics_mode", mode)
	# Node cha nối signal sau `_ready` của con — phát trễ để giữ trạng thái đã lưu.
	camera_motion_changed.emit.bind(motion).call_deferred()
	_dang_nap = false


func _luu() -> void:
	if _dang_nap:
		return
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master_volume", volume_slider.value)
	cfg.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	cfg.set_value("display", "menu_camera_motion", camera_motion_check.button_pressed)
	cfg.set_value("display", "reduce_motion", reduce_motion_check.button_pressed)
	cfg.set_value("display", "ui_scale", ui_scale_slider.value / 100.0)
	cfg.set_value("display", "graphics_mode", _chat_luong_hien_tai())
	cfg.save(SETTINGS_PATH)
