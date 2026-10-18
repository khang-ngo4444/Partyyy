@tool
extends McpTestSuite

const Rocks = preload("res://minigame/lo_da/lo_da.gd")

func suite_name() -> String:
	return "lo_da"

func test_swept_collision_catches_fast_rolling_stone() -> void:
	var rock := {"t": 5.0, "d": 65.0, "x": 0.0, "r": Rocks.R_NHO, "bao": 1.4}
	var feet := Vector3(0, Rocks.mat(50), -50)
	assert_false(Rocks.cham(rock, 5.0, feet))
	assert_false(Rocks.cham(rock, 7.5, feet))
	assert_true(Rocks.cham_qua(rock, 5.0, 7.5, feet, feet))

func test_warning_period_has_no_damage() -> void:
	var rock := {"t": 5.0, "d": 65.0, "x": 0.0, "r": Rocks.R_TO, "bao": 1.4}
	var feet := Vector3(0, Rocks.mat(65), -65)
	assert_false(Rocks.cham_qua(rock, 3.6, 4.0, feet, feet))
	assert_true(Rocks.cham_qua(rock, 4.0, 5.0, feet, feet))

func test_swept_collision_respects_jump_and_lateral_escape() -> void:
	var rock := {"t": 0.0, "d": 70.0, "x": 0.0, "r": Rocks.R_NHO, "bao": 1.4}
	var left := Vector3(5, Rocks.mat(55), -55)
	assert_false(Rocks.cham_qua(rock, 0.0, 3.0, left, left))
	var jump := Vector3(0, Rocks.mat(55) + 2.4, -55)
	assert_false(Rocks.cham_qua(rock, 1.8, 2.2, jump, jump))

func test_stone_visual_radius_matches_gameplay_radius() -> void:
	var scene: PackedScene = load("res://minigame/lo_da/da.tscn")
	var stone := scene.instantiate()
	var mesh: SphereMesh = stone.get_node("Than").mesh
	assert_eq(mesh.radius, 1.0)
	assert_eq(mesh.height, 2.0)
	stone.free()

func test_meteor_wall_reaches_summit_without_outrunning_players() -> void:
	assert_true(Rocks.pha_d(60.0) >= Rocks.DAI)
	assert_true(Rocks.PHA_TOC_CUOI < 6.0)

func test_schedule_preserves_seed_and_spawn_grace() -> void:
	assert_eq(str(Rocks.lich_da(7)), str(Rocks.lich_da(7)))
	assert_true(str(Rocks.lich_da(7)) != str(Rocks.lich_da(8)))
	for seed in range(10):
		for rock: Dictionary in Rocks.lich_da(seed):
			assert_true(float(rock["t"]) - float(rock["bao"]) >= 0.5)
			assert_true(float(rock["bao"]) >= 0.9)
			assert_true(float(rock["d"]) >= Rocks.D_MIN)
