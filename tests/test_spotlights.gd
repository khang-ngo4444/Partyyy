@tool
extends McpTestSuite

const Spot = preload("res://minigame/spotlights/spotlights.gd")

func suite_name() -> String:
	return "spotlights"

func test_initial_two_lights_increase_each_cycle() -> void:
	assert_eq(Spot.so_den(0.0), 2)
	assert_eq(Spot.so_den(-5.0), 2)
	for cycle in range(12):
		assert_eq(Spot.so_den(cycle * Spot.CHU_KY + 0.01), mini(2 + cycle, Spot.DEN_TOI_DA))

func test_bright_dark_and_relight_windows_repeat_smoothly() -> void:
	assert_eq(Spot.do_sang(0.0), 1.0)
	assert_eq(Spot.do_sang(2.49), 1.0)
	assert_true(Spot.do_sang(3.3) > 0.49 and Spot.do_sang(3.3) < 0.51)
	assert_eq(Spot.do_sang(6.0), 0.0)
	assert_eq(Spot.do_sang(9.0), 0.0)
	assert_eq(Spot.do_sang(Spot.CHU_KY), 1.0)
	assert_eq(Spot.ten_pha(0.0), "GHI NHỚ VỊ TRÍ")
	assert_eq(Spot.ten_pha(2.8), "ĐÈN ĐANG TẮT")
	assert_eq(Spot.ten_pha(6.0), "NÉ SPOTLIGHT")
	assert_eq(Spot.ten_pha(11.0), "ĐÈN ĐANG BẬT")
	for frame in range(4500):
		var time := frame / 60.0
		assert_true(absf(Spot.do_sang(time + 1.0 / 60.0) - Spot.do_sang(time)) <= 0.012)

func test_memory_window_is_safe_and_dangerous_footprint_is_exact() -> void:
	assert_false(Spot.co_nguy_hiem(2.49))
	assert_true(Spot.co_nguy_hiem(2.5))
	assert_true(Spot.cham_den(Vector2(2.66, 0), Vector2.ZERO))
	assert_false(Spot.cham_den(Vector2(2.67, 0), Vector2.ZERO))
	assert_true(Spot.cham_den(Vector2(4, 6), Vector2(4, 6)))

func test_moving_lights_stay_on_floor_and_leave_room_to_escape() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261012
	for light in range(8):
		var phase := rng.randf() * TAU
		var frequency := rng.randf_range(0.28, 0.52)
		for sample in range(750):
			var t := sample * 0.1
			var point: Vector2 = Spot.cho_den(phase, frequency, t)
			assert_true(point.length() + Spot.BAN_KINH_DEN < 11.5)
			var speed: float = point.distance_to(Spot.cho_den(phase, frequency, t + 0.01)) / 0.01
			assert_true(speed < 6.0)

func test_scene_keeps_eight_beams_and_self_marker() -> void:
	var arena: Node = track(load("res://minigame/spotlights/san_spot.tscn").instantiate())
	assert_eq(arena.find_children("Den*", "Node3D", false, false).size(), 8)
	assert_true(arena.has_node("DauToi"))
	var game: Node = track(load("res://minigame/spotlights/spotlights.tscn").instantiate())
	assert_true(game.has_node("Pha/Nhan"))

func test_actual_spotlights_point_down_at_the_floor() -> void:
	var arena: Node = track(load("res://minigame/spotlights/san_spot.tscn").instantiate())
	for index in range(8):
		var light: SpotLight3D = arena.get_node("Den%d/Bong" % index)
		assert_true((light.basis * Vector3.FORWARD).dot(Vector3.DOWN) > 0.999)
		assert_true(light.spot_range > light.position.y)

func test_spawn_positions_avoid_initial_spotlights_and_other_players() -> void:
	for seed_value in range(32):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var lights: Array[Vector2] = []
		for light in range(2):
			var phase := rng.randf() * TAU
			var frequency := rng.randf_range(0.28, 0.52)
			lights.append(Spot.cho_den(phase, frequency, 0.0))
		for count in [1, 2, 4, 8]:
			var previous: Array[Vector2] = []
			for index in range(count):
				var spawn: Vector3 = Spot.cho_vao_an_toan(index, count, lights)
				var point := Vector2(spawn.x, spawn.z)
				assert_true(point.length() < Spot.BAN_KINH_GIU)
				for light: Vector2 in lights:
					assert_true(point.distance_to(light) >= Spot.BAN_KINH_DEN + 0.89)
				for other: Vector2 in previous:
					assert_true(point.distance_to(other) > 1.0)
				previous.append(point)
