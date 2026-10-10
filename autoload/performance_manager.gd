extends Node

## Preset chất lượng + độ phân giải động cho cảnh 3D (UI giữ độ phân giải gốc).

signal render_scale_changed(scale: float)
signal graphics_mode_changed(mode: int)

enum GraphicsMode { AUTO, PERFORMANCE, BALANCED, QUALITY }

const TARGET_FPS := 60.0
const SAMPLE_SECONDS := 1.0
const WARMUP_SECONDS := 4.0
const LOW_FPS := TARGET_FPS * 0.9
const RECOVER_FPS := TARGET_FPS - 1.0
const AUTO_START_SCALE := 0.77
const AUTO_MIN_SCALE := 0.59
const AUTO_MAX_SCALE := 1.0
const SCALE_STEP := 0.05
const LOW_SAMPLES_TO_DROP := 2
const HIGH_SAMPLES_TO_RAISE := 6

var graphics_mode: int = GraphicsMode.AUTO
var current_scale := AUTO_START_SCALE
var _sample_acc := 0.0
var _warmup_left := WARMUP_SECONDS
var _low_samples := 0
var _high_samples := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_mode()


func set_graphics_mode(value: int) -> void:
	graphics_mode = clampi(value, GraphicsMode.AUTO, GraphicsMode.QUALITY)
	_sample_acc = 0.0
	_warmup_left = WARMUP_SECONDS
	_low_samples = 0
	_high_samples = 0
	_apply_mode()


func _apply_mode() -> void:
	var viewport := get_tree().root
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	match graphics_mode:
		GraphicsMode.PERFORMANCE:
			viewport.mesh_lod_threshold = 2.0
			_set_scale(0.59)
		GraphicsMode.BALANCED:
			viewport.mesh_lod_threshold = 1.5
			_set_scale(0.77)
		GraphicsMode.QUALITY:
			viewport.mesh_lod_threshold = 1.0
			_set_scale(1.0)
		_:
			viewport.mesh_lod_threshold = 1.5
			_set_scale(AUTO_START_SCALE)
	graphics_mode_changed.emit(graphics_mode)


func _process(delta: float) -> void:
	if graphics_mode != GraphicsMode.AUTO or not DisplayServer.window_is_focused():
		return
	if _warmup_left > 0.0:
		_warmup_left -= delta
		return
	_sample_acc += delta
	if _sample_acc < SAMPLE_SECONDS:
		return
	_sample_acc = fmod(_sample_acc, SAMPLE_SECONDS)

	var fps := Engine.get_frames_per_second()
	if fps < LOW_FPS:
		_low_samples += 1
		_high_samples = 0
		if _low_samples >= LOW_SAMPLES_TO_DROP:
			_set_scale(current_scale - SCALE_STEP)
			_low_samples = 0
	elif fps >= RECOVER_FPS:
		_high_samples += 1
		_low_samples = 0
		if _high_samples >= HIGH_SAMPLES_TO_RAISE:
			_set_scale(current_scale + SCALE_STEP)
			_high_samples = 0
	else:
		_low_samples = 0
		_high_samples = 0


func _set_scale(value: float) -> void:
	var minimum := AUTO_MIN_SCALE if graphics_mode == GraphicsMode.AUTO else 0.5
	var scale := snappedf(clampf(value, minimum, AUTO_MAX_SCALE), 0.01)
	if is_equal_approx(scale, current_scale) \
			and is_equal_approx(get_tree().root.scaling_3d_scale, scale):
		return
	current_scale = scale
	get_tree().root.scaling_3d_scale = current_scale
	# Hạ độ phân giải thì chuyển LOD sớm hơn.
	if graphics_mode == GraphicsMode.AUTO:
		get_tree().root.mesh_lod_threshold = lerpf(2.0, 1.0,
				inverse_lerp(AUTO_MIN_SCALE, AUTO_MAX_SCALE, current_scale))
	render_scale_changed.emit(current_scale)
