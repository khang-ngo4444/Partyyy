extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var runner: RefCounted = load("res://addons/godot_ai/testing/test_runner.gd").new()
	for path in ["res://tests/test_magma_clock.gd", "res://tests/test_word_wars_pool.gd",
		"res://tests/test_shared_minigames.gd", "res://tests/test_gameplay_rules.gd"]:
		runner.run_suite(load(path).new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	var runtime_ok: bool = await _check_runtime()
	quit(1 if int(results.get("failed", 0)) > 0 or not runtime_ok else 0)

func _check_runtime() -> bool:
	var game_script: Script = load("res://minigame/magma/magma.gd")
	var arena: Node3D = load("res://minigame/magma/san_magma.tscn").instantiate()
	root.add_child(arena)
	await physics_frame
	await physics_frame
	var slope_ok := true
	for radius: float in [0.0, 3.0, 7.0, 11.0]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(radius, 10, 0), Vector3(radius, -5, 0), 1)
		var hit := arena.get_world_3d().direct_space_state.intersect_ray(ray)
		slope_ok = slope_ok and not hit.is_empty() and absf(hit["position"].y - game_script.cao_san(radius)) < 0.02
	var target := Node3D.new()
	root.add_child(target)
	var ball: Node3D = load("res://minigame/chung/cau_lua.tscn").instantiate()
	root.add_child(ball)
	ball.set_physics_process(false)
	ball.ban(Vector3(0, 1, -2), Vector3.BACK, 2, 0.15)
	var latency_hit: bool = ball.trung(target)
	var forward_push: bool = ball.huong_bay().dot(Vector3.BACK) > 0.999
	ball.free()
	target.free()
	arena.free()
	var controller: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	root.add_child(controller)
	var game: Node = load("res://minigame/chung/mini_game_3d.gd").new()
	controller.get_node("Lop/Khung").add_child(game)
	game._chay = true
	game.giay_van = 75.0
	game._bat_dau_luc = Time.get_ticks_msec() / 1000.0
	controller._game = game
	controller._dang_chay = true
	controller._ve_dong_ho()
	var clock: Label = controller.get_node("Lop/Clock")
	var timer_visible := clock.visible and clock.text == "THỜI GIAN  01:15"
	game._bat_dau_luc -= 70.0
	controller._ve_dong_ho()
	var urgent := clock.modulate.r > clock.modulate.g
	game.giay_van = 0.0
	controller._ve_dong_ho()
	var unlimited_hidden := not clock.visible
	game.giay_van = 75.0
	controller._huong_dan.visible = true
	controller._ve_dong_ho()
	var countdown_hidden := not clock.visible
	controller.free()
	print(JSON.stringify({"slope_collider_matches": slope_ok, "latency_sweep_hits": latency_hit,
		"pushes_along_shot": forward_push, "timer_visible": timer_visible, "timer_urgent": urgent,
		"unlimited_hidden": unlimited_hidden, "countdown_hidden": countdown_hidden}))
	return slope_ok and latency_hit and forward_push and timer_visible and urgent and unlimited_hidden and countdown_hidden
