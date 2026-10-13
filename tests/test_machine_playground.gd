@tool
extends McpTestSuite

const Factory = preload("res://minigame/machine_playground/factory_rules.gd")
const Wave = preload("res://minigame/machine_playground/wave_rules.gd")


func suite_name() -> String:
	return "machine_playground"


func test_each_player_can_complete_five_distinct_parts() -> void:
	var state := Factory.initial([1, 2], 42)
	for kind: int in Factory.PART_COUNT:
		var item: Dictionary = state.items[kind * 2]
		Factory.interact(state, [1, 2], 1, Vector3(item.position[0], 0, item.position[1]), kind * 2)
		Factory.interact(state, [1, 2], 1, Factory.bench(0, 2), kind * 2 + 1)
	assert_eq(state.built["1"], [0, 1, 2, 3, 4])


func test_one_item_cannot_be_claimed_twice() -> void:
	var state := Factory.initial([1, 2], 42)
	state.items = [{"kind": 0, "owner": -1, "position": [0, 0]}]
	Factory.interact(state, [1, 2], 1, Vector3.ZERO, 0)
	assert_false(Factory.interact(state, [1, 2], 2, Vector3.ZERO, 0))


func test_duplicate_part_does_not_increase_assembly() -> void:
	var state := Factory.initial([1, 2], 42)
	state.built["1"] = [0]
	state.held["1"] = 0
	state.items[0].owner = 1
	Factory.interact(state, [1, 2], 1, Factory.bench(0, 2), 1)
	assert_eq(state.built["1"], [0])


func test_splash_preserves_assembled_parts() -> void:
	var state := Factory.initial([1, 2], 42)
	state.built["2"] = [0, 1]
	state.held["2"] = 4
	state.items[4].owner = 2
	Factory.drop(state, 2, Vector3(3, 0, 4))
	assert_eq([state.built["2"], state.held["2"], state.items[4].owner], [[0, 1], -1, -1])


func test_finished_gun_obeys_cooldown() -> void:
	var state := Factory.initial([1], 42)
	state.finished["1"] = 3
	Factory.fire(state, 1, 4)
	assert_false(Factory.fire(state, 1, 4.9))


func test_finish_time_ranks_before_incomplete_assembly() -> void:
	var state := Factory.initial([1, 2, 3], 42)
	state.finished = {"1": 15, "2": 12}
	state.built["3"] = [0, 1, 2, 3]
	assert_eq(Factory.ranking(state, [1, 2, 3], {"1": -1, "2": -1, "3": -1}), [2, 1, 3])


func test_wave_scores_once_per_player_per_cycle() -> void:
	var state := Wave.initial([1])
	Wave.resolve(state, 1, 0, true, 5)
	Wave.resolve(state, 1, 0, true, 6)
	assert_eq(state.score["1"], 1)


func test_wash_keeps_player_in_next_wave() -> void:
	var state := Wave.initial([1])
	Wave.resolve(state, 1, 0, false, 5)
	Wave.resolve(state, 1, 1, true, 17)
	assert_eq(state.score["1"], 1)


func test_warning_then_wave_reaches_beyond_entire_island() -> void:
	assert_eq([Wave.sample(7, 2).warning, Wave.sample(7, 3).active,
		Wave.sample(7, 9).front], [true, true, Wave.EXTENT])


func test_wave_direction_changes_and_seed_is_repeatable() -> void:
	assert_true(Wave.sample(7, 0).direction == Wave.sample(7, 0).direction
		and Wave.sample(7, 0).direction != Wave.sample(7, 12).direction)
