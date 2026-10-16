extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var themes: Script = load("res://minigame/chung/theme_backdrop.gd")
	var base: Script = load("res://minigame/chung/mini_game_3d.gd")
	for key: String in themes.THEMES:
		var backdrop: Node3D = themes.SCENE.instantiate()
		themes.configure(backdrop, key)
		check(backdrop.find_children("*", "CollisionObject3D", true, false).is_empty(), key + ": scenery must not block players or catch a fall")
		check(not backdrop.has_node("Decorations"), key + ": replace detached prop rows with illustrated walls")
		check(backdrop.get_node("Wrap").get_child_count() == 5, key + ": four walls and a ceiling close the shell")
		for name: String in ["BackWall", "LeftWall", "RightWall", "FrontWall"]:
			var wall: MeshInstance3D = backdrop.get_node("Wrap/" + name)
			check(wall.material_override.get_shader_parameter("wallpaper") is Texture2D and wall.mesh is PlaneMesh, key + ": continuous illustrated wall")
		var ground: MeshInstance3D = backdrop.get_node("HorizonGround")
		check(ground.position.y < -base.ROI_KHOI_SAN, key + ": scenic ground remains below elimination threshold")
		if key == "spotlights":
			var material: ShaderMaterial = backdrop.get_node("Wrap/BackWall").material_override
			check(material.get_shader_parameter("receive_lighting") == true, "Theatre scenery must obey blackout")
		if key == "lo_da":
			check(backdrop.get_node("Wrap/Ceiling").position.y > 40, "Mountain enclosure covers the uphill camera")
		backdrop.free()
	var first: Node3D = themes.SCENE.instantiate()
	var second: Node3D = themes.SCENE.instantiate()
	themes.configure(first, "paint")
	themes.configure(second, "minefield")
	check(first.get_node("Wrap/BackWall").material_override != second.get_node("Wrap/BackWall").material_override, "A later game cannot overwrite another arena's palette")
	first.free()
	second.free()
	print("THEME BACKDROP: %d configurations, %d failures" % [themes.THEMES.size(), failures])
	quit(1 if failures else 0)
