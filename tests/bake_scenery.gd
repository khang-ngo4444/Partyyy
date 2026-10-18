extends SceneTree

## Render existing licensed models in the MCP-authored bake scene. No editor control.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(2048, 512)
	root.content_scale_size = Vector2i(2048, 512)
	var stage: Node3D = load("res://minigame/chung/scenery_bake.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	var groups := ["Forest", "Rocks", "Castle", "Palms", "Workshop"]
	DirAccess.make_dir_recursive_absolute("res://minigame/chung/scenery")
	for theme: String in groups:
		for name: String in groups:
			stage.get_node(name).visible = name == theme
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		if rendered.save_png("res://minigame/chung/scenery/" + theme.to_lower() + ".png") != OK:
			push_error("Could not bake " + theme)
			quit(1)
			return
		print("BAKED ", theme, " ", rendered.get_size())
	stage.free()
	quit()
