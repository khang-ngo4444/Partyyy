extends Node

## Các mức đồ hoạ cho cảnh 3D (UI giữ độ phân giải gốc). Mỗi mức một mục đích:
##   MƯỢT: máy yếu, đổi hình lấy FPS. CÂN BẰNG: nét gốc, khử răng cưa vừa, chạy nhẹ.
##   ĐẸP: khử răng cưa mạnh, bóng xa và mịn, đủ chi tiết. TỰ ĐỘNG: tự đổi mức để giữ 60 FPS.
## Scene 3D đọc `thong_so()` khi nhận `graphics_mode_changed` để bật tắt phần của mình.

signal render_scale_changed(scale: float)
## `mode` là mức đang có hiệu lực: không bao giờ là AUTO.
signal graphics_mode_changed(mode: int)

enum GraphicsMode { AUTO, PERFORMANCE, BALANCED, QUALITY }

const THONG_SO := {
	GraphicsMode.PERFORMANCE: {
		"ti_le_3d": 0.75, "msaa": Viewport.MSAA_DISABLED, "fxaa": true, "taa": false,
		"loc_di_huong": Viewport.ANISOTROPY_2X, "lod": 3.0, "co_bong": 2048,
		"loc_bong": RenderingServer.SHADOW_QUALITY_HARD,
		"ssao": false, "chat_luong_ssao": RenderingServer.ENV_SSAO_QUALITY_VERY_LOW, "glow": false,
		"xa_bong": 45.0, "che_do_bong": DirectionalLight3D.SHADOW_ORTHOGONAL,
		"chi_tiet_cao": false, "ti_le_hat": 0.4,
		"mo_ta": "Máy yếu: render 75%, khử răng cưa FXAA, tắt cỏ, ánh sáng phụ và bớt hiệu ứng.",
	},
	GraphicsMode.BALANCED: {
		"ti_le_3d": 1.0, "msaa": Viewport.MSAA_2X, "fxaa": true, "taa": false,
		"loc_di_huong": Viewport.ANISOTROPY_8X, "lod": 1.5, "co_bong": 4096,
		"loc_bong": RenderingServer.SHADOW_QUALITY_SOFT_LOW,
		"ssao": true, "chat_luong_ssao": RenderingServer.ENV_SSAO_QUALITY_LOW, "glow": true,
		"xa_bong": 100.0, "che_do_bong": DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		"chi_tiet_cao": true, "ti_le_hat": 0.7,
		"mo_ta": "Máy tầm trung: nét 100%, MSAA 2x + FXAA, bóng vừa, đủ cỏ và tàu thuyền.",
	},
	GraphicsMode.QUALITY: {
		"ti_le_3d": 1.0, "msaa": Viewport.MSAA_4X, "fxaa": false, "taa": true,
		"loc_di_huong": Viewport.ANISOTROPY_16X, "lod": 0.75, "co_bong": 8192,
		"loc_bong": RenderingServer.SHADOW_QUALITY_SOFT_HIGH,
		"ssao": true, "chat_luong_ssao": RenderingServer.ENV_SSAO_QUALITY_HIGH, "glow": true,
		"xa_bong": 170.0, "che_do_bong": DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS,
		"chi_tiet_cao": true, "ti_le_hat": 1.0,
		"mo_ta": "Máy mạnh: MSAA 4x + TAA hết răng cưa, bóng xa và mịn, chi tiết tối đa.",
	},
}
const MO_TA_TU_DONG := "Tự đổi mức theo sức máy để giữ 60 FPS. Đang dùng: %s."
const TEN_MUC := {
	GraphicsMode.PERFORMANCE: "MƯỢT", GraphicsMode.BALANCED: "CÂN BẰNG", GraphicsMode.QUALITY: "ĐẸP",
}

const SAMPLE_SECONDS := 1.0
const WARMUP_SECONDS := 4.0
## Dưới mức này coi là không giữ nổi 60 FPS.
const LOW_FPS := 54.0
## Thời gian GPU cho một khung (ms) còn dư bao nhiêu mới dám lên mức cao hơn.
const GPU_MS_DE_LEN_MUC := 7.0
const LOW_SAMPLES_TO_DROP := 3
const HIGH_SAMPLES_TO_RAISE := 8
## Vừa tụt mức thì chờ lâu mới thử lại, tránh nhảy qua nhảy lại.
const GIAY_CHO_SAU_KHI_TUT := 60.0
const AUTO_MIN_SCALE := 0.6
const SCALE_STEP := 0.05

var graphics_mode: int = GraphicsMode.AUTO
## Mức đang áp dụng thật (TỰ ĐỘNG cũng quy về một trong ba mức).
var muc_hieu_luc: int = GraphicsMode.BALANCED
var current_scale := 1.0

var _sample_acc := 0.0
var _warmup_left := WARMUP_SECONDS
var _low_samples := 0
var _high_samples := 0
var _cho_len_muc := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.viewport_set_measure_render_time(get_tree().root.get_viewport_rid(), true)
	_ap_muc(GraphicsMode.BALANCED)


func set_graphics_mode(value: int) -> void:
	graphics_mode = clampi(value, GraphicsMode.AUTO, GraphicsMode.QUALITY)
	_dat_lai_dem()
	_cho_len_muc = 0.0
	_ap_muc(GraphicsMode.BALANCED if graphics_mode == GraphicsMode.AUTO else graphics_mode)


func thong_so() -> Dictionary:
	return THONG_SO[muc_hieu_luc]


## Câu mô tả cho bảng cài đặt: mức nào cũng nói rõ để làm gì.
func mo_ta(mode: int) -> String:
	if mode == GraphicsMode.AUTO:
		return MO_TA_TU_DONG % TEN_MUC[muc_hieu_luc]
	return THONG_SO[mode]["mo_ta"]


func _dat_lai_dem() -> void:
	_sample_acc = 0.0
	_warmup_left = WARMUP_SECONDS
	_low_samples = 0
	_high_samples = 0


func _ap_muc(mode: int) -> void:
	muc_hieu_luc = mode
	var ts: Dictionary = THONG_SO[mode]
	var viewport := get_tree().root
	viewport.msaa_3d = ts["msaa"]
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if ts["fxaa"] else Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.use_taa = ts["taa"]
	viewport.use_debanding = true
	viewport.anisotropic_filtering_level = ts["loc_di_huong"]
	viewport.mesh_lod_threshold = ts["lod"]
	RenderingServer.directional_shadow_atlas_set_size(ts["co_bong"], true)
	RenderingServer.directional_soft_shadow_filter_set_quality(ts["loc_bong"])
	RenderingServer.positional_soft_shadow_filter_set_quality(ts["loc_bong"])
	RenderingServer.environment_set_ssao_quality(ts["chat_luong_ssao"], true, 0.5, 2, 50.0, 300.0)
	_set_scale(ts["ti_le_3d"])
	graphics_mode_changed.emit(mode)


func _process(delta: float) -> void:
	_cho_len_muc = maxf(_cho_len_muc - delta, 0.0)
	if graphics_mode != GraphicsMode.AUTO or not DisplayServer.window_is_focused():
		return
	if _warmup_left > 0.0:
		_warmup_left -= delta
		return
	_sample_acc += delta
	if _sample_acc < SAMPLE_SECONDS:
		return
	_sample_acc = fmod(_sample_acc, SAMPLE_SECONDS)
	_danh_gia_tu_dong()


func _danh_gia_tu_dong() -> void:
	var gpu_ms := RenderingServer.viewport_get_measured_render_time_gpu(get_tree().root.get_viewport_rid())
	if Engine.get_frames_per_second() < LOW_FPS:
		_low_samples += 1
		_high_samples = 0
		if _low_samples >= LOW_SAMPLES_TO_DROP:
			_low_samples = 0
			_giam_mot_nac()
	elif gpu_ms > 0.0 and gpu_ms < GPU_MS_DE_LEN_MUC and _cho_len_muc <= 0.0:
		_low_samples = 0
		_high_samples += 1
		if _high_samples >= HIGH_SAMPLES_TO_RAISE:
			_high_samples = 0
			_tang_mot_nac()
	else:
		_low_samples = 0
		_high_samples = 0


## Tụt mức trước; đã ở mức thấp nhất thì mới hạ tiếp độ phân giải.
func _giam_mot_nac() -> void:
	_cho_len_muc = GIAY_CHO_SAU_KHI_TUT
	if muc_hieu_luc > GraphicsMode.PERFORMANCE:
		_dat_lai_dem()
		_ap_muc(muc_hieu_luc - 1)
	else:
		_set_scale(current_scale - SCALE_STEP)


func _tang_mot_nac() -> void:
	var ti_le_chuan: float = THONG_SO[muc_hieu_luc]["ti_le_3d"]
	if current_scale < ti_le_chuan:
		_set_scale(current_scale + SCALE_STEP)
	elif muc_hieu_luc < GraphicsMode.QUALITY:
		_dat_lai_dem()
		_ap_muc(muc_hieu_luc + 1)


func _set_scale(value: float) -> void:
	var ti_le := snappedf(clampf(value, AUTO_MIN_SCALE, 1.0), 0.01)
	var viewport := get_tree().root
	# Đúng 100% thì không qua bộ phóng to, ảnh giữ nguyên độ nét.
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR if ti_le >= 1.0 else Viewport.SCALING_3D_MODE_FSR
	viewport.scaling_3d_scale = ti_le
	current_scale = ti_le
	render_scale_changed.emit(current_scale)
