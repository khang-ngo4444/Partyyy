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
		var active := 0
		for group: Node3D in backdrop.get_node("Decorations").get_children():
			if group.visible:
				active += 1
		check(active == 1, key + ": only the selected decoration set is drawn")
		var ground: MeshInstance3D = backdrop.get_node("HorizonGround")
		check(ground.position.y < -base.ROI_KHOI_SAN, key + ": scenic ground remains below elimination threshold")
		if key == "spotlights":
			var material: StandardMaterial3D = backdrop.get_node("Wrap/BackWall").material_override
			check(material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED, "Theatre scenery must obey blackout")
		if key == "lo_da":
			var last: Node3D = backdrop.get_node("Decorations/Rocks/Prop0")
			check(last.position.y > 25, "Mountain props follow the uphill arena elevation")
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
