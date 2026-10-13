class_name CharacterCreator
extends Control

## Màn nhân vật dùng chung:
## - open(): từ menu chính, bấm TIẾP TỤC mới lưu vào NetManager.
## - open_phong(p): trong phòng (phím M), chọn là áp ngay lên Player (replicate).
## Phím: Q/E đổi nhân vật, 1–9/0 chọn nhanh, Esc quay lại. Kéo chuột trên sân khấu để xoay.

signal confirmed
signal cancelled

## Ảnh chân dung từng nhân vật, chụp một lần cho cả phiên.
static var _anh: Array[Texture2D] = []

@export var nut_chon_scene: PackedScene = null
## Cùng thứ tự với `Player.models` và `CharacterVisual.ARCHETYPE_NAMES`.
@export var models: Array[PackedScene] = []
@export var o_mau_scene: PackedScene = null

var _model_index := 0
var _primary_index := 0
var _accent_index := 1
var _accessory_enabled := true
var _bubble := 0
var _preview: Node3D
var _animation: AnimationPlayer
var _playing := "idle"
var _player: Player = null  # khác null = chế độ trong phòng
var _keo := false
var _xoay_tu_dong := true

@onready var stage: Control = %Stage
@onready var options: Control = %Options
@onready var preview_anchor: Node3D = %PreviewAnchor
@onready var preview_camera: Camera3D = %PreviewCamera
@onready var viewport_container: SubViewportContainer = %ViewportContainer
@onready var class_grid: GridContainer = %ClassGrid
@onready var primary_grid: GridContainer = %PrimaryGrid
@onready var accent_grid: GridContainer = %AccentGrid
@onready var bubble_box: Control = %BubbleBox
@onready var bubble_grid: HBoxContainer = %BubbleGrid
@onready var accessory_check: CheckButton = %AccessoryCheck
@onready var archetype_name: Label = %ArchetypeName
@onready var player_name_label: Label = %PlayerName
@onready var back_btn: Button = %CreatorBackBtn
@onready var confirm_btn: Button = %CreatorConfirmBtn
@onready var prev_btn: Button = %PrevBtn
@onready var next_btn: Button = %NextBtn
@onready var anh_viewport: SubViewport = %AnhViewport


func _ready() -> void:
	preview_camera.look_at(Vector3(0.0, 0.72, 0.0), Vector3.UP)
	_build_class_buttons()
	_build_color_buttons(primary_grid, _select_primary)
	_build_color_buttons(accent_grid, _select_accent)
	_build_bubble_buttons()
	accessory_check.toggled.connect(_toggle_accessory)
	back_btn.pressed.connect(close)
	confirm_btn.pressed.connect(_confirm)
	prev_btn.pressed.connect(func(): _select_model(posmod(_model_index - 1, models.size())))
	next_btn.pressed.connect(func(): _select_model(posmod(_model_index + 1, models.size())))
	UIKit.gan_phim(prev_btn, "Q")
	UIKit.gan_phim(next_btn, "E")
	UIKit.gan_phim(back_btn, "Esc")
	var anim := {%IdleBtn: ["idle", "ĐỨNG"], %WalkBtn: ["walk", "ĐI"],
			%JumpBtn: ["jump", "NHẢY"], %SitBtn: ["sit", "NGỒI"]}
	for b: Button in anim:
		var a: Array = anim[b]
		b.pressed.connect(func(): _play_preview(a[0], a[1]))
	viewport_container.gui_input.connect(_keo_xoay)
	visible = false
	set_process(false)
	if _anh.is_empty():
		_chup_anh.call_deferred()


# ---------- Mở / đóng ----------

func open() -> void:
	_player = null
	_model_index = clampi(NetManager.model_index, 0, models.size() - 1)
	_primary_index = posmod(NetManager.color_index, NetManager.PLAYER_COLORS.size())
	_accent_index = posmod(NetManager.accent_index, NetManager.PLAYER_COLORS.size())
	_accessory_enabled = NetManager.accessory_enabled
	_mo_chung()
	confirm_btn.text = "TIẾP TỤC  ▶"
	back_btn.visible = true
	bubble_box.visible = false


func open_phong(p: Player) -> void:
	_player = p
	_model_index = clampi(p.model_index, 0, models.size() - 1)
	_primary_index = posmod(p.color_index, NetManager.PLAYER_COLORS.size())
	_accent_index = posmod(p.accent_index, NetManager.PLAYER_COLORS.size())
	_accessory_enabled = p.accessory_enabled
	_bubble = p.bubble_shape
	_mo_chung()
	confirm_btn.text = "XONG"
	back_btn.visible = false
	bubble_box.visible = true


func _mo_chung() -> void:
	accessory_check.set_pressed_no_signal(_accessory_enabled)
	player_name_label.text = NetManager.player_name if NetManager.player_name != "" else "Bạn"
	visible = true
	set_process(true)
	_xoay_tu_dong = true
	preview_anchor.rotation.y = PI
	_rebuild_preview()
	_refresh_buttons()
	UINav.xuat_hien([stage, options], 0.08, 0.85)
	confirm_btn.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	set_process(false)
	cancelled.emit()


func _confirm() -> void:
	NetManager.model_index = _model_index
	NetManager.color_index = _primary_index
	NetManager.accent_index = _accent_index
	NetManager.accessory_enabled = _accessory_enabled
	visible = false
	set_process(false)
	confirmed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _player != null:
			_confirm()
		else:
			close()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	var k: int = event.keycode
	if k == KEY_Q:
		prev_btn.pressed.emit()
	elif k == KEY_E:
		next_btn.pressed.emit()
	elif k >= KEY_1 and k <= KEY_9 and k < KEY_1 + models.size():
		_select_model(k - KEY_1)
	elif k == KEY_0 and models.size() >= 10:
		_select_model(9)
	else:
		return
	get_viewport().set_input_as_handled()


# ---------- Xem trước ----------

func _process(delta: float) -> void:
	if _xoay_tu_dong:
		preview_anchor.rotation.y = wrapf(preview_anchor.rotation.y + delta * 0.35, -PI, PI)
	if _animation != null and _playing == "jump" and not _animation.is_playing():
		_play_preview("idle", "ĐỨNG")


func _keo_xoay(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_keo = event.pressed
		if _keo:
			_xoay_tu_dong = false
	elif event is InputEventMouseMotion and _keo:
		preview_anchor.rotation.y += event.relative.x * 0.012


## Chụp chân dung từng nhân vật bằng SubViewport riêng (own_world_3d).
func _chup_anh() -> void:
	var ds: Array[Texture2D] = []
	for scene in models:
		var inst := (scene as PackedScene).instantiate() as Node3D
		inst.rotation.y = PI + deg_to_rad(20.0)
		anh_viewport.add_child(inst)
		var animator := CharacterVisual.hoat_anh_cua(inst)
		if animator != null:
			animator.play("idle")
			animator.advance(0.3)
		anh_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		ds.append(ImageTexture.create_from_image(anh_viewport.get_texture().get_image()))
		anh_viewport.remove_child(inst)
		inst.queue_free()
	anh_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_anh = ds
	_gan_anh()


func _gan_anh() -> void:
	if _anh.size() < class_grid.get_child_count():
		return
	for i in class_grid.get_child_count():
		var b := class_grid.get_child(i) as Button
		b.icon = _anh[i]
		b.text = ""


# ---------- Dựng nút ----------

func _build_class_buttons() -> void:
	for index in models.size():
		var button := nut_chon_scene.instantiate() as Button
		button.custom_minimum_size = Vector2(88, 82)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.theme_type_variation = &"NutTrang"
		button.text = str(index + 1)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = CharacterVisual.ARCHETYPE_NAMES[index]
		# Ảnh chân dung giữ màu gốc (theme mặc định tô icon màu mực).
		for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
				"icon_focus_color", "icon_hover_pressed_color"]:
			button.add_theme_color_override(k, Color.WHITE)
		var picked := index
		button.pressed.connect(func(): _select_model(picked))
		class_grid.add_child(button)
		if index < 10:
			UIKit.gan_phim(button, str((index + 1) % 10))
	_gan_anh()


func _build_color_buttons(grid: GridContainer, callback: Callable) -> void:
	for index in NetManager.PLAYER_COLORS.size():
		var button := o_mau_scene.instantiate() as OMau
		button.tooltip_text = "Màu %d" % (index + 1)
		button.dat(NetManager.PLAYER_COLORS[index])
		var picked := index
		button.pressed.connect(func(): callback.call(picked))
		grid.add_child(button)


func _build_bubble_buttons() -> void:
	for i in SpeechBubble.TEN_KIEU.size():
		var b := nut_chon_scene.instantiate() as Button
		b.text = SpeechBubble.TEN_KIEU[i]
		b.theme_type_variation = &"NutTrang"
		b.custom_minimum_size = Vector2(0, 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 20)
		var k := i
		b.pressed.connect(func():
			_bubble = k
			if _player != null:
				_player.bubble_shape = k
			_refresh_buttons())
		bubble_grid.add_child(b)


# ---------- Chọn ----------

func _select_model(index: int) -> void:
	_model_index = index
	if _player != null:
		_player.model_index = index
		NetManager.model_index = index
	_rebuild_preview()
	_refresh_buttons()
	UINav.nay(archetype_name, 1.15)


func _select_primary(index: int) -> void:
	_primary_index = index
	if _player != null:
		_player.color_index = index
		NetManager.color_index = index
	_apply_preview_customization()
	_refresh_buttons()


func _select_accent(index: int) -> void:
	_accent_index = index
	if _player != null:
		_player.accent_index = index
		NetManager.accent_index = index
	_apply_preview_customization()
	_refresh_buttons()


func _toggle_accessory(enabled: bool) -> void:
	_accessory_enabled = enabled
	if _player != null:
		_player.accessory_enabled = enabled
		NetManager.accessory_enabled = enabled
	if _preview != null:
		CharacterVisual.set_accessory_enabled(_preview, enabled)


func _rebuild_preview() -> void:
	if _preview != null:
		_preview.queue_free()
	_preview = models[posmod(_model_index, models.size())].instantiate() as Node3D
	preview_anchor.add_child(_preview)
	_animation = CharacterVisual.hoat_anh_cua(_preview)
	_apply_preview_customization()
	archetype_name.text = CharacterVisual.ARCHETYPE_NAMES[_model_index]
	_play_preview("idle", "ĐỨNG")


func _apply_preview_customization() -> void:
	if _preview == null:
		return
	CharacterVisual.apply_customization(_preview,
			NetManager.color_for(_primary_index),
			NetManager.color_for(_accent_index), _accessory_enabled)


func _play_preview(animation: String, _label: String) -> void:
	_playing = animation
	if _animation != null and _animation.has_animation(animation):
		_animation.play(animation, 0.18)


func _refresh_buttons() -> void:
	for index in class_grid.get_child_count():
		(class_grid.get_child(index) as Button).set_pressed_no_signal(index == _model_index)
		(class_grid.get_child(index) as Button).toggled.emit(index == _model_index)
	for index in primary_grid.get_child_count():
		(primary_grid.get_child(index) as OMau).dat(
				NetManager.PLAYER_COLORS[index], index == _primary_index)
	for index in accent_grid.get_child_count():
		(accent_grid.get_child(index) as OMau).dat(
				NetManager.PLAYER_COLORS[index], index == _accent_index)
	for index in bubble_grid.get_child_count():
		var b := bubble_grid.get_child(index) as Button
		b.set_pressed_no_signal(index == _bubble)
		b.toggled.emit(index == _bubble)
