extends Control

## Màn hình chọn nhân vật, mở từ bảng trên tường phòng chờ.
##
## Ba thứ chọn được, cả ba đều là property REPLICATE trên `Player` — đặt thẳng, không qua RPC,
## Fusion tự gửi sang máy khác (giống hệt cách `color_index` đã làm từ lúc vào phòng).
##
## Màn hình này KHÔNG giữ trạng thái riêng. Mở ra là đọc lại từ nhân vật của mình, bấm là ghi
## thẳng vào đó. Không có "Lưu"/"Huỷ" — không có bản nháp nào để mà huỷ.
##
## Chuột: nhường quyền cho `PauseMenu` như mọi màn hình khác trong game, xem `_mo`/`dong`.

const CO_O := Vector2(112, 138)
const CO_MAU := Vector2(48, 36)
## Co anh preview, pixel. To hon o nut mot chut cho khoi ro rang khi phong to.
const CO_ANH := Vector2i(128, 156)

## Anh preview tung nhan vat, dung MOT lan cho ca phien roi nho lai. `static` nen mo lai man
## hinh nay lan hai la co san, khong dung lai tu dau.
static var _anh: Array[Texture2D] = []

@onready var _luoi_model: GridContainer = %ModelGrid
@onready var _luoi_mau: GridContainer = %ColorGrid
@onready var _luoi_nhan: GridContainer = %AccentGrid
@onready var _luoi_bong: GridContainer = %BubbleGrid
@onready var _ten: Label = %PickerName
@onready var _phu_kien: CheckButton = %AccessoryCheck


func _ready() -> void:
	%CloseButton.pressed.connect(dong)
	_phu_kien.toggled.connect(func(enabled: bool):
		var p := _toi()
		if p != null:
			p.accessory_enabled = enabled
			NetManager.accessory_enabled = enabled)
	# `is_inside_tree` la bat buoc: tin hieu nay khong tu ngat khi node roi khoi cay, va
	# `get_viewport_rect()` tren mot node da roi ra la loi.
	get_viewport().size_changed.connect(func():
		if visible and is_inside_tree():
			_vua_man_hinh())
	visible = false
	if _anh.is_empty():
		_dung_anh.call_deferred()


## Chup anh tung nhan vat bang mot SubViewport rieng.
##
## Khong ke anh san vao repo: 22 model, moi lan them/doi model la phai chup lai bang tay va
## nho commit. Dung o day thi danh sach model trong `player.tscn` van la nguon su that duy
## nhat — them mot model moi la no tu co anh.
##
## `own_world_3d` la BAT BUOC: khong bat thi SubViewport nhin vao chinh the gioi cua game,
## va anh chup ra la ca can phong chu khong phai cai nhan vat.
##
## ponytail: chup tuan tu, moi model mot khung hinh — 22 model la ~0.4 giay. Chay ngam luc
## vao phong nen khong ai thay. Cham hon thi gop nhieu model vao mot khung hinh.
func _dung_anh() -> void:
	var p := _toi()
	if p == null or p.models.is_empty():
		return

	var vp := SubViewport.new()
	vp.size = CO_ANH
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp)

	var cam := Camera3D.new()
	cam.fov = 32.0
	cam.position = Vector3(0.0, 1.0, 3.6)
	vp.add_child(cam)

	# Hai den: mot den chinh chech truoc, mot den yeu tu sau cho vien nguoi tach khoi nen trong.
	var den := DirectionalLight3D.new()
	den.rotation_degrees = Vector3(-28.0, -38.0, 0.0)
	den.light_energy = 1.5
	vp.add_child(den)
	var vien := DirectionalLight3D.new()
	vien.rotation_degrees = Vector3(-10.0, 150.0, 0.0)
	vien.light_energy = 0.7
	vp.add_child(vien)

	var ds: Array[Texture2D] = []
	for scene in p.models:
		var inst := (scene as PackedScene).instantiate() as Node3D
		# Kenney quay mat ve +Z va scene da xoay 180 do; quay them 20 do cho dang nghieng.
		inst.rotation.y = deg_to_rad(20.0)
		vp.add_child(inst)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		ds.append(ImageTexture.create_from_image(vp.get_texture().get_image()))
		# GO KHOI CAY NGAY roi moi queue_free: `queue_free` chi thuc su xoa o cuoi khung hinh,
		# de nguyen thi model nay con dung trong anh cua model ke tiep.
		vp.remove_child(inst)
		inst.queue_free()

	vp.queue_free()
	_anh = ds
	if visible:
		var toi := _toi()
		if toi != null:
			_dung_luoi(toi)


## Người chơi của MÁY NÀY. Không có (chưa vào phòng, vừa rời phòng) thì màn hình vô nghĩa.
func _toi() -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_mine:
			return p
	return null


const CHUA_LE := 28.0
const RONG_TOI_DA := 700.0


func mo() -> void:
	var p := _toi()
	if p == null:
		return
	_dung_luoi(p)
	visible = true
	_vua_man_hinh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Ep bang nam gon trong man hinh NGUOI DUNG. Co chep cung thi cua so thap hon la tieu de bi
## cat o tren va hang nut bi cat o duoi — bam khong toi.
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


## Esc đóng màn hình này TRƯỚC khi PauseMenu kịp mở. Bắt ở `_input` vì PauseMenu cũng bắt ở
## đó — node nào đứng sau trong cây thì nhận trước, nên picker phải nằm dưới PauseMenu trong
## main.tscn và tự đánh dấu đã xử lý.
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
		var b := Button.new()
		b.custom_minimum_size = CO_O
		b.toggle_mode = true
		b.button_pressed = i == p.model_index
		# Chua chup xong thi hien so — van bam chon duoc binh thuong.
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
		var b := Button.new()
		b.custom_minimum_size = CO_MAU
		# Nút tô đúng màu nó đại diện: một ô màu bấm được, không cần nhãn.
		var kieu := StyleBoxFlat.new()
		kieu.bg_color = NetManager.PLAYER_COLORS[i]
		kieu.set_corner_radius_all(6)
		if i == p.color_index:
			kieu.set_border_width_all(4)
			kieu.border_color = Color.WHITE
		for tt in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(tt, kieu)
		var k := i
		b.pressed.connect(func():
			p.color_index = k
			NetManager.color_index = k
			_dung_luoi(p))
		_luoi_mau.add_child(b)

	for c in _luoi_nhan.get_children():
		c.queue_free()
	for i in NetManager.PLAYER_COLORS.size():
		var b := Button.new()
		b.custom_minimum_size = CO_MAU
		var kieu := StyleBoxFlat.new()
		kieu.bg_color = NetManager.PLAYER_COLORS[i]
		kieu.set_corner_radius_all(6)
		if i == p.accent_index:
			kieu.set_border_width_all(4)
			kieu.border_color = Color.WHITE
		for tt in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(tt, kieu)
		var k := i
		b.pressed.connect(func():
			p.accent_index = k
			NetManager.accent_index = k
			_dung_luoi(p))
		_luoi_nhan.add_child(b)

	for c in _luoi_bong.get_children():
		c.queue_free()
	for i in SpeechBubble.TEN_KIEU.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(110, 40)
		b.text = SpeechBubble.TEN_KIEU[i]
		b.toggle_mode = true
		b.button_pressed = i == p.bubble_shape
		var k := i
		b.pressed.connect(func():
			p.bubble_shape = k
			_dung_luoi(p))
		_luoi_bong.add_child(b)
