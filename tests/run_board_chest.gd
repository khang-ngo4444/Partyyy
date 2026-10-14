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
	var board: Node3D = load("res://board/ban_party.tscn").instantiate()
	fixture.add_child(board)
	var chest: Node3D = board.get_node("RuongBau")
	for tile_index: int in [2, 8, 40, 53]:
		board.dat_ruong(-1)
		board.dat_ruong(tile_index)
		var tile: Node3D = board._o[tile_index]
		check(chest.visible and chest.global_position.distance_to(tile.global_position + Vector3.UP * 0.2) < 0.01, "Chests follow the active chest tile")
		check(chest.global_basis.is_equal_approx(tile.global_basis * Basis(Vector3.UP, PI * 0.5)), "Chest pair follows tile orientation on the ring and shortcuts")
		check(chest.get_node("Than/Left").position.x < -1.2 and chest.get_node("Than/Right").position.x > 1.2, "Both chests keep the tile center clear")
	var tile: Node3D = board._o[8]
	board.dat_ruong(-1)
	board.dat_ruong(8)
	tile.hien_trang_thai(4, "", "", true, PackedStringArray(), PackedStringArray())
	var player: Node3D = load("res://player/player.tscn").instantiate()
	player.set_script(load("res://tests/fixtures/spot_player.gd"))
	fixture.add_child(player)
	player.global_position = tile.global_position + Vector3.UP * 0.2
	var camera: Camera3D = board.camera_ban
	camera.global_position = tile.global_position + tile.global_basis * Vector3(7, 6, 8)
	camera.look_at(tile.global_position + Vector3.UP * 0.5)
	camera.make_current()
	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/runtime/board_chest.png")
	board.dat_ruong(9)
	var move: Tween = chest._move
	board.dat_ruong(9)
	check(chest._move == move, "Repeated snapshots do not restart chest relocation")
	await create_timer(0.9).timeout
	check(chest.global_position.distance_to(board.vi_tri(9) + Vector3.UP * 0.2) < 0.01, "Relocated chest pair reaches the new tile")
	board.dat_ruong(-1)
	check(not chest.visible, "Clearing the chest tile hides both models")
	fixture.free()
	print("BOARD CHEST: %d failures" % failures)
	quit(0 if failures == 0 else 1)
