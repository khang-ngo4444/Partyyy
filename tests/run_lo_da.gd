extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _run() -> void:
	var runner: RefCounted = load("res://addons/godot_ai/testing/test_runner.gd").new()
	runner.run_suite(load("res://tests/test_lo_da.gd").new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	await _runtime()
	print("LO DA RUNTIME: %d failures" % failures)
	quit(1 if failures > 0 or int(results.get("failed", 0)) > 0 else 0)

func _runtime() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var local: int = root.get_node("NetManager").local_id()
	var players: Array = []
	for i in range(5):
		var player: Node3D = load("res://player/player.tscn").instantiate()
		player.set_script(load("res://tests/fixtures/spot_player.gd"))
		player.test_id = local + i
		player.collision_layer = 2
		fixture.add_child(player)
		players.append(player)
	var game: Node = load("res://minigame/lo_da/lo_da.tscn").instantiate()
	fixture.add_child(game)
	game.bat_dau([local], 42)
	game.set_process(false)
	check(not game.ket_thuc_khi_con_mot, "Solo should have time to climb")
	var slope: Script = load("res://minigame/lo_da/lo_da.gd")
	var player: CharacterBody3D = players[0]
	player.global_position = game.san.to_global(Vector3(0, 1, 2))
	player.khoa_di_chuyen = false
	player.set_physics_process(true)
	await physics_frame
	await physics_frame
	var floor_ok := true
	for distance: float in [0.5, 30, 80, 139, 141]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(4, 360, -distance), Vector3(4, 290, -distance), 1)
		var hit := fixture.get_world_3d().direct_space_state.intersect_ray(ray)
		floor_ok = floor_ok and not hit.is_empty() and absf(float(hit["position"].y) - 300.0 - slope.mat(distance)) < 0.01
	check(floor_ok, "Slope and summit collision should match mathematical ground")
	Input.action_press("move_forward")
	for frame in range(180):
		await physics_frame
	Input.action_release("move_forward")
	check(game.d_cua(local) > 14.0 and player.is_on_floor(), "Real player movement should climb slope")
	var stopped: Vector3 = player.global_position
	for frame in range(30):
		await physics_frame
	check(player.global_position.distance_to(stopped) < 0.05, "Player should stand still without sliding downhill")
	player.set_physics_process(false)
	game._song = {local: -1.0, local + 1: -1.0, local + 2: -1.0, local + 3: 10.0, local + 4: 20.0}
	game._thu_tu_chet = [local + 3, local + 4]
	players[1].global_position = game.san.to_global(Vector3(0, slope.mat(90), -90))
	players[2].global_position = game.san.to_global(Vector3(0, slope.mat(30), -30))
	check(not game.co_the_ve_dich(local), "Finish request before crossing should be rejected")
	player.global_position = game.san.to_global(Vector3(0, slope.mat(142), -142))
	check(game.co_the_ve_dich(local), "Living player beyond finish should qualify")
	game._net_da_ve(local)
	game._net_da_ve(local)
	check(game._ve_dich.size() == 1, "Finish should be recorded only once")
	check(not game._co_the_danh(local), "Finisher should not attack or take attacks")
	game._net_chet(local, 31.0)
	check(game.con_song(local), "Delayed death packet should not eliminate a finisher")
	check(game.xep_hang_hien_tai() == [local, local + 1, local + 2, local + 4, local + 3], "Rank finishers, then climbers, then latest deaths")
	game._net_da_ve(local + 3)
	check(not game._ve_dich.has(local + 3), "Dead player should not finish")
	game._cap_nhat_da(0.7)
	var warning: MeshInstance3D = game._dang[0]["n"].get_node("Vong")
	var radius: float = warning.scale.x
	game._cap_nhat_da(1.2)
	check(is_equal_approx(radius, warning.scale.x), "Warning should show full footprint from the start")
	game._khi_ai_do_chet(local + 1)
	game._song[local + 1] = 35.0
	check(not players[1].model_root.visible and not players[1].name_tag.visible, "Spectator should not leave a floating name")
	check(game._nguoi_dan_dau() == local + 2, "Spectator should follow highest living climber")
	game._chay = false
	game._net_da_ve(local + 2)
	check(not game._ve_dich.has(local + 2), "Late finish should not alter ended match")
	game.dung_som()
	check(players[1].model_root.visible and players[1].name_tag.visible, "Player visibility should restore after match")
	fixture.free()
