@tool
extends McpTestSuite

const Rules = preload("res://minigame/paint/paint_rules.gd")


func suite_name() -> String:
	return "paint"


func test_overpaint_transfers_area_instead_of_counting_layers() -> void:
	var state := Rules.initial([1, 2])
	Rules.paint(state, [1, 2], 1, Vector2.ZERO)
	var area := int(state.counts["1"])
	Rules.paint(state, [1, 2], 2, Vector2.ZERO)
	assert_eq([state.counts["1"], state.counts["2"]], [0, area])


func test_repainting_own_area_does_not_inflate_score() -> void:
	var state := Rules.initial([1])
	Rules.paint(state, [1], 1, Vector2.ZERO)
	var area := int(state.counts["1"])
	Rules.paint(state, [1], 1, Vector2.ZERO)
	assert_eq(state.counts["1"], area)


func test_fast_movement_leaves_continuous_trail() -> void:
	var state := Rules.initial([1])
	Rules.paint(state, [1], 1, Vector2(-2, 0))
	Rules.paint(state, [1], 1, Vector2(2, 0))
	assert_eq(state.cells[28 * Rules.GRID_SIZE + 28], "1")


func test_teleport_does_not_paint_between_endpoints() -> void:
	var state := Rules.initial([1])
	Rules.paint(state, [1], 1, Vector2(-10, 0))
	Rules.paint(state, [1], 1, Vector2(10, 0))
	assert_eq(state.cells[28 * Rules.GRID_SIZE + 28], "0")


func test_jump_breaks_trail_without_filling_air_gap() -> void:
	var state := Rules.initial([1])
	Rules.paint(state, [1], 1, Vector2(-2, 0))
	Rules.stop_stroke(state, 1)
	Rules.paint(state, [1], 1, Vector2(2, 0))
	assert_eq(state.cells[28 * Rules.GRID_SIZE + 28], "0")


func test_paint_is_clipped_to_map_and_count_matches_grid() -> void:
	var state := Rules.initial([1])
	Rules.paint(state, [1], 1, Vector2(14, 14))
	assert_eq(int(state.counts["1"]), state.cells.count("1"))


func test_unknown_player_cannot_paint() -> void:
	assert_false(Rules.paint(Rules.initial([1]), [1], 2, Vector2.ZERO))


func test_hit_has_cooldown_and_interrupts_painting() -> void:
	var state := Rules.initial([1, 2])
	Rules.paint(state, [1, 2], 2, Vector2.ZERO)
	Rules.hit(state, 1, 2, 5, Vector2.RIGHT)
	assert_eq([Rules.hit(state, 1, 2, 5.1, Vector2.RIGHT), state.last.has("2"), state.stun["2"]],
		[false, false, 5 + Rules.STUN_SECONDS])


func test_roundtrip_snapshot_preserves_exact_ownership() -> void:
	var state := Rules.initial([1, 2])
	Rules.paint(state, [1, 2], 1, Vector2.ZERO)
	Rules.paint(state, [1, 2], 2, Vector2(0.5, 0))
	var restored: Dictionary = JSON.parse_string(JSON.stringify(state))
	assert_eq([restored.cells, int(restored.counts["1"]), int(restored.counts["2"])],
		[state.cells, int(state.counts["1"]), int(state.counts["2"])])


func test_rank_uses_final_coverage_and_departures_rank_last() -> void:
	var state := Rules.initial([1, 2, 3])
	state.counts = {"1": 50, "2": 80, "3": 100}
	assert_eq(Rules.ranking(state, [1, 2, 3], {"1": -1, "2": -1, "3": 5}), [2, 1, 3])

func test_miss_has_a_replicated_swing_and_cooldown() -> void:
	var state := Rules.initial([1, 2])
	assert_true(Rules.swing(state, 1, 2))
	assert_eq(state.swings["1"].serial, 1)
	assert_false(Rules.hit(state, 1, 2, 2.1, Vector2.RIGHT))
	assert_true(state.events.is_empty())
	state.stun["1"] = 5.0
	assert_false(Rules.swing(state, 1, 4.0))
