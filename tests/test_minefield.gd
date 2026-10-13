@tool
extends McpTestSuite

const Rules = preload("res://minigame/minefield/mine_rules.gd")

func suite_name() -> String:
	return "minefield"


func test_seed_is_repeatable_and_spawn_is_safe() -> void:
	var state := Rules.initial([1, 2], 7)
	assert_eq(state, Rules.initial([1, 2], 7))
	for index in Rules.COLUMNS * 2:
		assert_false(state.mines[index])
	assert_eq(state.players["1"].hp, 2)


func test_connected_route_for_many_seeds() -> void:
	for seed in 100:
		var state := Rules.initial([1], seed)
		var reached := {0: true}
		var queue: Array = [0]
		while not queue.is_empty():
			var index: int = queue.pop_front()
			for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var x := index % Rules.COLUMNS + direction.x
				var y := index / Rules.COLUMNS + direction.y
				var neighbor := y * Rules.COLUMNS + x
				if x >= 0 and x < Rules.COLUMNS and y >= 0 and y < Rules.ROWS and not state.mines[neighbor] and not reached.has(neighbor):
					reached[neighbor] = true
					queue.append(neighbor)
		var success := false
		for index in range((Rules.ROWS - 1) * Rules.COLUMNS, Rules.ROWS * Rules.COLUMNS):
			success = success or reached.has(index)
		assert_true(success, "Seed %d must have a traversable route" % seed)


func test_two_lives_and_no_double_damage() -> void:
	var state := Rules.initial([1], 2)
	state.mines.fill(false)
	state.mines[17] = true
	state.mines[24] = true
	Rules.advance(state, 1, Rules.center(17), 1)
	assert_eq(state.players["1"].hp, 1)
	Rules.advance(state, 1, Rules.center(24), 1.1)
	assert_eq(state.players["1"].hp, 1)
	Rules.advance(state, 1, Rules.center(24), 2.3)
	assert_eq(state.players["1"].hp, 0)


func test_roller_ignores_hearts_and_immunity() -> void:
	var state := Rules.initial([1], 7)
	state.players["1"].immune = 90
	Rules.advance(state, 1, Vector2(0, 1), 40)
	assert_eq(state.players["1"].hp, 0)
	assert_eq(state.events["1"].kind, "roller")
	assert_true(Rules.front(58) > Rules.LENGTH)
	assert_eq(Rules.front(4), -6.0)


func test_scanning_requires_standing_and_cancels_when_moving() -> void:
	var state := Rules.initial([1], 7)
	Rules.advance(state, 1, Vector2(0, 1), 0)
	Rules.advance(state, 1, Vector2(0, 1), 0.5)
	assert_true(state.revealed.is_empty())
	Rules.advance(state, 1, Vector2(0, 1), 0.7)
	assert_false(state.revealed.is_empty())
	state.revealed.clear()
	Rules.advance(state, 1, Vector2(1, 1), 0.8)
	Rules.advance(state, 1, Vector2(1, 1), 1.1)
	assert_true(state.revealed.is_empty())


func test_swept_movement_hits_intermediate_mine() -> void:
	var state := Rules.initial([1], 7)
	state.mines.fill(false)
	state.mines[17] = true
	Rules.advance(state, 1, Vector2(0, 3), 0)
	Rules.advance(state, 1, Vector2(0, 7), 1)
	assert_eq(state.players["1"].hp, 1)
	assert_true(state.exploded.has("17"))


func test_distance_not_accumulated_and_teleports_rejected() -> void:
	var state := Rules.initial([1], 7)
	state.mines.fill(false)
	Rules.advance(state, 1, Vector2(0, 1), 0)
	Rules.advance(state, 1, Vector2(0, 5), 1)
	Rules.advance(state, 1, Vector2(1, 2), 2)
	assert_eq(state.players["1"].distance, 5.0)
	Rules.advance(state, 1, Vector2(1, 40), 3)
	assert_eq(state.players["1"].distance, 5.0)


func test_clues_and_json_roundtrip() -> void:
	var state := Rules.initial([1], 7)
	state.mines.fill(false)
	state.mines[16] = true
	state.mines[18] = true
	assert_eq(Rules.clue(state, 17), 2)
	state.exploded["16"] = 1
	var restored: Dictionary = JSON.parse_string(JSON.stringify(state))
	assert_eq(Rules.clue(restored, 17), 1)
	Rules.advance(restored, 1, Vector2(0, 1), 0)
	assert_eq(restored.players["1"].hp, 2)


func test_distance_ranking_and_finish_protection() -> void:
	var state := Rules.initial([1, 2], 7)
	state.players["1"].distance = 20
	state.players["1"].hp = 0
	state.players["2"].distance = 10
	assert_eq(Rules.ranking(state, [2, 1], {"1": 5, "2": -1}), [1, 2])
	state.players["2"].last = [0, 47]
	Rules.advance(state, 2, Vector2(0, 48), 10)
	Rules.advance(state, 2, Vector2(0, 48), 59)
	assert_eq(state.players["2"].hp, 2)
	assert_true(Rules.complete(state))
