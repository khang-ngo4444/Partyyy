extends Control

## Màn hình trộn màu đèn, mở từ nút DOI MAU DEN trên tường phòng chờ.
##
## Màu là trạng thái CẢ PHÒNG: chọn xong là gửi RPC, mọi người đổi theo, người vào muộn đọc
## lại từ `MatchState`. Màn hình này không giữ gì riêng ngoài hai màu đang soạn.
##
## HAI NGUỒN: bấm ô A hoặc B để chọn đang sửa màu nào, bánh xe sửa đúng ô đó. Bật "Hai nguồn"
## thì phòng thành gradient — đèn bên trái ăn màu A, bên phải màu B, đỉnh trời A chân trời B.
## Tắt thì cả phòng một màu A.
##
## Dùng `ColorPicker` có sẵn của Godot thay vì tự dựng ba thanh trượt: đã có bánh xe, thanh
## RGB/HSV và ô mã hex — trộn được mọi màu, không phải viết dòng nào.
##
## Gửi lúc bấm ÁP DỤNG, KHÔNG nối thẳng `color_changed`: bánh xe bắn signal mỗi pixel con trỏ
## đi qua, nối thẳng vào RPC là kéo một đường ngang phát vài trăm gói tin và dựng lại radiance
## cubemap của bầu trời từng ấy lần — đúng cái lỗi lag đã phải đi sửa một lần rồi.

## Vài màu đặt sẵn cho ai không muốn ngồi trộn.
const DAT_SAN: Array[Color] = [
	Color("ffc46b"), Color("ffffff"), Color("ff5fa2"),
	Color("4d8cff"), Color("46d97a"), Color("a56bff"),
	Color("ff3b30"), Color("00e5ff"),
]
## Chừa quanh mép màn hình chừng này pixel. Bảng không bao giờ tràn ra ngoài.
const CHUA_LE := 28.0
const RONG_TOI_DA := 520.0

signal mau_da_chon(mau_a: Color, mau_b: Color, hai_mau: bool)
signal xin_mau_goc

@onready var _khung: PanelContainer = %Panel
@onready var _banh_xe: ColorPicker = %Wheel
@onready var _dat_san: GridContainer = %PresetGrid
@onready var _o_a: Button = %ChipA
@onready var _o_b: Button = %ChipB
@onready var _bat_b: CheckButton = %TwoToggle
@onready var _xem_truoc: TextureRect = %GradientPreview

var _mau := [Color("ffc46b"), Color("4d8cff")]
## Đang sửa ô nào: 0 = A, 1 = B.
var _dang_sua := 0
var _dai := GradientTexture2D.new()


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
	# Bam o B la TU BAT che do hai nguon luon. Truoc day o B bi `disabled` cho toi khi tich
	# cai o "Hai nguon sang" — ma nut `disabled` thi khong ban `pressed`, nen bam vao no im
	# lang hoan toan: nhin nhu tinh nang chet. Khong bat ai phai tim ra cai cong tac truoc.
	_o_b.pressed.connect(func():
		_bat_b.button_pressed = true
		_chon_o(1))
	_bat_b.toggled.connect(func(_on): _ve_lai())

	_dai.gradient = Gradient.new()
	_dai.fill_from = Vector2(0, 0.5)
	_dai.fill_to = Vector2(1, 0.5)
	_xem_truoc.texture = _dai

	for m in DAT_SAN:
		var b := Button.new()
		b.custom_minimum_size = Vector2(48, 34)
		var kieu := StyleBoxFlat.new()
		kieu.bg_color = m
		kieu.set_corner_radius_all(5)
		for tt in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(tt, kieu)
		var mau := m
		# Bấm màu đặt sẵn là gán vào Ô ĐANG SỬA, không áp thẳng: còn phải chọn ô kia nữa.
		b.pressed.connect(func():
			_mau[_dang_sua] = mau
			_banh_xe.color = mau
			_ve_lai())
		_dat_san.add_child(b)

	_chon_o(0)
	# `is_inside_tree` la bat buoc: tin hieu nay khong tu ngat khi node roi khoi cay, va
	# `get_viewport_rect()` tren mot node da roi ra la loi.
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


## Ép bảng nằm gọn trong màn hình NGƯỜI DÙNG, không phải trong một cỡ chép cứng.
##
## Bảng cũ cao cố định 620 px: cửa sổ thấp hơn thế thì tiêu đề bị cắt mất ở trên và ba nút
## VỀ MÀU GỐC / ĐÓNG / ÁP DỤNG bị cắt mất ở dưới — bấm không tới. Giờ đo `get_visible_rect()`
## mỗi lần mở và mỗi lần đổi cỡ cửa sổ; phần nội dung dài hơn thì `ScrollContainer` cuộn.
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
	# Tat hai nguon thi quay ve sua o A — khong de con tro ket o cai o dang khong duoc dung.
	if not hai and _dang_sua == 1:
		_dang_sua = 0
		_banh_xe.color = _mau[0]
	# O B mo di khi khong dung, nhung VAN BAM DUOC: bam vao la bat hai nguon len.
	_o_b.modulate = Color(1, 1, 1, 1.0 if hai else 0.45)
	for i in 2:
		var o: Button = _o_a if i == 0 else _o_b
		var kieu := StyleBoxFlat.new()
		kieu.bg_color = _mau[i]
		kieu.set_corner_radius_all(6)
		if i == _dang_sua:
			kieu.set_border_width_all(3)
			kieu.border_color = Color.WHITE
		for tt in ["normal", "hover", "pressed", "focus"]:
			o.add_theme_stylebox_override(tt, kieu)
	_dai.gradient.set_color(0, _mau[0])
	_dai.gradient.set_color(1, _mau[1] if hai else _mau[0])
