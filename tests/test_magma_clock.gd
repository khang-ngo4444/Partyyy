@tool
extends McpTestSuite

const Magma = preload("res://minigame/magma/magma.gd")
const Fireball = preload("res://minigame/chung/cau_lua.gd")
const Host = preload("res://minigame/quan_tro_minigame.gd")
const Game3D = preload("res://minigame/chung/mini_game_3d.gd")

func suite_name() -> String:
	return "magma_clock"

func test_lava_rises_continuously_and_covers_center() -> void:
	var previous := Magma.muc_nham(0.0)
	var previous_safe := 1.0
	for i in range(1, 751):
		var t := i * 0.1
		var height: float = Magma.muc_nham(t)
		assert_true(height >= previous)
		assert_true(height - previous <= 0.0161)
		var safe: float = Magma.ti_le_san(t)
		assert_true(safe <= previous_safe)
		previous = height
		previous_safe = safe
	assert_false(Magma.bi_ngap(Magma.BAN_KINH_SAN, 10.0))
	assert_true(Magma.bi_ngap(Magma.BAN_KINH_SAN, 11.0))
	assert_false(Magma.bi_ngap(0.0, Magma.NGAP_HET_LUC - 5.0))
	assert_true(Magma.bi_ngap(0.0, Magma.NGAP_HET_LUC))
	assert_eq(Magma.ti_le_san(Magma.NGAP_HET_LUC), 0.0)
	assert_true(Magma.NGAP_HET_LUC + 100.0 / Magma.MAT_MAU_MOI_GIAY < 60.0)

func test_fireball_sweeps_past_target_and_respects_height() -> void:
	# Cả hai đầu đạn đều đã ở ngoài người: overlap đơn thuần bỏ sót trường hợp này.
	assert_true(Fireball.quet_trung(Vector3(-4, 1, 0), Vector3(4, 1, 0), Vector3.ZERO))
	assert_false(Fireball.quet_trung(Vector3(-4, 4, 0), Vector3(4, 4, 0), Vector3.ZERO))
	assert_true(Fireball.quet_trung(Vector3(-4, 3, 0), Vector3(4, 3, 0), Vector3(0, 2, 0)))
	assert_true(Fireball.quet_trung(Vector3(-4, 1, 0.94), Vector3(4, 1, 0.94), Vector3.ZERO))
	assert_false(Fireball.quet_trung(Vector3(-4, 1, 0.96), Vector3(4, 1, 0.96), Vector3.ZERO))

func test_parallel_and_zero_length_segments() -> void:
	assert_eq(Fireball.khoang_cach_doan(Vector3.ZERO, Vector3.ZERO,
		Vector3(2, 0, 0), Vector3(2, 0, 0)), 2.0)
	assert_eq(Fireball.khoang_cach_doan(Vector3.ZERO, Vector3.UP,
		Vector3.RIGHT, Vector3.RIGHT + Vector3.UP), 1.0)
	assert_true(Fireball.quet_trung(Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3.ZERO))

func test_predictive_aim_hits_running_target() -> void:
	var origin := Vector3(0, 1, 0)
	var target := Vector3(0, 2, -12)
	var velocity := Vector3(6, 0, 0)
	var direction: Vector3 = Magma.ngam_don(origin, target, velocity)
	var flight_time := (target.z - origin.z) / (direction.z * Fireball.TOC_DO)
	var intercept := origin + direction * Fireball.TOC_DO * flight_time
	assert_true(intercept.distance_to(target + velocity * flight_time) < 0.001)
	assert_true(direction.x > 0.0)
	assert_true(direction.y > 0.0)
	assert_true(Fireball.TOC_DO > 26.0)
	assert_true(Fireball.TOC_DO * Fireball.SONG >= Magma.BAN_KINH_SAN * 2.0)

func test_timer_format_never_shows_negative_seconds() -> void:
	assert_eq(Host.dinh_dang_gio(75.0), "01:15")
	assert_eq(Host.dinh_dang_gio(60.1), "01:01")
	assert_eq(Host.dinh_dang_gio(0.01), "00:01")
	assert_eq(Host.dinh_dang_gio(-1.0), "00:00")

func test_remote_velocity_estimate_follows_motion_but_ignores_teleport() -> void:
	var velocity := Vector3.ZERO
	for frame in range(60):
		velocity = Magma.uoc_luong_van_toc(Vector3.ZERO, Vector3(0.1, 0, 0), velocity, 1.0 / 60.0)
	assert_true(velocity.distance_to(Vector3(6, 0, 0)) < 0.001)
	assert_eq(Magma.uoc_luong_van_toc(Vector3.ZERO, Vector3(300, 0, 0), velocity, 0.016), Vector3.ZERO)
	assert_eq(Magma.uoc_luong_van_toc(Vector3.ZERO, Vector3.ONE, velocity, 0.0), Vector3.ZERO)

func test_timer_uses_shared_duration_and_hides_unlimited_games() -> void:
	var game: Node = track(Game3D.new())
	assert_eq(game.giay_con_lai(), -1.0)
	game._chay = true
	game.giay_van = 0.0
	assert_eq(game.giay_con_lai(), -1.0)
	game.shared_snapshot = {"duration": 90.0}
	game._bat_dau_luc = Fusion.get_network_time() - 15.0
	assert_true(absf(game.giay_con_lai() - 75.0) < 0.1)
	game._bat_dau_luc = Fusion.get_network_time() - 100.0
	assert_eq(game.giay_con_lai(), 0.0)
	game._chay = false
	assert_eq(game.giay_con_lai(), -1.0)

func test_island_contains_real_slope_and_lava_has_fixed_size() -> void:
	var arena: Node = track(load("res://minigame/magma/san_magma.tscn").instantiate())
	assert_true(arena.get_node("SanTron/Than/Hinh").shape is ConvexPolygonShape3D)
	assert_false(arena.has_node("VungBao"))
	assert_false(arena.has_node("VungAnToan"))
	assert_eq(arena.get_node("DungNham").scale, Vector3.ONE)
	assert_true(arena.has_node("TamNgam"))
