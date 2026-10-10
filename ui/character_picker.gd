extends Control

## Màn chọn nhân vật/màu/kiểu bong bóng. Ghi thẳng vào property replicate của Player.

## Chừa quanh mép màn hình (px).
const CHUA_LE := 28.0
const RONG_TOI_DA := 700.0

## Ảnh preview từng nhân vật, chụp một lần cho cả phiên.
static var _anh: Array[Texture2D] = []

@export var nut_model_scene: PackedScene = null
@export var o_mau_scene: PackedScene = null
@export var nut_chon_scene: PackedScene = null

@onready var _luoi_model: GridContainer = %ModelGrid
@onready var _luoi_mau: GridContainer = %ColorGrid
@onready var _luoi_nhan: GridContainer = %AccentGrid
@onready var _luoi_bong: GridContainer = %BubbleGrid
@onready var _ten: Label = %PickerName
@onready var _phu_kien: CheckButton = %AccessoryCheck
@onready var _anh_viewport: SubViewport = $AnhViewport


func _ready() -> void:
	%CloseButton.pressed.connect(dong)
	_phu_kien.toggled.connect(func(enabled: bool):
		var p := _toi()
		if p != null:
			p.accessory_enabled = enabled
			NetManager.accessory_enabled = enabled)
	# Phải kiểm `is_inside_tree`: tín hiệu không tự ngắt khi node rời cây.
	get_viewport().size_changed.connect(func():
		if visible and is_inside_tree():
			_vua_man_hinh())
	visible = false
	if _anh.is_empty():
		_dung_anh.call_deferred()


## Chụp ảnh từng nhân vật bằng SubViewport (`own_world_3d` để chỉ thấy nhân vật).
## ponytail: mỗi model một khung hình, chạy ngầm lúc vào phòng.
func _dung_anh() -> void:
	var p := _toi()
	if p == null or p.models.is_empty():
		return

	var vp := _anh_viewport
	var ds: Array[Texture2D] = []
	for scene in p.models:
		var inst := (scene as PackedScene).instantiate() as Node3D
		# Quay nghiêng 20°.
		inst.rotation.y = deg_to_rad(20.0)
		vp.add_child(inst)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		ds.append(ImageTexture.create_from_image(vp.get_texture().get_image()))
		# Gỡ khỏi cây ngay, kẻo còn trong ảnh của model kế tiếp.
		vp.remove_child(inst)
		inst.queue_free()
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_anh = ds
	if visible:
		var toi := _toi()
		if toi != null:
			_dung_luoi(toi)


## Người chơi của máy này.
func _toi() -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_mine:
			return p
	return null


func mo() -> void:
	var p := _toi()
	if p == null:
		return
	_dung_luoi(p)
	visible = true
	_vua_man_hinh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Ép bảng nằm gọn trong màn hình.
func _vua_man_hinh() -> void:
	var khung := %Panel as PanelContainer
	var man := get_viewport_rect().size
	var rong := minf(RONG_TOI_DA, man.x - CHUA_LE * 2.0)
	var cao := man.y - CHUA_LE * 2.0
	khung.offset_left = -rong * 0.5
	khung.offset_right = rong * 0.5
	khung.offset_top = -cao * 0.5
	khung.offset_bottom = cao * 0.5


func dong() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Esc đóng màn này trước khi PauseMenu kịp mở.
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		dong()


func _dung_luoi(p: Player) -> void:
	_ten.text = p.player_name if p.player_name != "" else "#%d" % p.player_id()
	_phu_kien.set_pressed_no_signal(p.accessory_enabled)

	for c in _luoi_model.get_children():
		c.queue_free()
	for i in p.models.size():
		var b := nut_model_scene.instantiate() as Button
		b.button_pressed = i == p.model_index
		# Chưa chụp xong thì hiện tên.
		if i < _anh.size():
			b.icon = _anh[i]
			b.expand_icon = true
			b.tooltip_text = CharacterVisual.ARCHETYPE_NAMES[i]
		else:
			b.text = CharacterVisual.ARCHETYPE_NAMES[i]
		var k := i
		b.pressed.connect(func():
			p.model_index = k
			NetManager.model_index = k
			_dung_luoi(p))
		_luoi_model.add_child(b)

	for c in _luoi_mau.get_children():
		c.queue_free()
	for i in NetManager.PLAYER_COLORS.size():
		var b := o_mau_scene.instantiate() as OMau
		b.dat(NetManager.PLAYER_COLORS[i], i == p.color_index)
		var k := i
		b.pressed.connect(func():
			p.color_index = k
			NetManager.color_index = k
			_dung_luoi(p))
		_luoi_mau.add_child(b)

	for c in _luoi_nhan.get_children():
		c.queue_free()
	for i in NetManager.PLAYER_COLORS.size():
		var b := o_mau_scene.instantiate() as OMau
		b.dat(NetManager.PLAYER_COLORS[i], i == p.accent_index)
		var k := i
		b.pressed.connect(func():
			p.accent_index = k
			NetManager.accent_index = k
			_dung_luoi(p))
		_luoi_nhan.add_child(b)

	for c in _luoi_bong.get_children():
		c.queue_free()
	for i in SpeechBubble.TEN_KIEU.size():
		var b := nut_chon_scene.instantiate() as Button
		b.text = SpeechBubble.TEN_KIEU[i]
		b.button_pressed = i == p.bubble_shape
		var k := i
		b.pressed.connect(func():
			p.bubble_shape = k
			_dung_luoi(p))
		_luoi_bong.add_child(b)
