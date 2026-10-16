@tool
extends McpTestSuite

const Rules = preload("res://minigame/minefield/mine_rules.gd")

func suite_name() -> String:
	return "minefield"


func test_seed_is_repeatable_and_spawn_is_safe() -> void:
	var state := Rules.initial([1, 2], 7)
	assert_eq(state, Rules.initial([1, 2], 7))
	assert_true(state.mines != Rules.initial([1, 2], 9).mines, "Different seeds must randomize mine positions")
	for index in Rules.COLUMNS * Rules.SAFE_ROWS:
		assert_false(state.mines[index])
	assert_eq(state.players["1"].hp, 2)


func test_dense_random_fields_for_many_seeds() -> void:
	var danger_cells := Rules.COLUMNS * (Rules.ROWS - Rules.SAFE_ROWS)
	for seed in 100:
		var state := Rules.initial([1], seed)
		var density := float(state.mines.count(true)) / danger_cells
		assert_true(density >= 0.6 and density <= 0.7, "Seed %d must remain densely mined" % seed)
		assert_eq(state.mines.size(), Rules.COLUMNS * Rules.ROWS)


func test_two_lives_and_no_double_damage() -> void:
	var state := Rules.initial([1], 2)
	state.mines.fill(false)
	var first := Rules.COLUMNS * 2 + 2
	var second := first + Rules.COLUMNS
	state.mines[first] = true
	state.mines[second] = true
	Rules.advance(state, 1, Rules.center(first), 1)
	assert_eq(state.players["1"].hp, 1)
	Rules.advance(state, 1, Rules.center(second), 1.1)
	assert_eq(state.players["1"].hp, 1)
	Rules.advance(state, 1, Rules.center(second), 2.3)
	assert_eq(state.players["1"].hp, 0)


func test_roller_ignores_hearts_and_immunity() -> void:
	var state := Rules.initial([1], 7)
	state.players["1"].immune = 90
	Rules.advance(state, 1, Vector2(0, 1), 40)
	assert_eq(state.players["1"].hp, 0)
	assert_eq(state.events["1"].kind, "roller")
	assert_true(Rules.front(23) > Rules.LENGTH)
	assert_eq(Rules.front(1), -4.0)
	assert_true(Rules.front(10) > 5, "Roller should pressure the field early")


func test_no_auto_scan_and_explicit_scan_cooldown() -> void:
	var state := Rules.initial([1], 7)
	Rules.advance(state, 1, Vector2(0, 1), 0)
	Rules.advance(state, 1, Vector2(0, 1), 0.5)
	assert_true(state.revealed.is_empty())
	Rules.advance(state, 1, Vector2(0, 1), 0.7)
	assert_true(state.revealed.is_empty(), "Standing still must never auto scan")
	assert_true(Rules.scan(state, 1, Vector2(0, 1), 1))
	assert_false(state.revealed.is_empty())
	assert_false(Rules.scan(state, 1, Vector2(0, 1), 1.1))
	assert_true(Rules.scan(state, 1, Vector2(0, 1), 1.8))
	state.players["1"].hp = 0
	assert_false(Rules.scan(state, 1, Vector2(0, 1), 3))
	assert_false(Rules.scan(state, 999, Vector2(0, 1), 3))


func test_random_generation_does_not_reserve_edges_or_a_corridor() -> void:
	var row_counts := {}
	var mined_cells := {}
	var clear_cells := {}
	for seed in 100:
		var state := Rules.initial([1], seed)
		for row in range(Rules.SAFE_ROWS, Rules.ROWS):
			var mine_count := 0
			for column in Rules.COLUMNS:
				var index := row * Rules.COLUMNS + column
				if state.mines[index]:
					mine_count += 1
					mined_cells[index] = true
				else:
					clear_cells[index] = true
			row_counts[mine_count] = true
	for count in range(Rules.COLUMNS + 1):
		assert_true(row_counts.has(count), "Random rows can contain %d mines, including full barriers" % count)
	var danger_cells := Rules.COLUMNS * (Rules.ROWS - Rules.SAFE_ROWS)
	assert_eq(mined_cells.size(), danger_cells, "Every danger cell can contain a mine")
	assert_eq(clear_cells.size(), danger_cells, "No lane or edge is permanently mined")


func test_swept_movement_hits_intermediate_mine() -> void:
	var state := Rules.initial([1], 7)
	state.mines.fill(false)
	var mine := Rules.COLUMNS * 2 + 2
	state.mines[mine] = true
	var x := Rules.center(mine).x
	Rules.advance(state, 1, Vector2(x, 3), 0)
	Rules.advance(state, 1, Vector2(x, 7), 1)
	assert_eq(state.players["1"].hp, 1)
	assert_true(state.exploded.has(str(mine)))


func test_distance_not_accumulated_and_teleports_rejected() -> void:
	var state := Rules.initial([1], 7)
	state.mines.fill(false)
	Rules.advance(state, 1, Vector2(0, 1), 0)
	Rules.advance(state, 1, Vector2(0, 5), 1)
	Rules.advance(state, 1, Vector2(1, 2), 2)
	assert_eq(state.players["1"].distance, 5.0)
	Rules.advance(state, 1, Vector2(1, 40), 3)
	assert_eq(state.players["1"].distance, 5.0)


func test_scan_and_json_roundtrip() -> void:
	var state := Rules.initial([1], 7)
	assert_true(Rules.scan(state, 1, Vector2(0, 1), 1))
	var restored: Dictionary = JSON.parse_string(JSON.stringify(state))
	assert_eq(restored.revealed.size(), state.revealed.size())
	assert_false(Rules.scan(restored, 1, Vector2(0, 1), 1.1))
	Rules.advance(restored, 1, Vector2(0, 1), 0)
	assert_eq(restored.players["1"].hp, 2)


func test_distance_ranking_and_finish_protection() -> void:
	var state := Rules.initial([1, 2], 7)
	state.players["1"].distance = 20
	state.players["1"].hp = 0
	state.players["2"].distance = 10
	assert_eq(Rules.ranking(state, [2, 1], {"1": 5, "2": -1}), [1, 2])
	state.mines.fill(false)
	state.players["2"].last = [0, Rules.LENGTH - 1]
	Rules.advance(state, 2, Vector2(0, Rules.LENGTH), 10)
	Rules.advance(state, 2, Vector2(0, Rules.LENGTH), 59)
	assert_eq(state.players["2"].hp, 2)
	assert_true(Rules.complete(state))
