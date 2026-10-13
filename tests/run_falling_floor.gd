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
	runner.run_suite(load("res://tests/test_falling_floor.gd").new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	await _runtime()
	print("FALLING FLOOR RUNTIME: %d failures" % failures)
	quit(1 if failures > 0 or int(results.get("failed", 0)) > 0 else 0)


func _runtime() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.set_script(load("res://tests/fixtures/spot_player.gd"))
	player.test_id = root.get_node("NetManager").local_id()
	fixture.add_child(player)
	var original_position: Vector3 = player.global_position
	var game: Node = load("res://minigame/breaking_blocks/breaking_blocks.tscn").instantiate()
	fixture.add_child(game)
	var ids: Array = [player.test_id, player.test_id + 1, player.test_id + 2]
	game.bat_dau(ids, 7)
	game.set_process(false)
	await physics_frame
	await physics_frame
	check(game._tiles.size() == 64 and game.giay_van <= 60.0, "Authored 64-tile floor and one minute cap")
	var tile_index: int = game._plan[0].tiles[0]
	var tile: Node3D = game._tiles[tile_index]
	game._present_floor(3.0)
	check(tile.get_node("Than").collision_layer == 1
		and tile.get_node("Mat").material_override == game._warning_material,
		"Warning stays collidable and changes the existing tile material")
	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/runtime/falling_floor_preview.png")
	game._present_floor(4.6)
	check(tile.position.y < 0.0 and tile.get_node("Than").collision_layer == 0,
		"Dropping visual disconnects collision immediately")
	player.global_position = game.san.global_position + game._centers[tile_index] + Vector3.UP
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	for frame: int in 100:
		await physics_frame
	check(game._toi_thua(), "Real Player falls below elimination threshold through missing tile")
	player.set_physics_process(false)
	game._net_chet(ids[0], 50.0)
	game._net_chet(ids[2], 0.1)
	game._net_chet(ids[0], 0.01)
	check(game._thu_tu_chet == [ids[0], ids[2]], "Actual RPC receiver preserves first reports and ignores duplicates")
	var rules: Script = load("res://minigame/breaking_blocks/falling_floor_rules.gd")
	check(rules.ranking(ids, game._song, game._thu_tu_chet) == [ids[1], ids[2], ids[0]],
		"Receiver order determines ranks despite reversed client timestamps")
	game._present_floor(7.4)
	check(is_zero_approx(tile.position.y) and tile.get_node("Than").collision_layer == 1,
		"Returned authored floor restores collision only at the surface")
	game._present_floor(58.4)
	var final_clear := true
	for floor_tile: Node in game._tiles:
		final_clear = final_clear and floor_tile.get_node("Than").collision_layer == 0
	check(final_clear, "Final drop disconnects the whole map")
	var emitted: Array = []
	game.xong.connect(func(ranks: Array) -> void: emitted.append(ranks))
	game._net_xep_hang(rules.ranking(ids, game._song, game._thu_tu_chet))
	await process_frame
	await process_frame
	check(emitted == [[ids[1], ids[2], ids[0]]], "Result receiver emits the actual receive-order ranking")
	game.dung_som()
	await process_frame
	check(player.global_position.distance_to(original_position) < 0.05
		and not player.che_do_san, "Cleanup returns player and movement mode")
	var solo: Node = load("res://minigame/breaking_blocks/breaking_blocks.tscn").instantiate()
	fixture.add_child(solo)
	solo.bat_dau([player.test_id], 7)
	await process_frame
	check(solo._chay and not solo.ket_thuc_khi_con_mot and solo.giay_con_lai() > 50.0,
		"Solo practice remains running after spawn and reaches the scheduled waves")
	solo.dung_som()
	fixture.queue_free()
	await process_frame
