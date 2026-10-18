extends SceneTree
var failures := 0
var games_checked := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_cmdline_user_args().has("--wide"):
		root.size = Vector2i(1680, 720)
	var selected_game := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--game="):
			selected_game = argument.trim_prefix("--game=")
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var local: int = root.get_node("NetManager").local_id()
	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.set_script(load("res://tests/fixtures/spot_player.gd"))
	player.test_id = local
	fixture.add_child(player)
	var registry: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	fixture.add_child(registry)
	DirAccess.make_dir_recursive_absolute("res://tests/runtime/enclosures")
	for scene: PackedScene in registry.tro_choi:
		var code := scene.resource_path.get_file().get_basename()
		if not selected_game.is_empty() and code != selected_game:
			continue
		games_checked += 1
		print("ENCLOSURE: " + code)
		var game: Node = scene.instantiate()
		fixture.add_child(game)
		if game.has_method("network_parameters"):
			var parameters: Dictionary = game.network_parameters()
			if registry.get_node("Session").supports(code):
				game.shared_snapshot = {"round": 80, "code": code, "seed": 42, "ids": [local],
					"alive": {str(local): -1}, "start": Engine.get_singleton("Fusion").call("get_network_time"),
					"duration": 60.0, "phase": "RUNNING", "parameters": parameters}
				if game.has_method("initial_shared_state"):
					game.shared_snapshot.objective = game.initial_shared_state([local], 42)
		game.bat_dau([local], 42)
		game.set_process(false)
		game.set_physics_process(false)
		await process_frame
		if code == "tank_battle":
			var frame: TextureRect = game.get_node("ScenicFrame")
			check(frame.texture != null and frame.size.x >= root.size.x and frame.size.y >= root.size.y, "Tank illustrated frame covers the viewport")
		else:
			var camera: Camera3D = game._cam_san()
			camera.make_current()
			var shell: Node3D = game.san.get_node("ThemeBackdrop")
			_check_edges(camera, shell, code)
			if code == "laser_leap":
				game._beams[0].present(0, 2, true)
		await _capture(code)
		if code == "lo_da":
			var camera: Camera3D = game._cam_san()
			var saved_position := player.global_position
			camera.position = Vector3(0, game.mat(game.DAI) + game.CAM_CAO, -game.DAI + game.CAM_LUI)
			player.global_position = game.san.to_global(Vector3(0, game.mat(game.DAI) + 1, -game.DAI))
			_check_edges(camera, game.san.get_node("ThemeBackdrop"), "lo_da summit")
			await _capture("lo_da_summit")
			player.global_position = saved_position
		if code == "spotlights":
			game._ve_nhip(8.0)
			await _capture("spotlights_dark")
		game.dung_som()
		await process_frame
		await process_frame
		game.queue_free()
		await process_frame
		await process_frame
	fixture.queue_free()
	await process_frame
	check(games_checked > 0, "The selected minigame exists")
	print("MINIGAME ENCLOSURES: %d games, %d failures" % [games_checked, failures])
	quit(0 if failures == 0 else 1)

func _capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var suffix := "_wide" if OS.get_cmdline_user_args().has("--wide") else ""
	check(root.get_texture().get_image().save_png("res://tests/runtime/enclosures/" + name + suffix + ".png") == OK, "Save capture: " + name)

func _check_edges(camera: Camera3D, shell: Node3D, label: String) -> void:
	for edge: Vector2 in [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1), Vector2(0.5,0), Vector2(0,0.5), Vector2(1,0.5), Vector2(0.5,1)]:
		var pixel := Vector2.ONE + edge * Vector2(root.size - Vector2i(2, 2))
		check(_hits_shell(camera, shell, pixel), label + ": frame edge must hit enclosure at " + str(pixel))

func _hits_shell(camera: Camera3D, shell: Node3D, pixel: Vector2) -> bool:
	var origin := camera.project_ray_origin(pixel)
	var direction := camera.project_ray_normal(pixel)
	for name: String in ["BackWall", "LeftWall", "RightWall", "FrontWall", "Ceiling", "Ground"]:
		var plane: MeshInstance3D = shell.get_node("HorizonGround" if name == "Ground" else "Wrap/" + name)
		var normal := plane.global_basis.y.normalized() if name in ["Ceiling", "Ground"] else plane.global_basis.z.normalized()
		var denominator := normal.dot(direction)
		if absf(denominator) < 0.0001 or (name != "Ground" and denominator >= 0):
			continue
		var distance := normal.dot(plane.global_position - origin) / denominator
		if distance < 0:
			continue
		var point := plane.to_local(origin + direction * distance)
		if absf(point.x) <= 0.501 and absf(point.z if name in ["Ceiling", "Ground"] else point.y) <= 0.501:
			return true
	return false
