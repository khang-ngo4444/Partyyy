extends SceneTree
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var id: int = root.get_node("NetManager").local_id()
	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.set_script(load("res://tests/fixtures/spot_player.gd"))
	player.test_id = id
	fixture.add_child(player)
	var game: Node = load("res://minigame/laser_leap/laser_leap.tscn").instantiate()
	fixture.add_child(game)
	game.bat_dau([id], 42)
	game.set_process(false)
	game.set_physics_process(false)
	player.global_position = game.san.to_global(Vector3(0, 0.2, 0))
	check(game.san.get_node("Floor").mesh.size == Vector3(24, 0.4, 24), "Authored arena is square")
	check(game._beams.size() == 1 and game.allows_jump(), "One sweep with jumping enabled")
	check(player.so_lan_nhay > 0 and game.giay_van == 60, "Laser match permits jumping and lasts at most one minute")
	var beam: Node3D = game._beams[0]
	for axis: int in [0, 1]:
		beam.deactivate()
		beam.present(axis, 0, false)
		check(not beam.hits(player), "Warning cannot eliminate a player")
		beam.present(axis, -2, true)
		beam.present(axis, 2, true)
		check(beam.hits(player), "Translated sweep cannot skip a player between frames")
		beam.deactivate()
		beam.present(axis, 10, true)
		check(not beam.hits(player), "Player away from beam remains safe")
	var original := player.global_position
	player.global_position = game.san.to_global(Vector3(10.5, 2, 10.5))
	await physics_frame
	await physics_frame
	player.move_and_collide(Vector3(0, -3, 0))
	check(player.global_position.y > game.san.global_position.y, "Square corners have floor collision")
	player.global_position = original
	if OS.get_cmdline_user_args().has("--capture"):
		beam.deactivate()
		beam.present(0, 2, true)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/runtime/laser_sweep.png")
	game.dung_som()
	fixture.free()
	print("LASER SWEEP: %d failures" % failures)
	quit(0 if failures == 0 else 1)
