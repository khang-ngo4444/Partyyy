@tool
extends McpTestSuite
const LaserGame = preload("res://minigame/laser_leap/laser_leap.gd")
const Beam = preload("res://minigame/laser_leap/laser_beam.gd")
const Session = preload("res://minigame/minigame_session.gd")

func suite_name() -> String:
	return "shared_minigames"

func test_laser_replays_same_seed() -> void:
	var game: Node = LaserGame.new()
	var parameters: Dictionary = game.network_parameters()
	assert_eq(JSON.stringify(LaserGame.build_schedule(4242, 90.0, parameters)),
		JSON.stringify(LaserGame.build_schedule(4242, 90.0, parameters)))
	game.free()

func test_laser_variety_and_telegraph() -> void:
	var game: Node = LaserGame.new()
	var schedule: Array = LaserGame.build_schedule(42, 90.0, game.network_parameters())
	var counts: Dictionary = {}
	var previous_end: float = 0.0
	for wave: Dictionary in schedule:
		assert_true(float(wave["start"]) - previous_end >= game.telegraph_seconds - 0.0001)
		assert_true(wave["beams"].size() >= 1 and wave["beams"].size() <= 3)
		counts[wave["beams"].size()] = true
		previous_end = float(wave["end"])
	assert_eq(counts.size(), 3)
	game.free()

func test_beam_capsule_boundary_and_corner() -> void:
	var half_size := Vector2(15.0, 0.35)
	assert_true(Beam.circle_overlaps_box(Vector2(4.0, 0.74), half_size, 0.4))
	assert_false(Beam.circle_overlaps_box(Vector2(4.0, 0.76), half_size, 0.4))
	assert_false(Beam.circle_overlaps_box(Vector2(15.39, 0.74), half_size, 0.4))

func test_survivors_win_timeout_and_ties_are_stable() -> void:
	var session: Node = Session.new()
	var snapshot: Dictionary = {"ids": [3, 2, 1], "alive": {"1": -1.0, "2": -1.0, "3": 9.0}}
	session._finish(snapshot, 10.0)
	assert_eq(snapshot["ranking"], [1, 2, 3])
	session.free()

func test_disconnected_players_are_removed_from_living_roster() -> void:
	var session: Node = Session.new()
	var snapshot: Dictionary = {"ids": [1, 2, 3], "alive": {"1": 0.0, "2": -1.0, "3": 2.0}}
	assert_eq(session.living_ids(snapshot), [2])
	session.free()
