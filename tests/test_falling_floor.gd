@tool
extends McpTestSuite

const Rules = preload("res://minigame/breaking_blocks/falling_floor_rules.gd")


func suite_name() -> String:
	return "falling_floor"


func test_seed_reproduces_all_group_and_permanent_choices() -> void:
	assert_eq(Rules.plan(735), Rules.plan(735))


func test_regular_groups_include_half_the_map_and_a_quarter() -> void:
	var waves: Array = Rules.plan(7)
	assert_eq([waves[0].tiles.size(), waves[1].tiles.size()], [32, 16])


func test_warning_keeps_collision_before_floor_drops() -> void:
	var waves: Array = Rules.plan(7)
	var tile: int = waves[0].tiles[0]
	var warning: Dictionary = Rules.tile_at(waves, tile, 3.0)
	var dropping: Dictionary = Rules.tile_at(waves, tile, 4.6)
	assert_eq([warning.solid, warning.warning, dropping.solid, dropping.warning],
		[true, true, false, false])


func test_temporary_floor_sinks_then_returns_with_collision() -> void:
	var waves: Array = Rules.plan(7)
	var tile: int = waves[0].tiles[0]
	var down: Dictionary = Rules.tile_at(waves, tile, 5.0)
	var rising: Dictionary = Rules.tile_at(waves, tile, 7.05)
	var restored: Dictionary = Rules.tile_at(waves, tile, 7.4)
	assert_true(down.depth == Rules.DEPTH and not down.solid and rising.depth > 0.0
		and rising.depth < Rules.DEPTH and not rising.solid and restored.solid and restored.depth == 0.0)


func test_permanent_holes_only_remove_edges_and_never_return() -> void:
	var waves: Array = Rules.plan(7)
	var valid := true
	for wave: Dictionary in waves.slice(0, Rules.REGULAR_WAVES):
		for tile: int in wave.permanent:
			valid = valid and Rules._on_edge(tile) and not Rules.tile_at(waves, tile, 54.0).solid
	assert_true(valid)


func test_regular_waves_leave_connected_center_and_enough_floor() -> void:
	var valid := true
	for seed_value: int in 50:
		var waves: Array = Rules.plan(seed_value)
		for wave: Dictionary in waves.slice(0, Rules.REGULAR_WAVES):
			var solid := 0
			for tile: int in Rules.TILE_COUNT:
				if Rules.tile_at(waves, tile, float(wave.start) + 3.0).solid:
					solid += 1
			valid = valid and solid >= 24
	assert_true(valid)


func test_final_whole_map_drop_forces_end_before_one_minute() -> void:
	var waves: Array = Rules.plan(7)
	var all_down := true
	for tile: int in Rules.TILE_COUNT:
		all_down = all_down and not Rules.tile_at(waves, tile, 58.4).solid
	assert_true(all_down)


func test_first_fall_is_last_even_when_client_clocks_disagree() -> void:
	assert_eq(Rules.ranking([1, 2, 3, 4], {1: 50.0, 2: 1.0, 3: -1.0, 4: 2.0}, [1, 4, 2]),
		[3, 2, 4, 1])


func test_duplicate_death_reports_never_duplicate_rank() -> void:
	assert_eq(Rules.ranking([1, 2], {1: 5.0, 2: 5.0}, [1, 1, 2]), [2, 1])


func test_contiguous_floor_and_warning_allow_escape_from_half_map() -> void:
	var tile: Node = load("res://minigame/breaking_blocks/o_vo.tscn").instantiate()
	var width: float = tile.get_node("Mat").mesh.size.x
	tile.free()
	var player: Node = load("res://player/player.tscn").instantiate()
	var speed: float = player.speed
	player.free()
	assert_true(is_equal_approx(width, Rules.TILE_SIZE)
		and Rules.WARNING_SECONDS * speed > Rules.TILE_SIZE * Rules.SIDE * 0.5 + 0.5)
