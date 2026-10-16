extends SceneTree

var failures := 0

class ActionRecorder extends Node:
	var actions: Array = []
	func request_action(action: String, _payload: Array) -> void:
		actions.append(action)

func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var runner: RefCounted = load("res://addons/godot_ai/testing/test_runner.gd").new()
	runner.run_suite(load("res://tests/test_minefield.gd").new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	await _runtime()
	print("MINEFIELD RUNTIME: %d failures" % failures)
	quit(1 if failures > 0 or int(results.get("failed", 0)) > 0 else 0)


func _runtime() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var id: int = root.get_node("NetManager").local_id()
	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.set_script(load("res://tests/fixtures/spot_player.gd"))
	fixture.add_child(player)
	var original: Vector3 = player.global_position
	var jumps: int = player.so_lan_nhay
	var controller: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	fixture.add_child(controller)
	var game: Node = load("res://minigame/minefield/minefield.tscn").instantiate()
	var authored_arena: Node3D = game.get_node("Arena")
	check(authored_arena.get_node("Tiles").get_child_count() == 56, "All tiles exist before running the scene")
	check(authored_arena.has_node("ThemeBackdrop/Wrap/BackWall"), "Scenery exists in the authored scene")
	check(authored_arena.get_node("Cam").environment != null and not authored_arena.has_node("Environment"), "Authored camera environment cannot change the lobby world")
	var authored_wall: MeshInstance3D = authored_arena.get_node("ThemeBackdrop/Wrap/BackWall")
	var authored_material := authored_wall.material_override
	var authored_wall_transform := authored_wall.transform
	fixture.add_child(game)
	var snapshot := {"round": 43, "code": "minefield", "seed": 7, "ids": [id],
		"alive": {str(id): -1}, "start": Engine.get_singleton("Fusion").call("get_network_time"),
		"duration": game.giay_van, "phase": "RUNNING",
		"objective": game.initial_shared_state([id], 7), "parameters": {"objectives": true}}
	game.shared_snapshot = snapshot.duplicate(true)
	game.bat_dau([id], 7)
	check(game.san == authored_arena, "Gameplay uses the existing Arena node")
	check(game.san.get_node("Tiles").get_child_count() == 56, "Starting the round does not duplicate tiles")
	check(authored_wall.material_override == authored_material and authored_wall.transform == authored_wall_transform, "Runtime preserves authored scenery settings")
	game.set_process(false)
	game.set_physics_process(false)
	await physics_frame
	await physics_frame
	game._present_shared_players()
	check(game._tiles.size() == 56, "Four-column field uses 56 tiles")
	for index in game._tiles.size():
		var center: Vector2 = load("res://minigame/minefield/mine_rules.gd").center(index)
		check(game._tiles[index].position == Vector3(center.x, 0, -center.y), "Authored tile matches rule coordinates: %d" % index)
	check(game.giay_con_lai() > 59 and game.giay_con_lai() <= 60, "One minute timer")
	check(player.so_lan_nhay == 0, "Jumping is disabled during minefield")
	var ray := PhysicsRayQueryParameters3D.create(Vector3(0, 310, -20), Vector3(0, 290, -20), 1)
	check(not fixture.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Continuous playable floor")
	controller._game = game
	var session: Node = controller.get_node("Session")
	session._update_rules(snapshot, float(snapshot.start) + 1)
	check(snapshot.phase == "RUNNING", "Solo practice must not end immediately")
	check(snapshot.objective.revealed.is_empty(), "No automatic scanner during simulation")
	check(game.handle_shared_action(snapshot, id, "scan", [], 1), "Master accepts right-click scanner action")
	check(not game.handle_shared_action(snapshot, id, "scan", [], 1.1), "Scanner cooldown cannot be bypassed")
	check(not snapshot.objective.revealed.is_empty(), "Explicit scan reveals nearby cells")
	var recorder := ActionRecorder.new()
	fixture.add_child(recorder)
	game.shared_session = recorder
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	game._input(click)
	check(recorder.actions.is_empty(), "Left click must not scan")
	click.button_index = MOUSE_BUTTON_RIGHT
	game._input(click)
	check(recorder.actions == ["scan"], "Right click sends the scanner action")
	game.shared_session = null
	recorder.free()
	var rules: Script = load("res://minigame/minefield/mine_rules.gd")
	var mine: int = snapshot.objective.mines.find(true)
	var center: Vector2 = rules.center(mine)
	player.global_position = game.san.to_global(Vector3(center.x, 0, -center.y))
	snapshot.objective.players[str(id)].last = []
	game.advance_shared_rules(snapshot, 2)
	check(int(snapshot.objective.players[str(id)].hp) == 1, "Master resolves first mine hit")
	check(float(snapshot.alive[str(id)]) < 0, "First hit is not elimination")
	snapshot.objective.players[str(id)].immune = 100
	game.advance_shared_rules(snapshot, 23)
	check(float(snapshot.alive[str(id)]) == 23, "Faster roller eliminates despite immunity")
	session._update_rules(snapshot, float(snapshot.start) + 23)
	check(snapshot.phase == "ENDED", "All eliminated ends early")
	check(snapshot.ranking == [id], "Distance ranking is published")
	if OS.get_cmdline_user_args().has("--capture"):
		snapshot.phase = "RUNNING"
		snapshot.alive[str(id)] = -1
		snapshot.objective.players[str(id)].hp = 2
		snapshot.objective.players[str(id)].distance = 8
		for index in 42:
			snapshot.objective.revealed[str(index)] = true
		player.global_position = game.san.to_global(Vector3(0, 0, -8))
		game._bat_dau_luc = Engine.get_singleton("Fusion").call("get_network_time") - 10
		game.shared_snapshot = snapshot
		game._present_shared_players()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/runtime/minefield_preview.png")
	game.dung_som()
	check(player.so_lan_nhay == jumps, "Original jump setting restored")
	check(player.global_position.distance_to(original) < 0.01, "Original position restored")
	game.queue_free()
	await process_frame
	fixture.free()
