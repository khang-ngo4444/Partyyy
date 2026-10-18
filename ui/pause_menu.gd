extends Control

## Màn Esc — nơi duy nhất đổi `Input.mouse_mode`.
## Lưới thẻ to: Tiếp tục / Nhân vật / Cài đặt / Cách chơi / Rời phòng / Thoát.
## Phím: mũi tên chọn, Enter mở, 1–6 mở nhanh, Esc đóng. Rời/Thoát có hộp xác nhận.

@onready var leave_button: Button = %LeaveButton
@onready var resume_button: Button = %ResumeButton
@onready var character_button: Button = %CharacterButton
@onready var settings_button: Button = %SettingsButton
@onready var howto_button: Button = %HowToButton
@onready var quit_button: Button = %QuitButton
@onready var the: Control = %The
@onready var room_label: Label = %RoomCode
@onready var xac_nhan: Control = %XacNhan
@onready var xac_nhan_the: Control = %XacNhanThe
@onready var xac_nhan_tieu_de: Label = %XacNhanTieuDe
@onready var xac_nhan_loi: Label = %XacNhanLoi
@onready var xac_nhan_co: Button = %XacNhanCo
@onready var xac_nhan_khong: Button = %XacNhanKhong

var _viec_xac_nhan: Callable
var _nut_quay_ve: Button


func _ready() -> void:
	# `visible = false` đặt trong .tscn.
	UIKit.the_nut(resume_button, "TIẾP TỤC", "right", &"NutVang", Vector2(300, 200), 88, 34)
	UIKit.the_nut(character_button, "NHÂN VẬT", "singleplayer", &"NutHong", Vector2(160, 160), 60, 22)
	UIKit.the_nut(settings_button, "CÀI ĐẶT", "gear", &"NutLa", Vector2(160, 160), 60, 22)
	UIKit.the_nut(howto_button, "CÁCH CHƠI", "question", &"NutTroi", Vector2(160, 160), 60, 22)
	UIKit.the_nut(leave_button, "RỜI PHÒNG", "exitLeft", &"NutCam", Vector2(160, 160), 60, 22)
	UIKit.the_nut(quit_button, "THOÁT GAME", "power", &"NutDo", Vector2(160, 160), 60, 22)
	var ds := _cac_the()
	for i in ds.size():
		UIKit.gan_phim(ds[i], str(i + 1))
	UIKit.gan_phim(xac_nhan_khong, "Esc")

	resume_button.pressed.connect(_dong)
	character_button.pressed.connect(func():
		var picker = get_tree().get_first_node_in_group("chon_nhan_vat")
		_dong()
		if picker != null:
			picker.mo())
	settings_button.pressed.connect(_mo_bang.bind("bang_cai_dat", settings_button))
	howto_button.pressed.connect(_mo_bang.bind("bang_huong_dan", howto_button))
	leave_button.pressed.connect(func(): _hoi("RỜI PHÒNG?",
			"Bạn sẽ rời phòng hiện tại và quay về menu chính.", "RỜI PHÒNG", func():
				_dong()
				NetManager.leave_room(), leave_button))
	quit_button.pressed.connect(func(): _hoi("THOÁT GAME?",
			"Bữa tiệc vẫn còn đang vui mà!", "THOÁT", get_tree().quit, quit_button))
	xac_nhan_co.pressed.connect(func():
		_tat_hoi()
		_viec_xac_nhan.call())
	xac_nhan_khong.pressed.connect(_tat_hoi)
	%CopyBtn.pressed.connect(func():
		DisplayServer.clipboard_set(NetManager.room_name)
		%CopyBtn.text = "ĐÃ CHÉP!"
		UINav.nay(%CopyBtn))
	NetManager.room_joined.connect(func(): leave_button.disabled = false)
	NetManager.room_left.connect(func(): leave_button.disabled = true)
	leave_button.disabled = true
	xac_nhan.visible = false


func _cac_the() -> Array[Button]:
	return [resume_button, character_button, settings_button, howto_button,
			leave_button, quit_button]


func _input(event: InputEvent) -> void:
	# Phím số mở nhanh thẻ khi menu đang mở (không có hộp xác nhận).
	if visible and not xac_nhan.visible and not _bang_dang_mo() and event is InputEventKey \
			and event.pressed and not event.echo:
		var i: int = event.keycode - KEY_1
		var ds := _cac_the()
		if i >= 0 and i < ds.size() and ds[i].visible and not ds[i].disabled:
			get_viewport().set_input_as_handled()
			ds[i].grab_focus()
			ds[i].pressed.emit()
			return
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
	if xac_nhan.visible:
		_tat_hoi()
	elif visible:
		_dong()
	else:
		_mo()


func _bang_dang_mo() -> bool:
	for nhom in ["bang_cai_dat", "bang_huong_dan"]:
		var b = get_tree().get_first_node_in_group(nhom)
		if b != null and b.visible:
			return true
	return false


func _mo() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	room_label.text = NetManager.room_name
	%CopyBtn.text = "CHÉP MÃ"
	var main := get_tree().current_scene
	character_button.visible = main != null and main.has_method("dang_o_sanh") \
			and main.dang_o_sanh()
	UINav.xuat_hien([the] + _cac_the(), 0.035, 0.75)
	resume_button.grab_focus()


func _dong() -> void:
	visible = false
	xac_nhan.visible = false
	# Chưa vào phòng thì trả chuột cho menu chính.
	Input.mouse_mode = (Input.MOUSE_MODE_VISIBLE if leave_button.disabled
			else Input.MOUSE_MODE_CAPTURED)


## Mở bảng dùng chung (Cài đặt / Cách chơi) đè lên; đóng xong trả focus về thẻ.
func _mo_bang(nhom: String, nut: Button) -> void:
	var bang = get_tree().get_first_node_in_group(nhom)
	if bang == null:
		return
	var tin_hieu: Signal = bang.closed if bang is BangCaiDat else bang.close_requested
	if not tin_hieu.is_connected(_khi_dong_bang):
		tin_hieu.connect(_khi_dong_bang)
	_nut_quay_ve = nut
	if bang is BangCaiDat:
		bang.mo()
	else:
		var controller := get_tree().get_first_node_in_group("quan_tro")
		if controller != null and controller.dang_chay():
			bang.open_for_game(controller.ma_dang_choi())
		else:
			bang.open()


func _khi_dong_bang() -> void:
	if visible and _nut_quay_ve != null:
		_nut_quay_ve.grab_focus()


func _hoi(tieu_de: String, loi: String, chu_co: String, viec: Callable, nut: Button) -> void:
	_viec_xac_nhan = viec
	_nut_quay_ve = nut
	xac_nhan_tieu_de.text = tieu_de
	xac_nhan_loi.text = loi
	xac_nhan_co.text = chu_co
	xac_nhan.visible = true
	UINav.xuat_hien([xac_nhan_the], 0.0, 0.7)
	xac_nhan_khong.grab_focus()


func _tat_hoi() -> void:
	xac_nhan.visible = false
	if _nut_quay_ve != null and visible:
		_nut_quay_ve.grab_focus()
