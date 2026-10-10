extends Control

## Màn trộn màu đèn cả phòng. Hai nguồn A/B (gradient) hoặc một màu.
## Chỉ gửi RPC khi bấm ÁP DỤNG (không nối `color_changed` để tránh vài trăm gói tin).

signal mau_da_chon(mau_a: Color, mau_b: Color, hai_mau: bool)
signal xin_mau_goc

## Màu đặt sẵn.
const DAT_SAN: Array[Color] = [
	Color("ffc46b"), Color("ffffff"), Color("ff5fa2"),
	Color("4d8cff"), Color("46d97a"), Color("a56bff"),
	Color("ff3b30"), Color("00e5ff"),
]

## Chừa quanh mép màn hình (px).
const CHUA_LE := 28.0
const RONG_TOI_DA := 520.0

@export var o_mau_scene: PackedScene = null

var _mau := [Color("ffc46b"), Color("4d8cff")]

## 0 = A, 1 = B.
var _dang_sua := 0
var _dai := GradientTexture2D.new()

@onready var _khung: PanelContainer = %Panel
@onready var _banh_xe: ColorPicker = %Wheel
@onready var _dat_san: GridContainer = %PresetGrid
@onready var _o_a: OMau = %ChipA
@onready var _o_b: OMau = %ChipB
@onready var _bat_b: CheckButton = %TwoToggle
@onready var _xem_truoc: TextureRect = %GradientPreview


func _ready() -> void:
	visible = false
	%CloseButton.pressed.connect(dong)
	%ResetButton.pressed.connect(func():
		xin_mau_goc.emit()
		dong())
	%ApplyButton.pressed.connect(func():
		mau_da_chon.emit(_mau[0], _mau[1], _bat_b.button_pressed)
		dong())

	_banh_xe.edit_alpha = false
	_banh_xe.can_add_swatches = false
	_banh_xe.sampler_visible = false
	_banh_xe.color_changed.connect(func(c: Color):
		_mau[_dang_sua] = c
		_ve_lai())

	_o_a.pressed.connect(func(): _chon_o(0))
	# Bấm ô B là tự bật chế độ hai nguồn.
	_o_b.pressed.connect(func():
		_bat_b.button_pressed = true
		_chon_o(1))
	_bat_b.toggled.connect(func(_on): _ve_lai())

	_dai.gradient = Gradient.new()
	_dai.fill_from = Vector2(0, 0.5)
	_dai.fill_to = Vector2(1, 0.5)
	_xem_truoc.texture = _dai

	for m in DAT_SAN:
		var b := o_mau_scene.instantiate() as OMau
		b.dat(m)
		var mau := m
		# Màu đặt sẵn gán vào ô đang sửa.
		b.pressed.connect(func():
			_mau[_dang_sua] = mau
			_banh_xe.color = mau
			_ve_lai())
		_dat_san.add_child(b)

	_chon_o(0)
	# Phải kiểm `is_inside_tree`: tín hiệu không tự ngắt khi node rời cây.
	get_viewport().size_changed.connect(func():
		if is_inside_tree():
			_vua_man_hinh())


func mo() -> void:
	visible = true
	_vua_man_hinh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func dong() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		dong()


## Ép bảng nằm gọn trong màn hình; nội dung dài thì cuộn.
func _vua_man_hinh() -> void:
	var man := get_viewport_rect().size
	var rong := minf(RONG_TOI_DA, man.x - CHUA_LE * 2.0)
	var cao := man.y - CHUA_LE * 2.0
	_khung.offset_left = -rong * 0.5
	_khung.offset_right = rong * 0.5
	_khung.offset_top = -cao * 0.5
	_khung.offset_bottom = cao * 0.5


func _chon_o(i: int) -> void:
	_dang_sua = i
	_banh_xe.color = _mau[i]
	_ve_lai()


func _ve_lai() -> void:
	var hai := _bat_b.button_pressed
	# Tắt hai nguồn thì quay về sửa ô A.
	if not hai and _dang_sua == 1:
		_dang_sua = 0
		_banh_xe.color = _mau[0]
	# Ô B mờ khi không dùng, vẫn bấm được.
	_o_b.modulate = Color(1, 1, 1, 1.0 if hai else 0.45)
	_o_a.dat(_mau[0], _dang_sua == 0)
	_o_b.dat(_mau[1], _dang_sua == 1)
	_dai.gradient.set_color(0, _mau[0])
	_dai.gradient.set_color(1, _mau[1] if hai else _mau[0])
