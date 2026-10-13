extends RefCounted

## Sparse scenery around an arena. All visual nodes/resources are authored in the prefab.
## Decorative walls have no collision and never provide a safe landing surface.
const SCENE = preload("res://minigame/chung/theme_backdrop.tscn")
const ENVIRONMENT = preload("res://minigame/chung/theme_environment.tres")

const THEMES := {
	"breaking_blocks": [Vector2(24, 24), Vector2.ZERO, "Castle", "#ccd5f7", "#b19edb", "#7284b8"],
	"laser_leap": [Vector2(24, 24), Vector2.ZERO, "Castle", "#243b63", "#375580", "#172740"],
	"spotlights": [Vector2(24, 24), Vector2.ZERO, "Castle", "#10121e", "#15182c", "#10121e"],
	"explosive": [Vector2(24, 24), Vector2.ZERO, "Forest", "#b9e0ef", "#aecbce", "#7ca39a"],
	"magma": [Vector2(90, 90), Vector2.ZERO, "Rocks", "#b96c72", "#6c535d", "#322936"],
	"crown": [Vector2(24, 24), Vector2.ZERO, "Castle", "#e2d5f6", "#cbb3dc", "#aca4c6"],
	"word_wars": [Vector2(28, 28), Vector2.ZERO, "Workshop", "#d3eaf3", "#c3dfd7", "#93b7a9"],
	"dem_thu": [Vector2(48, 60), Vector2(0, 8), "Forest", "#b9e0ef", "#a4cfb6", "#7aaa80"],
	"lo_da": [Vector2(14, 148), Vector2(0, -71), "Rocks", "#afcedf", "#7898a1", "#617c80"],
	"toy_factory": [Vector2(28, 28), Vector2.ZERO, "Workshop", "#d9e0f2", "#aabdd8", "#929fbc"],
	"wave_hide": [Vector2(100, 100), Vector2.ZERO, "Palms", "#abdef1", "#94cddd", "#609fae"],
	"minefield": [Vector2(16, 58), Vector2(0, -25), "Forest", "#c5e8f0", "#a7d8c4", "#83b69f"],
	"paint": [Vector2(28, 28), Vector2.ZERO, "Workshop", "#ebdff2", "#cab8dd", "#a49ab8"],
	"temporal_trails": [Vector2(24, 24), Vector2.ZERO, "Castle", "#a0d9e2", "#62969d", "#406d7d"],
}


static func key_for(game: Node) -> String:
	return game.get_script().resource_path.get_file().get_basename()


static func attach(arena: Node3D, game: Node, camera: Camera3D) -> Node3D:
	var key := key_for(game)
	if not THEMES.has(key):
		return null
	var backdrop := SCENE.instantiate() as Node3D
	arena.add_child(backdrop)
	configure(backdrop, key)
	# Spotlight owns its camera environment and switches every light on/off itself.
	if camera != null and key != "spotlights":
		var environment := ENVIRONMENT.duplicate(true) as Environment
		var sky_material := environment.sky.sky_material as ProceduralSkyMaterial
		sky_material.sky_top_color = Color(THEMES[key][3])
		sky_material.sky_horizon_color = Color(THEMES[key][3]).lightened(0.2)
		sky_material.ground_horizon_color = sky_material.sky_horizon_color
		sky_material.ground_bottom_color = Color(THEMES[key][5])
		camera.environment = environment
	return backdrop


static func configure(backdrop: Node3D, key: String) -> void:
	var theme: Array = THEMES[key]
	var footprint: Vector2 = theme[0]
	var center: Vector2 = theme[1]
	var half := footprint * 0.5 + Vector2(5, 5)
	var height := 12.0 if key != "lo_da" else 52.0
	var base := -3.0
	var wall_color := Color(theme[4])
	var back: MeshInstance3D = backdrop.get_node("Wrap/BackWall")
	var left: MeshInstance3D = backdrop.get_node("Wrap/LeftWall")
	var right: MeshInstance3D = backdrop.get_node("Wrap/RightWall")
	back.position = Vector3(center.x, base + height * 0.5, center.y - half.y)
	back.scale = Vector3(half.x * 2, height, 0.2)
	for pair: Array in [[left, -1.0], [right, 1.0]]:
		var wall: MeshInstance3D = pair[0]
		wall.position = Vector3(center.x + half.x * float(pair[1]), base + height * 0.5, center.y)
		wall.scale = Vector3(0.2, height, half.y * 2)
	for wall: MeshInstance3D in [back, left, right]:
		_tint(wall, wall_color)
		# Theatre walls receive light: no bright unshaded backdrop during blackout.
		if key == "spotlights":
			(wall.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var ground: MeshInstance3D = backdrop.get_node("HorizonGround")
	ground.position = Vector3(center.x, -15, center.y)
	ground.scale = Vector3(half.x * 2, 0.2, half.y * 2)
	_tint(ground, Color(theme[5]))
	ground.visible = key not in ["spotlights", "wave_hide", "magma"]
	for group: Node3D in backdrop.get_node("Decorations").get_children():
		group.visible = group.name == String(theme[2])
		if not group.visible:
			continue
		_arrange_props(group, footprint, center, key)
		if group.name == "Rocks":
			for mesh: MeshInstance3D in group.find_children("*", "MeshInstance3D", true, false):
				var source := mesh.get_active_material(0) as StandardMaterial3D
				if source != null:
					var rock_material := source.duplicate() as StandardMaterial3D
					rock_material.albedo_texture = null
					rock_material.albedo_color = wall_color.darkened(0.2)
					mesh.material_override = rock_material


static func _arrange_props(group: Node3D, footprint: Vector2, center: Vector2, key: String) -> void:
	# Lava and ocean surfaces extend beyond the playable island. Dress the island's
	# perimeter, not the far edge of those large background planes.
	if key in ["magma", "wave_hide"]:
		footprint = Vector2(28, 28)
	var side_x := footprint.x * 0.5 + 2.6
	var z_start := center.y - footprint.y * 0.5 + 3.0
	var z_end := center.y + footprint.y * 0.5 - 4.0
	if key == "wave_hide":
		side_x = 23.0
		z_start = -20
		z_end = 12
	for index in group.get_child_count():
		var prop := group.get_child(index) as Node3D
		var z := lerpf(z_start, z_end, float(index / 2) / 3.0)
		var y := maxf(-z, 0.0) * tan(0.20943951) if key == "lo_da" else -0.2
		prop.position = Vector3(side_x * (-1 if index % 2 == 0 else 1), y, z)
		var sizes := {"Forest": 5.0, "Rocks": 6.0, "Castle": 3.0, "Palms": 5.0, "Workshop": 3.0}
		var size: float = sizes[String(group.name)]
		prop.scale = Vector3.ONE * size
		prop.rotation.y = PI * 0.5 * float(index % 4)
		_keep_outside_playfield(prop, footprint.x * 0.5 + 1.0, index % 2 == 1)


## Imported meshes can have off-center pivots. Place the whole scaled mesh outside,
## rather than only its node origin, so scenery cannot cover a narrow route.
static func _keep_outside_playfield(prop: Node3D, boundary: float, on_right: bool) -> void:
	var minimum := INF
	var maximum := -INF
	for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
		var relative := Transform3D.IDENTITY
		var ancestor: Node3D = mesh
		while ancestor != prop:
			relative = ancestor.transform * relative
			ancestor = ancestor.get_parent() as Node3D
		var bounds: AABB = (prop.transform * relative) * mesh.get_aabb()
		minimum = minf(minimum, bounds.position.x)
		maximum = maxf(maximum, bounds.end.x)
	if minimum == INF:
		return
	if on_right:
		prop.position.x += maxf(boundary - minimum, 0.0)
	else:
		prop.position.x -= maxf(maximum + boundary, 0.0)


static func _tint(mesh: MeshInstance3D, color: Color) -> void:
	var material := mesh.material_override.duplicate() as StandardMaterial3D
	material.albedo_color = color
	mesh.material_override = material
