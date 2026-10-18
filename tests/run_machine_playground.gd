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
	runner.run_suite(load("res://tests/test_machine_playground.gd").new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	await _runtime()
	print("MACHINE PLAYGROUND RUNTIME: %d failures" % failures)
	quit(1 if failures > 0 or int(results.get("failed", 0)) > 0 else 0)


func _runtime() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var local: int = root.get_node("NetManager").local_id()
	var ids: Array = [local, local + 1]
	var alive := {str(local): -1, str(local + 1): -1}
	var players: Array = []
	for id: int in ids:
		var player: Node3D = load("res://player/player.tscn").instantiate()
		player.set_script(load("res://tests/fixtures/spot_player.gd"))
		player.test_id = id
		fixture.add_child(player)
		players.append(player)
	var controller: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	fixture.add_child(controller)
	var session: Node = controller.get_node("Session")
	var original: Vector3 = players[0].global_position
	for code: String in ["toy_factory", "wave_hide"]:
		var game: Node = load("res://minigame/machine_playground/" + code + ".tscn").instantiate()
		fixture.add_child(game)
		var snapshot := {"round": 42, "code": code, "seed": 7, "ids": ids,
			"alive": alive, "start": Engine.get_singleton("Fusion").call("get_network_time"),
			"duration": game.giay_van, "phase": "RUNNING",
			"objective": game.initial_shared_state(ids, 7), "parameters": {"objectives": true}}
		game.shared_snapshot = snapshot.duplicate(true)
		game.bat_dau(ids, 7)
		game.set_process(false)
		game.set_physics_process(false)
		await physics_frame
		await physics_frame
		game._present_shared_players()
		check(game.san.get_node("HUD").visible, "Compact objective should show while running")
		check(game.giay_con_lai() > 50 and game.giay_con_lai() <= 60, "New minigames should use one minute countdown")
		var ray := PhysicsRayQueryParameters3D.create(Vector3(4, 310, -1), Vector3(4, 290, -1), 1)
		var hit := fixture.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and absf(hit.position.y - 300) < 0.05, "Playable ground must match visual floor")
		if code == "toy_factory":
			check(game._items.size() == 10 and game._benches.size() == 2, "Create five parts per player and own bench")
			var item: Dictionary = snapshot.objective.items[0]
			players[0].global_position = game.san.to_global(Vector3(item.position[0], 0, item.position[1]))
			check(game.handle_shared_action(snapshot, local, "interact", [], 1), "Master accepts nearby pickup")
			check(not game.handle_shared_action(snapshot, local, "spray", [1, 0], 1), "Unfinished gun cannot fire")
			var victim: Node3D = players[1]
			victim.global_position = game.san.to_global(Vector3(0, 0, 0))
			snapshot.objective.finished[str(local)] = 1
			victim.global_position = game.san.to_global(Vector3(3, 0, 0))
			players[0].global_position = game.san.to_global(Vector3.ZERO)
			snapshot.objective.held[str(local + 1)] = 2
			snapshot.objective.items[2].owner = local + 1
			check(game.handle_shared_action(snapshot, local, "spray", [1, 0], 2), "Finished gun should fire")
			check(int(snapshot.objective.held[str(local + 1)]) == -1, "Validated splash should drop target item")
		else:
			var land: CSGPolygon3D = game.san.get_node("Land")
			check(land.polygon.size() == 9, "Island should preserve editable irregular outline")
			check(game.sheltered(game.san.to_global(Vector3(2.5, 0, 0)), Vector2.RIGHT), "Rock should protect nearby downstream player")
			check(not game.sheltered(game.san.to_global(Vector3(-2.5, 0, 0)), Vector2.RIGHT), "Rock should not protect upstream player")
			var sample: Dictionary = load("res://minigame/machine_playground/wave_rules.gd").sample(7, 8.9)
			players[0].global_position = game.san.to_global(Vector3(5, 0, 0))
			players[1].global_position = game.san.to_global(Vector3(-5, 0, 0))
			game.advance_shared_rules(snapshot, 8.9)
			check(snapshot.objective.resolved.size() == 2, "Whole wave crossing should resolve both players even after skipped ticks")
			game.advance_shared_rules(snapshot, 8.95)
			check(snapshot.objective.resolved.size() == 2, "Same wave should not resolve twice")
		controller._game = game
		session._update_rules(snapshot, float(snapshot.start) + 1)
		check(snapshot.phase == "RUNNING", "Objectives must run full duration, including solo practice")
		session._update_rules(snapshot, float(snapshot.start) + float(snapshot.duration))
		check(snapshot.phase == "ENDED" and snapshot.has("ranking"), "Session must finish objective games with their own ranking")
		snapshot.phase = "ENDED"
		snapshot.ended = snapshot.start + snapshot.duration
		snapshot.ranking = game.shared_ranking(snapshot)
		game.apply_shared_state(snapshot)
		game._present_shared_players()
		check(not game.san.get_node("HUD").visible, "Objectives hide during results")
		game.dung_som()
		check(players[0].global_position.distance_to(original) < 0.01, "Leaving game should restore player location")
		game.queue_free()
		await process_frame
		check(fixture.get_child_count() == 3, "Arena and assets must clean up")
	fixture.free()
