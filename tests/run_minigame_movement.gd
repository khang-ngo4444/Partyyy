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
	var player: Node = load("res://player/player.tscn").instantiate()
	player.set_script(load("res://tests/fixtures/spot_player.gd"))
	fixture.add_child(player)
	var controller: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	fixture.add_child(controller)
	var count := 0
	for scene: PackedScene in controller.tro_choi:
		var game: Node = scene.instantiate()
		if not game.has_method("_apply_jump_policy"):
			game.free()
			continue
		fixture.add_child(game)
		var code := scene.resource_path.get_file().get_basename()
		player.so_lan_nhay = 2
		game._apply_jump_policy(player)
		game._apply_jump_policy(player)
		check(player.so_lan_nhay == (2 if code == "breaking_blocks" else 0), code + ": only falling floor permits jumping")
		player.global_position = Vector3(0, 5, 0)
		player.velocity = Vector3.ZERO
		player._lan_nhay = 0
		player.khoa_di_chuyen = false
		await process_frame
		player.set_physics_process(true)
		Input.action_press("jump")
		await physics_frame
		await process_frame
		player.set_physics_process(false)
		Input.action_release("jump")
		check((player.velocity.y > 0) == (code == "breaking_blocks"), code + ": actual Space input follows the game policy")
		game._restore_jump_policy()
		check(player.so_lan_nhay == 2, code + ": original jump count restored on exit")
		game.free()
		count += 1
	check(count == 13, "All active 3D games checked")
	var avatar_script: Script = load("res://player/player.gd")
	check(player.collision_mask & int(avatar_script.LOP_NGUOI) == 0, "Current player mask excludes other players")
	fixture.free()
	print("MINIGAME MOVEMENT: %d games, %d failures" % [count, failures])
	quit(1 if failures > 0 else 0)
