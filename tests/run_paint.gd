extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var runner: RefCounted = load("res://addons/godot_ai/testing/test_runner.gd").new()
	runner.run_suite(load("res://tests/test_paint.gd").new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	await _runtime()
	await _serialized_session()
	print("PAINT RUNTIME: %d failures" % failures)
	quit(1 if failures > 0 or int(results.get("failed", 0)) > 0 else 0)


func _runtime() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var local: int = root.get_node("NetManager").local_id()
	var ids: Array = [local, local + 1]
	var players: Array = []
	for id: int in ids:
		var player: Node3D = load("res://player/player.tscn").instantiate()
		player.set_script(load("res://tests/fixtures/spot_player.gd"))
		player.test_id = id
		fixture.add_child(player)
		players.append(player)
	var game: Node = load("res://minigame/paint/paint.tscn").instantiate()
	fixture.add_child(game)
	var original: Vector3 = players[0].global_position
	var snapshot := {"round": 77, "code": "paint", "seed": 5, "ids": ids,
		"alive": {str(local): -1, str(local + 1): -1},
		"start": Engine.get_singleton("Fusion").call("get_network_time"),
		"duration": 60.0, "phase": "RUNNING", "parameters": {"objectives": true},
		"objective": game.initial_shared_state(ids, 5)}
	game.shared_snapshot = snapshot.duplicate(true)
	game.bat_dau(ids, 5)
	game.set_process(false)
	game.set_physics_process(false)
	await physics_frame
	await physics_frame
	players[0].global_position = game.san.to_global(Vector3.ZERO)
	players[1].global_position = game.san.to_global(Vector3(10, 0, 10))
	game.advance_shared_rules(snapshot, 1)
	check(int(snapshot.objective.counts[str(local)]) > 0, "Master should paint at grounded feet")
	var area: int = snapshot.objective.counts[str(local)]
	players[0].global_position += Vector3.UP * 2
	game.advance_shared_rules(snapshot, 1.1)
	check(int(snapshot.objective.counts[str(local)]) == area, "Jump should not paint in air")
	players[0].global_position = game.san.to_global(Vector3.ZERO)
	players[1].global_position = game.san.to_global(Vector3(0, 0, -1))
	check(game.handle_shared_action(snapshot, local, "hit", [], 2), "Nearby facing target can be hit")
	check(not game.handle_shared_action(snapshot, local, "hit", [], 2.1), "Attack cooldown must be master validated")
	var victim_area: int = snapshot.objective.counts[str(local + 1)]
	game.advance_shared_rules(snapshot, 2.2)
	check(int(snapshot.objective.counts[str(local + 1)]) == victim_area, "Hit interrupts target painting")
	game.apply_shared_state(snapshot)
	game._present_shared_players()
	check(game.san.get_node("HUD/Progress").text.contains("%"), "HUD displays current map coverage")
	check(game._view._texture.get_image().get_size() == Vector2i(56, 56), "Rendering uses one compact paint texture")
	if OS.get_cmdline_user_args().has("--capture"):
		await _capture(game, snapshot, ids)
	var controller: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	fixture.add_child(controller)
	controller._game = game
	controller.get_node("Session")._update_rules(snapshot, float(snapshot.start) + 60)
	check(snapshot.phase == "ENDED" and snapshot.has("ranking"), "Minute deadline should finalize coverage ranking")
	game.apply_shared_state(snapshot)
	game._present_shared_players()
	check(not game.san.get_node("HUD").visible, "HUD hides after results")
	game.dung_som()
	check(players[0].global_position.distance_to(original) < 0.01, "Player returns after paint match")
	game.queue_free()
	await process_frame
	fixture.free()


func _capture(game: Node, snapshot: Dictionary, ids: Array) -> void:
	var rules: Script = load("res://minigame/paint/paint_rules.gd")
	for row: int in range(-10, 11, 2):
		for column: int in range(-10, 11):
			rules.paint(snapshot.objective, ids, int(ids[0 if column < 0 else 1]), Vector2(column, row))
	game.apply_shared_state(snapshot)
	game._present_shared_players()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://tests/runtime")
	var image := root.get_texture().get_image()
	check(image.save_png("res://tests/runtime/paint_preview.png") == OK, "Save visual QA frame")


func _serialized_session() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var local: int = root.get_node("NetManager").local_id()
	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.set_script(load("res://tests/fixtures/spot_player.gd"))
	player.test_id = local
	fixture.add_child(player)
	var controller: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	fixture.add_child(controller)
	var rules: Script = load("res://minigame/paint/paint_rules.gd")
	var snapshot := {"round": 78, "code": "paint", "seed": 5, "ids": [local],
		"alive": {str(local): -1}, "start": Engine.get_singleton("Fusion").call("get_network_time"),
		"duration": 60.0, "phase": "RUNNING", "parameters": {"objectives": true},
		"objective": rules.initial([local])}
	var session: Node = controller.get_node("Session")
	# Use the actual network decode and game-start path rather than a typed snapshot.
	session._read_snapshot(JSON.stringify(snapshot))
	var game: Node = controller._game
	game.set_process(false)
	game.set_physics_process(false)
	check(typeof(session.state.ids[0]) == TYPE_INT, "Network roster IDs must remain integers")
	player.global_position = game.san.to_global(Vector3(0, 1, 0))
	for frame: int in 90:
		await physics_frame
		player.velocity = Vector3(3, -3, 0)
		player.move_and_slide()
		session._update_rules(session.state, float(snapshot.start) + frame / 60.0)
	check(player.is_on_floor(), "Paint participant should settle onto the actual arena collider")
	check(int(session.state.objective.counts[str(local)]) > 0, "Decoded network roster must paint while moving")
	session._read_snapshot(JSON.stringify(session.state))
	game._present_shared_players()
	check(game.diem_cua(local) > 0.0, "Painted area reaches the local scoreboard")
	check(game._view._last_cells == session.state.objective.cells, "Decoded coverage reaches the renderer")
	# Dummy headless rendering does not update texture readback; verify pixels on GPU runs.
	if DisplayServer.get_name() != "headless":
		var image: Image = game._view._texture.get_image()
		var brush: Color = load("res://minigame/paint/paint_view.gd").color(0)
		var painted_cell := str(session.state.objective.cells).find("1")
		check(painted_cell >= 0 and image.get_pixel(painted_cell % rules.GRID_SIZE,
			painted_cell / rules.GRID_SIZE).is_equal_approx(Color.from_rgba8(roundi(brush.r * 255),
			roundi(brush.g * 255), roundi(brush.b * 255))), "Decoded coverage reaches the floor texture")
	session._update_rules(session.state, float(snapshot.start) + 60.0)
	session._read_snapshot(JSON.stringify(session.state))
	check(session.state.ranking.find(local) == 0, "Result ranking retains integer IDs after network decode")
	game.dung_som()
	fixture.free()
