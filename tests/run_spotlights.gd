extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var runner: RefCounted = load("res://addons/godot_ai/testing/test_runner.gd").new()
	runner.run_suite(load("res://tests/test_spotlights.gd").new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	var runtime_ok: bool = await _check_runtime()
	quit(1 if int(results.get("failed", 0)) > 0 or not runtime_ok else 0)

func _check_runtime() -> bool:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var sun := DirectionalLight3D.new()
	sun.light_energy = 3.0
	sun.light_cull_mask = 1048575
	fixture.add_child(sun)
	var omni := OmniLight3D.new()
	omni.light_cull_mask = 1048575
	fixture.add_child(omni)
	var hidden := SpotLight3D.new()
	hidden.visible = false
	hidden.light_cull_mask = 1048575
	fixture.add_child(hidden)
	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.set_script(load("res://tests/fixtures/spot_player.gd"))
	fixture.add_child(player)
	player.position = Vector3(0, 300.2, 0)
	var meshes: Array = player.model_root.find_children("*", "MeshInstance3D", true, false)
	var mesh: GeometryInstance3D = meshes[0]
	var original_layer := mesh.layers
	var game: Node = load("res://minigame/spotlights/spotlights.tscn").instantiate()
	fixture.add_child(game)
	game.bat_dau([root.get_node("NetManager").local_id()], 42)
	game.set_process(false)
	await process_frame
	var stage_mask: int = game.LOP_SAN
	var isolated: bool = (sun.light_cull_mask & stage_mask) == 0 and (omni.light_cull_mask & stage_mask) == 0
	var own_stage: bool = mesh.layers == stage_mask and game._cam_san().cull_mask == stage_mask
	own_stage = own_stage and game._den[0].get_node("Bong").layers == stage_mask
	var solo_runs: bool = not game.ket_thuc_khi_con_mot
	var initial_two := _visible_lights(game) == 2
	game._ve_nhip(8.0)
	var blackout: bool = game._troi.light_energy == 0.0 and game._env.ambient_light_energy == 0.0
	var markers_off: bool = game._vien.transparency == 1.0 and not game._dau_toi.visible
	game._ve_nhip(game.CHU_KY + 1.0)
	var relit: bool = game._troi.light_energy > 0.0 and game._env.ambient_light_energy > 0.0
	var next_three := _visible_lights(game) == 3
	var self_visible: bool = game._dau_toi.visible
	# Vùng quét vừa cập nhật phải gây cháy ngay, không chờ Area3D sang nhịp physics sau.
	game._bat_dau_luc = Time.get_ticks_msec() / 1000.0 - 8.0
	game._thanh.mau = 100.0
	game._ve_nhip(8.0)
	player.global_position = game.san.to_global(game._den[0].position + Vector3.UP * 0.2)
	game._luat_moi_nhip()
	var immediate_hit: bool = game._thanh.mau < 100.0
	game._bat_dau_luc = Time.get_ticks_msec() / 1000.0
	game._thanh.mau = 100.0
	game._luat_moi_nhip()
	var safe_start: bool = game._thanh.mau == 100.0
	game.dung_som()
	var restored: bool = sun.light_cull_mask == 1048575 and omni.light_cull_mask == 1048575
	restored = restored and hidden.light_cull_mask == 1048575 and not hidden.visible
	restored = restored and mesh.layers == original_layer and sun.light_energy == 3.0
	print(JSON.stringify({"foreign_lights_isolated": isolated, "stage_layers": own_stage,
		"solo_runs_full_cycle": solo_runs, "initial_two": initial_two, "darkness_zero": blackout,
		"markers_off": markers_off, "relit": relit, "next_three": next_three,
		"self_marker": self_visible, "immediate_hit": immediate_hit, "safe_start": safe_start,
		"room_restored": restored}))
	fixture.queue_free()
	await process_frame
	return isolated and own_stage and solo_runs and initial_two and blackout and markers_off and relit and next_three and self_visible and immediate_hit and safe_start and restored

func _visible_lights(game: Node) -> int:
	var count := 0
	for light: Node3D in game._den:
		if light.visible:
			count += 1
	return count
