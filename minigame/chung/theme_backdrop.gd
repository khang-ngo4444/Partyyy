extends RefCounted

## Continuous illustrated enclosure around each arena, built from the authored prefab.
## Decorative walls have no collision and never provide a safe landing surface.
const SCENE = preload("res://minigame/chung/theme_backdrop.tscn")
const ENVIRONMENT = preload("res://minigame/chung/theme_environment.tres")
const WALL_MATERIAL = preload("res://minigame/chung/wallpaper.tres")
const ARTWORK_HEIGHT := {"Forest": 14.0, "Rocks": 52.0, "Castle": 12.0, "Palms": 24.0, "Workshop": 12.0}
const ARENA_MARGIN := 1.4
const LASER_MARGIN := 5.0
const SCENERY_BOTTOM := -16.0
const ROOM_TOP := 36.0
const MOUNTAIN_TOP := 56.0
const CAMERA_CLEARANCE := 24.0

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
	"minefield": [Vector2(10, 38), Vector2(0, -14), "Forest", "#c5e8f0", "#a7d8c4", "#83b69f"],
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
	configure(backdrop, key, camera)
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


const WALLPAPERS := {
	"Forest": preload("res://minigame/chung/scenery/forest.png"),
	"Rocks": preload("res://minigame/chung/scenery/rocks.png"),
	"Castle": preload("res://minigame/chung/scenery/castle.png"),
	"Palms": preload("res://minigame/chung/scenery/palms.png"),
	"Workshop": preload("res://minigame/chung/scenery/workshop.png"),
}


static func configure(backdrop: Node3D, key: String, camera: Camera3D = null) -> void:
	var theme: Array = THEMES[key]
	var footprint: Vector2 = theme[0]
	var center: Vector2 = theme[1]
	var margin := LASER_MARGIN if key == "laser_leap" else ARENA_MARGIN
	var half := footprint * 0.5 + Vector2.ONE * margin
	if camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		# Parallel rays can start outside narrow side walls in a wide viewport.
		var aspect := camera.get_viewport().get_visible_rect().size.aspect()
		var view_width := camera.size * aspect if camera.keep_aspect == Camera3D.KEEP_HEIGHT else camera.size
		half.x = maxf(half.x, view_width * 0.5 + margin)
	var bottom := SCENERY_BOTTOM
	var top := MOUNTAIN_TOP if key == "lo_da" else ROOM_TOP
	var front := half.y + CAMERA_CLEARANCE # Keep the arena camera inside the illustrated shell.
	var height := top - bottom
	var middle_y := (top + bottom) * 0.5
	var depth := front + half.y
	var middle_z := center.y + (front - half.y) * 0.5
	var walls := [
		["BackWall", Vector3(center.x, middle_y, center.y - half.y), 0.0, half.x * 2],
		["LeftWall", Vector3(center.x - half.x, middle_y, middle_z), PI * 0.5, depth],
		["RightWall", Vector3(center.x + half.x, middle_y, middle_z), -PI * 0.5, depth],
		["FrontWall", Vector3(center.x, middle_y, center.y + front), PI, half.x * 2],
	]
	for specification: Array in walls:
		var wall: MeshInstance3D = backdrop.get_node("Wrap/" + str(specification[0]))
		wall.position = specification[1]
		wall.rotation = Vector3(0, float(specification[2]), 0)
		wall.scale = Vector3(float(specification[3]), height, 1)
		var material := WALL_MATERIAL.duplicate() as ShaderMaterial
		material.set_shader_parameter("wallpaper", WALLPAPERS[str(theme[2])])
		material.set_shader_parameter("tint", Color(theme[4]).lerp(Color.WHITE, 0.75))
		material.set_shader_parameter("wall_size", Vector2(float(specification[3]), height))
		material.set_shader_parameter("wall_top", top)
		material.set_shader_parameter("artwork_height", ARTWORK_HEIGHT[str(theme[2])])
		material.set_shader_parameter("receive_lighting", key == "spotlights")
		wall.material_override = material
	var ceiling: MeshInstance3D = backdrop.get_node("Wrap/Ceiling")
	ceiling.position = Vector3(center.x, top, middle_z)
	ceiling.rotation = Vector3(PI, 0, 0)
	ceiling.scale = Vector3(half.x * 2, 1, depth)
	_tint(ceiling, Color(theme[3]))
	var ceiling_material := ceiling.material_override as StandardMaterial3D
	ceiling_material.albedo_texture = null
	ceiling_material.cull_mode = BaseMaterial3D.CULL_BACK
	ceiling_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if key == "spotlights" else BaseMaterial3D.SHADING_MODE_UNSHADED
	var ground: MeshInstance3D = backdrop.get_node("HorizonGround")
	ground.position = Vector3(center.x, bottom, middle_z)
	ground.scale = Vector3(half.x * 2, 0.2, depth)
	_tint(ground, Color(theme[5]))
	# This is only scenery. Falling still eliminates players above this surface.
	ground.visible = true
	if key == "spotlights":
		(ground.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL


static func _tint(mesh: MeshInstance3D, color: Color) -> void:
	var material := mesh.material_override.duplicate() as StandardMaterial3D
	material.albedo_color = color
	mesh.material_override = material
