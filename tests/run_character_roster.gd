extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var creator_script: Script = load("res://ui/character_creator.gd")
	if DisplayServer.get_name() == "headless":
		creator_script._anh.resize(10)
	var creator: Control = load("res://ui/character_creator.tscn").instantiate()
	root.add_child(creator)
	current_scene = creator
	var player: Node = load("res://player/player.tscn").instantiate()
	check(creator.models.size() == 10, "Ten playable free model variants")
	check(creator.models.size() == player.models.size(), "Menu and player have the same roster")
	check(creator.models.size() == CharacterVisual.ARCHETYPE_NAMES.size(), "Every model has a label")
	for index in creator.models.size():
		check(creator.models[index].resource_path == player.models[index].resource_path, "Model order matches replication")
	creator.open()
	await create_timer(0.3).timeout
	check(creator.class_grid.get_child_count() == 10 and creator.class_grid.columns == 5, "Two rows of five choices")
	creator._select_model(9)
	check(creator.archetype_name.text == "ĐẠO TẶC XƯƠNG", "Last model can be selected")
	var event := InputEventKey.new()
	event.keycode = KEY_0
	event.pressed = true
	creator._select_model(0)
	creator._input(event)
	check(creator._model_index == 9, "Zero hotkey selects model ten")
	await create_timer(0.2).timeout
	check(creator.confirm_btn.get_global_rect().end.y <= 720, "Choices must not push confirm off screen at 720p")
	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/runtime/character_roster.png")
	player.free()
	creator.close()
	creator.queue_free()
	await process_frame
	print("CHARACTER ROSTER: %d failures" % failures)
	quit(1 if failures > 0 else 0)
