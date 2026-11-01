extends SceneTree

## Mỗi mức đồ hoạ phải khác nhau thật và đúng mục đích, kể cả trên đảo.

const MUOT := 1
const CAN_BANG := 2
const DEP := 3

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var board: Node3D = load("res://board/ban_party.tscn").instantiate()
	fixture.add_child(board)
	var map_model := board.get_node("MapModel")
	var quan_ly := root.get_node("PerformanceManager")
	_kiem_tra_muot(quan_ly, map_model)
	_kiem_tra_can_bang(quan_ly, map_model)
	_kiem_tra_dep(quan_ly, map_model)
	_kiem_tra_tu_dong(quan_ly)
	print("MUC DO HOA: %d failures" % failures)
	quit(failures)


func _kiem_tra_muot(quan_ly: Node, map_model: Node) -> void:
	quan_ly.set_graphics_mode(MUOT)
	check(root.scaling_3d_scale < 1.0 and root.msaa_3d == Viewport.MSAA_DISABLED, "MUOT saves GPU time")
	check(root.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA, "MUOT still has cheap anti-aliasing")
	check(not map_model.get_node("CoVaHoa").visible, "MUOT hides grass")
	check(not map_model.get_node("ChuyenDong/Thuyen/BuonXa").visible, "MUOT hides far boats")
	check(not map_model.get_node("RumbleReefEnvironment").environment.ssao_enabled, "MUOT disables SSAO")


func _kiem_tra_can_bang(quan_ly: Node, map_model: Node) -> void:
	quan_ly.set_graphics_mode(CAN_BANG)
	check(is_equal_approx(root.scaling_3d_scale, 1.0), "CAN BANG renders at native resolution")
	check(root.msaa_3d == Viewport.MSAA_2X, "CAN BANG uses MSAA 2x")
	check(root.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED and not root.use_taa, "CAN BANG keeps the picture sharp")
	check(map_model.get_node("CoVaHoa").visible, "CAN BANG shows grass")


func _kiem_tra_dep(quan_ly: Node, map_model: Node) -> void:
	quan_ly.set_graphics_mode(DEP)
	check(root.msaa_3d == Viewport.MSAA_4X, "DEP uses the strongest anti-aliasing")
	check(root.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED and not root.use_taa, "DEP keeps the picture sharp")
	check(root.anisotropic_filtering_level == Viewport.ANISOTROPY_16X, "DEP filters textures at 16x")
	check(map_model.get_node("MatTroi").directional_shadow_max_distance
			> 100.0, "DEP draws shadows further")
	var hat: GPUParticles3D = map_model.get_node("KhoiNuiLua")
	check(is_equal_approx(hat.amount_ratio, 1.0), "DEP keeps every particle")


func _kiem_tra_tu_dong(quan_ly: Node) -> void:
	quan_ly.set_graphics_mode(0)
	check(quan_ly.muc_hieu_luc == CAN_BANG, "AUTO starts balanced and native, not blurred")
	quan_ly._giam_mot_nac()
	check(quan_ly.muc_hieu_luc == MUOT, "AUTO drops a whole tier when FPS is low")
	quan_ly._cho_len_muc = 0.0
	quan_ly.current_scale = quan_ly.THONG_SO[MUOT]["ti_le_3d"]
	quan_ly._tang_mot_nac()
	check(quan_ly.muc_hieu_luc == CAN_BANG, "AUTO climbs back when the GPU has headroom")
	check(quan_ly.mo_ta(0).contains("CÂN BẰNG"), "AUTO description names the active tier")
