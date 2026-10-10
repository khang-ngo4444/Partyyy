class_name CharacterCreator
extends Control

signal confirmed
signal cancelled

@export var nut_chon_scene: PackedScene = null

## Cùng thứ tự với `Player.models` và `CharacterVisual.ARCHETYPE_NAMES`.
@export var models: Array[PackedScene] = []
@export var o_mau_scene: PackedScene = null

var _model_index := 0
var _primary_index := 0
var _accent_index := 1
var _accessory_enabled := true
var _preview: Node3D
var _animation: AnimationPlayer
var _playing := "idle"

@onready var preview_anchor: Node3D = %PreviewAnchor
@onready var preview_camera: Camera3D = %PreviewCamera
@onready var class_grid: GridContainer = %ClassGrid
@onready var primary_grid: GridContainer = %PrimaryGrid
@onready var accent_grid: GridContainer = %AccentGrid
@onready var accessory_check: CheckButton = %AccessoryCheck
@onready var archetype_name: Label = %ArchetypeName
@onready var animation_name: Label = %AnimationName
@onready var back_btn: Button = %CreatorBackBtn
@onready var confirm_btn: Button = %CreatorConfirmBtn


func _ready() -> void:
	preview_camera.look_at(Vector3(0.0, 0.72, 0.0), Vector3.UP)
	_build_class_buttons()
	_build_color_buttons(primary_grid, _select_primary)
	_build_color_buttons(accent_grid, _select_accent)
	accessory_check.toggled.connect(_toggle_accessory)
	back_btn.pressed.connect(close)
	confirm_btn.pressed.connect(_confirm)
	%IdleBtn.pressed.connect(func(): _play_preview("idle", "ĐỨNG"))
	%WalkBtn.pressed.connect(func(): _play_preview("walk", "ĐI"))
	%JumpBtn.pressed.connect(func(): _play_preview("jump", "NHẢY"))
	%SitBtn.pressed.connect(func(): _play_preview("sit", "NGỒI"))
	visible = false
	set_process(false)


func open() -> void:
	_model_index = clampi(NetManager.model_index, 0, models.size() - 1)
	_primary_index = posmod(NetManager.color_index, NetManager.PLAYER_COLORS.size())
	_accent_index = posmod(NetManager.accent_index, NetManager.PLAYER_COLORS.size())
	_accessory_enabled = NetManager.accessory_enabled
	accessory_check.button_pressed = _accessory_enabled
	visible = true
	set_process(true)
	_rebuild_preview()
	_refresh_buttons()
	confirm_btn.grab_focus()


func close() -> void:
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


func _process(delta: float) -> void:
	preview_anchor.rotation.y = wrapf(preview_anchor.rotation.y + delta * 0.28, -PI, PI)
	if _animation != null and _playing == "jump" and not _animation.is_playing():
		_play_preview("idle", "ĐỨNG")


func _build_class_buttons() -> void:
	for index in models.size():
		var button := nut_chon_scene.instantiate() as Button
		button.text = "%02d  %s" % [index + 1, CharacterVisual.ARCHETYPE_NAMES[index]]
		var picked := index
		button.pressed.connect(func(): _select_model(picked))
		class_grid.add_child(button)


func _build_color_buttons(grid: GridContainer, callback: Callable) -> void:
	for index in NetManager.PLAYER_COLORS.size():
		var button := o_mau_scene.instantiate() as OMau
		button.tooltip_text = "Màu %d" % (index + 1)
		button.dat(NetManager.PLAYER_COLORS[index])
		var picked := index
		button.pressed.connect(func(): callback.call(picked))
		grid.add_child(button)


func _select_model(index: int) -> void:
	_model_index = index
	_rebuild_preview()
	_refresh_buttons()


func _select_primary(index: int) -> void:
	_primary_index = index
	_apply_preview_customization()
	_refresh_buttons()


func _select_accent(index: int) -> void:
	_accent_index = index
	_apply_preview_customization()
	_refresh_buttons()


func _toggle_accessory(enabled: bool) -> void:
	_accessory_enabled = enabled
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


func _play_preview(animation: String, label: String) -> void:
	_playing = animation
	animation_name.text = "XEM ANIMATION  /  " + label
	if _animation != null and _animation.has_animation(animation):
		_animation.play(animation, 0.18)


func _refresh_buttons() -> void:
	for index in class_grid.get_child_count():
		(class_grid.get_child(index) as Button).button_pressed = index == _model_index
	for index in primary_grid.get_child_count():
		var button := primary_grid.get_child(index) as Button
		button.button_pressed = index == _primary_index
		button.modulate = Color.WHITE if index == _primary_index else Color(0.72, 0.72, 0.72)
	for index in accent_grid.get_child_count():
		var button := accent_grid.get_child(index) as Button
		button.button_pressed = index == _accent_index
		button.modulate = Color.WHITE if index == _accent_index else Color(0.72, 0.72, 0.72)
