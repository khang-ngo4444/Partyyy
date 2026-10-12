class_name UINav
extends Node

## UINav (autoload tên "UINavHook"): "juice" chung cho mọi nút + helper hoạt hình UI.
## Tự gắn vào mọi BaseButton được thêm vào cây (không cần sửa từng scene).
## - Rê chuột vào nút = nhận focus (ẩn viền) → chỉ một nút sáng, phím mũi tên đi tiếp từ đó.
## - Focus/hover: phóng to + nghiêng nhẹ. Bấm: lún xuống. Có âm tick.
## Đặt meta "khong_nay" trên nút để bỏ qua.

const SETTINGS_PATH := "user://party_settings.cfg"
const PHONG := Vector2(1.07, 1.07)
const LUN := Vector2(0.93, 0.93)

static var giam_chuyen_dong := false

var _tick := AudioStreamPlayer.new()
static var _tweens: Dictionary = {}  # Control -> Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tick.stream = load("res://asset/kenney_interface-sounds/Audio/tick_002.ogg")
	_tick.volume_db = -14.0
	add_child(_tick)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		giam_chuyen_dong = bool(cfg.get_value("display", "reduce_motion", false))
		ap_co_ui(float(cfg.get_value("display", "ui_scale", 1.0)))
	get_tree().node_added.connect(_on_node_added)


static func ap_co_ui(he_so: float) -> void:
	(Engine.get_main_loop() as SceneTree).root.content_scale_factor = clampf(he_so, 0.8, 1.3)


func _on_node_added(n: Node) -> void:
	if n is BaseButton and not n.has_meta("khong_nay"):
		_gan_nut(n)


func _gan_nut(b: BaseButton) -> void:
	_chuan_bi(b)
	b.mouse_entered.connect(_vao_chuot.bind(b))
	b.mouse_exited.connect(func(): if not b.has_focus(): _phong(b, false))
	b.focus_entered.connect(_nhan_focus.bind(b))
	b.focus_exited.connect(func(): _phong(b, false))
	b.button_down.connect(func(): _tween(b, LUN, 0.0, 0.06))
	b.button_up.connect(func(): _phong(b, b.has_focus() or b.is_hovered()))
	# Nút chọn (toggle, không phải công tắc): đang chọn = vàng.
	if b.toggle_mode and not (b is CheckButton or b is CheckBox):
		b.toggled.connect(_to_mau_chon.bind(b))
		_to_mau_chon.call_deferred(b.button_pressed, b)


func _to_mau_chon(on: bool, b: BaseButton) -> void:
	if not is_instance_valid(b):
		return
	if not b.has_meta("bien_the_goc"):
		b.set_meta("bien_the_goc", b.theme_type_variation)
	b.theme_type_variation = &"NutVang" if on else b.get_meta("bien_the_goc")
	if on and b.is_visible_in_tree():
		nay(b, 1.12)


static func _chuan_bi(c: Control) -> void:
	c.offset_transform_enabled = true
	c.offset_transform_visual_only = true
	c.offset_transform_pivot_ratio = Vector2(0.5, 0.5)


func _vao_chuot(b: BaseButton) -> void:
	if b.disabled:
		return
	_phong(b, true)
	if b.focus_mode == Control.FOCUS_NONE:
		_tick.play()
		return
	var f := b.get_viewport().gui_get_focus_owner()
	# Đang gõ thì không cướp focus.
	if f is LineEdit or f is TextEdit:
		return
	if f != b:
		b.grab_focus(true)


func _nhan_focus(b: BaseButton) -> void:
	_phong(b, true)
	if b.is_visible_in_tree():
		_tick.play()


static func _phong(b: BaseButton, on: bool) -> void:
	if not is_instance_valid(b):
		return
	if b.disabled:
		on = false
	var goc := 0.0
	if on and not giam_chuyen_dong:
		goc = deg_to_rad(1.6 if (b.get_index() % 2 == 0) else -1.6)
	_tween(b, PHONG if on else Vector2.ONE, goc, 0.16 if on else 0.12)


static func _tween(c: Control, s: Vector2, goc: float, t: float) -> void:
	if _tweens.has(c) and (_tweens[c] as Tween).is_valid():
		(_tweens[c] as Tween).kill()
	if giam_chuyen_dong:
		c.offset_transform_scale = s if s != LUN else Vector2.ONE
		c.offset_transform_rotation = 0.0
		return
	var tw := c.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "offset_transform_scale", s, t)
	tw.tween_property(c, "offset_transform_rotation", goc, t)
	_tweens[c] = tw
	tw.finished.connect(func(): _tweens.erase(c))


# ---------- Helper hoạt hình dùng chung ----------

## Các control bật lên lần lượt (mở màn hình).
static func xuat_hien(ds: Array, tre := 0.045, tu_scale := 0.6) -> void:
	var i := 0
	for c: Control in ds:
		if not is_instance_valid(c):
			continue
		_chuan_bi(c)
		if giam_chuyen_dong:
			c.offset_transform_scale = Vector2.ONE
			c.modulate.a = 1.0
			continue
		c.offset_transform_scale = Vector2(tu_scale, tu_scale)
		c.modulate.a = 0.0
		var tw := c.create_tween().set_parallel()
		tw.tween_property(c, "offset_transform_scale", Vector2.ONE, 0.32) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * tre)
		tw.tween_property(c, "modulate:a", 1.0, 0.14).set_delay(i * tre)
		# Nút đang được chọn giữ trạng thái phóng to sau khi bật lên.
		if c is BaseButton:
			tw.finished.connect(func():
				if is_instance_valid(c) and (c.has_focus() or c.is_hovered()):
					_phong(c, true))
		i += 1


## Banner "đập" xuống giữa màn.
static func dap(c: Control) -> void:
	_chuan_bi(c)
	if giam_chuyen_dong:
		c.offset_transform_scale = Vector2.ONE
		c.modulate.a = 1.0
		return
	c.offset_transform_scale = Vector2(2.2, 2.2)
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "offset_transform_scale", Vector2.ONE, 0.28) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, 0.1)


## Nảy nhẹ (số vừa đổi, nút vừa bấm).
static func nay(c: Control, muc := 1.25) -> void:
	_chuan_bi(c)
	if giam_chuyen_dong:
		return
	var tw := c.create_tween()
	tw.tween_property(c, "offset_transform_scale", Vector2(muc, muc), 0.08)
	tw.tween_property(c, "offset_transform_scale", Vector2.ONE, 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Lắc ngang (báo lỗi).
static func lac(c: Control) -> void:
	_chuan_bi(c)
	if giam_chuyen_dong:
		return
	var tw := c.create_tween()
	for x in [-10.0, 9.0, -6.0, 4.0, 0.0]:
		tw.tween_property(c, "offset_transform_position", Vector2(x, 0), 0.04)


## Lơ lửng lên xuống liên tục (logo, mũi tên gợi ý).
static func lo_lung(c: Control, bien_do := 6.0, chu_ky := 1.6) -> void:
	_chuan_bi(c)
	if giam_chuyen_dong:
		return
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "offset_transform_position", Vector2(0, -bien_do), chu_ky * 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(c, "offset_transform_position", Vector2(0, bien_do), chu_ky * 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
