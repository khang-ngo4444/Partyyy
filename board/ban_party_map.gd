@tool
extends Node3D
## Rumble Reef: quần đảo party cỡ lớn. Gameplay vẫn nằm ở các OBan thật trong ban_party.tscn.

const WATER_Y := -1.7
const GROUND_Y := 2.2
var _root: Node3D
var _m: Dictionary = {}
var _spinners: Array[Node3D] = []
var _bobbers: Array[Dictionary] = []
var _orbiters: Array[Dictionary] = []
var _drifters: Array[Dictionary] = []
var _beacon: Node3D
var _world_env: WorldEnvironment
var _previous_env: Environment
var _time := 0.0


func _ready() -> void:
	_build()
	set_process(true)


func _exit_tree() -> void:
	if _world_env != null and is_instance_valid(_world_env) and _previous_env != null:
		_world_env.environment = _previous_env


func _process(delta: float) -> void:
	_time += delta
	for n in _spinners:
		if is_instance_valid(n):
			n.rotation.y += delta * 0.34
	if _beacon != null and is_instance_valid(_beacon):
		_beacon.rotation.y += delta * 0.52
	for d in _bobbers:
		var n: Node3D = d.node
		if is_instance_valid(n):
			n.position.y = float(d.y) + sin(_time * float(d.speed) + float(d.phase)) * float(d.amount)
			n.rotation.z = sin(_time * 0.65 + float(d.phase)) * 0.04
	for d in _orbiters:
		var n: Node3D = d.node
		if is_instance_valid(n):
			var a := float(d.phase) + _time * float(d.speed)
			n.position = Vector3(cos(a) * float(d.radius), float(d.y) + sin(a * 2.0) * 0.2,
					sin(a) * float(d.radius))
			n.rotation.y = -a + PI * 0.5
	for d in _drifters:
		var n: Node3D = d.node
		if is_instance_valid(n):
			n.position.x += delta * float(d.speed)
			if n.position.x > 125.0:
				n.position.x = -125.0


func _build() -> void:
	if get_node_or_null("_GeneratedArchipelago") != null:
		return
	_root = Node3D.new()
	_root.name = "_GeneratedArchipelago"
	add_child(_root)
	_make_materials()
	_environment()
	_ocean()
	_terrain()
	_boardwalk()
	_lighthouse()
	_harbor()
	_temple()
	_volcano()
	_carnival()
	_props()
	_distant_world()
	_lighting()
	if Engine.is_editor_hint() or get_tree().current_scene == get_parent():
		_preview_camera(not Engine.is_editor_hint())


func _make_materials() -> void:
	_m.cliff = _tex_mat("Cliff", "res://asset/generated/rumble_reef/cliff_albedo.png",
			Color("#8796a4"), 0.9, 0.07)
	_m.grass = _tex_mat("Grass", "res://asset/generated/rumble_reef/grass_albedo.png",
			Color("#75b45e"), 0.88, 0.095)
	_m.sand = _tex_mat("Sand", "res://asset/generated/rumble_reef/sand_albedo.png",
			Color("#efc57a"), 0.84, 0.11)
	_m.rock = _mat("Deep rock", Color("#172737"), 0.93)
	_m.rock_hi = _mat("Rock edge", Color("#506a78"), 0.86)
	_m.wood = _mat("Wood", Color("#75412e"), 0.86)
	_m.wood_hi = _mat("Sunlit wood", Color("#bf7040"), 0.76)
	_m.wood_dark = _mat("Wet timber", Color("#2d2026"), 0.92)
	_m.gold = _mat("Brass", Color("#ffc14c"), 0.3, 0.66)
	_m.iron = _mat("Iron", Color("#17222f"), 0.42, 0.58)
	_m.cream = _mat("Canvas", Color("#ffe5ad"), 0.82)
	_m.red = _mat("Coral red", Color("#ed4b59"), 0.66)
	_m.purple = _mat("Mystic violet", Color("#884ee2"), 0.48, 0.08, Color("#5b2aad"), 0.55)
	_m.cyan = _mat("Arcane cyan", Color("#2ddbd4"), 0.2, 0.10, Color("#14aaa6"), 1.7)
	_m.orange = _mat("Lava", Color("#ff6a24"), 0.34, 0.05, Color("#ff350d"), 2.4)
	_m.leaf = _mat("Palm leaf", Color("#277558"), 0.9)
	_m.leaf_hi = _mat("Palm highlight", Color("#63b95f"), 0.86)
	_m.stone = _mat("Ancient limestone", Color("#c9c2a0"), 0.9)
	_m.glass = _mat("Beacon glass", Color(0.35, 0.92, 0.96, 0.40), 0.12, 0.0,
			Color("#55e8e5"), 0.95)
	_m.cloud = _mat("Cloud", Color(0.94, 0.98, 1.0, 0.8), 0.92)
	_m.foam = _mat("Sea foam", Color("#b8fff1"), 0.22, 0.0, Color("#63d9d2"), 0.4)


func _mat(label: String, color: Color, roughness: float, metallic := 0.0,
		emission := Color(0, 0, 0, 1), energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.resource_name = label
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if color.a < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = energy
	return mat


func _tex_mat(label: String, path: String, tint: Color, roughness: float,
		uv_scale: float) -> StandardMaterial3D:
	var mat := _mat(label, tint, roughness)
	var tex := load(path) as Texture2D
	if tex != null:
		mat.albedo_texture = tex
		mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
	return mat


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#10264d")
	sm.sky_horizon_color = Color("#70c6d1")
	sm.ground_horizon_color = Color("#5aa2a6")
	sm.ground_bottom_color = Color("#09233b")
	sm.sun_angle_max = 18.0
	sm.sun_curve = 0.08
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color("#b5def0")
	env.ambient_light_energy = 0.72
	env.ambient_light_sky_contribution = 0.78
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color("#79bac4")
	env.fog_light_energy = 0.72
	env.fog_density = 0.0038
	env.fog_sky_affect = 0.55
	env.fog_height = -2.0
	env.fog_height_density = 0.035
	var existing := _find_env(get_tree().current_scene)
	if existing != null:
		_world_env = existing
		_previous_env = existing.environment
		existing.environment = env
	else:
		_world_env = WorldEnvironment.new()
		_world_env.name = "RumbleReefEnvironment"
		_world_env.environment = env
		_root.add_child(_world_env)


func _find_env(n: Node) -> WorldEnvironment:
	if n == null:
		return null
	if n is WorldEnvironment:
		return n as WorldEnvironment
	for c in n.get_children():
		var found := _find_env(c)
		if found != null:
			return found
	return null


func _ocean() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(650, 650)
	mesh.subdivide_width = 180
	mesh.subdivide_depth = 180
	var ocean := MeshInstance3D.new()
	ocean.name = "InfiniteAnimatedOcean"
	ocean.mesh = mesh
	ocean.position.y = WATER_Y
	var water := ShaderMaterial.new()
	water.shader = load("res://materials/rumble_reef_ocean.gdshader") as Shader
	ocean.material_override = water
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(ocean)


func _terrain() -> void:
	var lobes := [
		[Vector3(-9, -0.2, -1), 14.5, Vector3(1.20, 1, 0.78)],
		[Vector3(8, 0.0, 1), 13.8, Vector3(1.08, 1, 0.82)],
		[Vector3(0, -0.1, -8), 12.2, Vector3(1.18, 1, 0.72)],
		[Vector3(-1, 0.2, 9), 11.4, Vector3(1.32, 1, 0.70)]
	]
	for i in lobes.size():
		var d: Array = lobes[i]
		_cylinder("CliffMass_%d" % i, d[0], float(d[1]), 4.6, _m.cliff, 28, d[2])
		_cylinder("Shelf_%d" % i, (d[0] as Vector3) + Vector3.UP * 2.05,
				float(d[1]) * 0.965, 0.62, _m.rock_hi, 28, d[2])
		_cylinder("Grass_%d" % i, (d[0] as Vector3) + Vector3.UP * 2.42,
				float(d[1]) * 0.91, 0.32, _m.grass, 28, d[2])
	_cylinder("SouthBeach", Vector3(0, GROUND_Y + 0.35, -8.3), 10.4, 0.24, _m.sand, 26,
			Vector3(1.35, 1, 0.63))
	_cylinder("HarborBeach", Vector3(-11.3, GROUND_Y + 0.34, -1.3), 7.0, 0.22, _m.sand, 22,
			Vector3(1.0, 1, 0.72))
	_cylinder("JunglePlateau", Vector3(-1.2, GROUND_Y + 0.65, 7.0), 8.2, 0.85, _m.grass, 24,
			Vector3(1.28, 1, 0.72))
	_cylinder("VolcanoPlateau", Vector3(10, GROUND_Y + 0.52, 1.6), 7.2, 0.64, _m.rock, 22,
			Vector3(1.05, 1, 0.82))
	for i in 30:
		var a := TAU * i / 30.0
		var r := 22.5 + sin(a * 5.0) * 2.2
		_sphere("ShoreRock_%02d" % i,
				Vector3(cos(a) * r, 0.25 + (i % 4) * 0.16, sin(a) * r * 0.72),
				1.2 + (i % 3) * 0.28, _m.cliff,
				Vector3(1.0 + (i % 2) * 0.4, 0.75 + (i % 3) * 0.17, 0.85))


func _boardwalk() -> void:
	var spaces: Array[Node3D] = []
	for child in get_parent().get_children():
		if child is OBan:
			spaces.append(child)
	spaces.sort_custom(func(a: OBan, b: OBan) -> bool: return a.so < b.so)
	# Mỗi ô có chân đế riêng: mặt ô không còn lơ lửng hoặc chìm theo các lớp terrain.
	for space in spaces:
		_cylinder("TilePedestal_%02d" % (space as OBan).so,
				Vector3(space.position.x, space.position.y - 0.53, space.position.z),
				0.94, 0.86, _m.iron, 8)
	for i in spaces.size():
		var a := spaces[i].position
		var b := spaces[(i + 1) % spaces.size()].position
		var delta := Vector3(b.x - a.x, 0, b.z - a.z)
		var length := maxf(delta.length() - 1.75, 0.5)
		var center := (a + b) * 0.5
		center.y = (a.y + b.y) * 0.5 - 0.17
		var yaw := atan2(delta.x, delta.z)
		_box("Boardwalk_%02d" % i, center, Vector3(1.36, 0.23, length), _m.wood, yaw)
		var side := Vector3(cos(yaw), 0, -sin(yaw))
		for s in [-1.0, 1.0]:
			_box("Trim", center + side * 0.61 * s + Vector3.UP * 0.14,
					Vector3(0.09, 0.16, length), _m.gold, yaw)
		for p in 4:
			var pos := a.lerp(b, (float(p) + 0.5) / 4.0)
			pos.y = center.y + 0.17
			_box("Plank", pos, Vector3(1.44, 0.045, 0.065), _m.wood_hi, yaw)


func _lighthouse() -> void:
	var g := _group("GrandLighthouse", Vector3(-1.5, GROUND_Y + 0.48, 0.8))
	_cone_to(g, "Tower", Vector3(0, 4.5, 0), 2.35, 1.58, 8.8, _m.cream, 20)
	for y in [1.1, 3.2, 5.3, 7.35]:
		_cylinder_to(g, "RedBand", Vector3(0, y, 0), 2.15 - y * 0.065, 0.66, _m.red, 20)
	_cylinder_to(g, "LanternDeck", Vector3(0, 9, 0), 2.05, 0.30, _m.iron, 20)
	_torus_to(g, "DeckRail", Vector3(0, 9.35, 0), 1.72, 2.0, _m.gold, 32, 8)
	_cylinder_to(g, "Glass", Vector3(0, 10, 0), 1.43, 1.55, _m.glass, 20)
	_cone_to(g, "Roof", Vector3(0, 11.25, 0), 1.86, 0, 1.28, _m.red, 20)
	_beacon = _group_to(g, "RotatingBeacon", Vector3(0, 10.05, 0))
	for s in [-1.0, 1.0]:
		var beam := SpotLight3D.new()
		beam.rotation_degrees = Vector3(-5, -90 if s > 0 else 90, 0)
		beam.light_color = Color("#a9fff1")
		beam.light_energy = 7.5
		beam.spot_range = 52.0
		beam.spot_angle = 12.0
		_beacon.add_child(beam)


func _harbor() -> void:
	for i in 6:
		_box("Dock_%d" % i, Vector3(-13 - i * 1.45, GROUND_Y + 0.55, -3),
				Vector3(1.3, 0.22, 4.2), _m.wood, deg_to_rad(90))
	_build_ship(Vector3(-20, WATER_Y + 0.85, -6.2), 1.35, true)
	for i in 6:
		_cylinder("Barrel_%d" % i, Vector3(-11 + (i % 3) * 0.8, GROUND_Y + 0.75,
				-3 + floorf(float(i) / 3.0) * 0.8), 0.38, 0.82, _m.wood, 12)
	_cylinder("CranePost", Vector3(-12, GROUND_Y + 2.6, 0.2), 0.24, 4.8, _m.wood_dark, 10)
	_box("CraneArm", Vector3(-13.4, GROUND_Y + 4.75, 0.2), Vector3(3.3, 0.25, 0.3),
			_m.wood_hi, 0, Vector3.ONE, deg_to_rad(-8))
	_cylinder("CraneRope", Vector3(-14.7, GROUND_Y + 3.25, 0.2), 0.035, 2.8, _m.iron, 6)
	_box("CraneCargo", Vector3(-14.7, GROUND_Y + 1.8, 0.2), Vector3(1, 0.85, 1), _m.wood)


func _temple() -> void:
	var c := Vector3(-2, GROUND_Y + 1.5, 7)
	for r in 2:
		_cylinder("TempleStep_%d" % r, c + Vector3.UP * r * 0.36, 4.5 - r * 0.7,
				0.46, _m.stone, 12, Vector3(1.25, 1, 0.78))
	for i in 8:
		var a := TAU * i / 8.0
		var p := c + Vector3(cos(a) * 3.1, 2.2, sin(a) * 2.25)
		_cylinder("Column_%d" % i, p, 0.36, 3.4, _m.stone, 10)
		_cylinder("Capital_%d" % i, p + Vector3.UP * 1.78, 0.52, 0.26, _m.gold, 10)
	_cone("TempleCrystal", c + Vector3.UP * 4.4, 1.0, 0.05, 2.8, _m.purple, 6)
	for d in [[Vector3(-7, GROUND_Y + 0.45, 8.7), 1.3],
			[Vector3(3.6, GROUND_Y + 0.5, 10), 1.1],
			[Vector3(-5.1, GROUND_Y + 0.45, 11.2), 0.92]]:
		_palm("TemplePalm", d[0], float(d[1]))


func _volcano() -> void:
	var c := Vector3(10.4, GROUND_Y + 0.85, 1.2)
	for i in 4:
		_cone("Volcano_%d" % i, c + Vector3.UP * i * 0.72, 5.4 - i * 0.85,
				4.0 - i * 0.80, 1.5, _m.rock, 14, Vector3(1.15, 1, 0.90))
	_torus("Crater", c + Vector3.UP * 3.15, 1.2, 2.1, _m.orange, 28, 10)
	_cylinder("LavaPool", c + Vector3.UP * 3.05, 1.34, 0.12, _m.orange, 28)
	for i in 7:
		var a := TAU * i / 7.0
		_cone("Spike_%d" % i, c + Vector3(cos(a) * 4.5, 2.1, sin(a) * 3.5),
				0.35, 0, 2.0 + (i % 2), _m.rock, 7)


func _carnival() -> void:
	var fair := Vector3(4.2, GROUND_Y + 0.62, -7.5)
	_cylinder("TentBody", fair + Vector3.UP * 1.5, 2.8, 2.8, _m.cream, 18,
			Vector3(1, 1, 0.82))
	_cone("TentRoof", fair + Vector3.UP * 3.8, 3.5, 0, 2.6, _m.red, 18,
			Vector3(1, 1, 0.82))
	_cylinder("TentMast", fair + Vector3.UP * 5.7, 0.1, 2.2, _m.gold, 10)
	var anchor := _group("FerrisAnchor", Vector3(9, GROUND_Y + 4.9, -7))
	anchor.rotation.x = deg_to_rad(90)
	var wheel := _group_to(anchor, "FerrisWheel", Vector3.ZERO)
	_torus_to(wheel, "WheelRim", Vector3.ZERO, 4.1, 4.42, _m.gold, 48, 10)
	for i in 10:
		var a := TAU * i / 10.0
		var p := Vector3(cos(a) * 4.22, 0, sin(a) * 4.22)
		_box_to(wheel, "Spoke", p * 0.5, Vector3(0.12, 0.10, 4.22), _m.iron, -a)
		_box_to(wheel, "Gondola", p, Vector3(0.72, 0.65, 0.82),
				_m.red if i % 2 == 0 else _m.cyan, -a)
	_spinners.append(wheel)
	for x in [7.0, 11.0]:
		_box("WheelSupport", Vector3(x, GROUND_Y + 2.25, -7), Vector3(0.32, 5.2, 0.38),
				_m.iron, 0, Vector3.ONE, deg_to_rad(-14 if x < 9 else 14))


func _props() -> void:
	var chest := Vector3(-12, GROUND_Y + 0.92, 5.1)
	_box("LandmarkChest", chest, Vector3(2.2, 1.15, 1.35), _m.wood)
	_cylinder("ChestLid", chest + Vector3.UP * 0.70, 0.68, 2.2, _m.wood_hi, 16,
			Vector3.ONE, deg_to_rad(90))
	for i in 3:
		var p := Vector3(-7 + i * 2.7, GROUND_Y + 0.65, -7 + (i % 2) * 0.55)
		_box("Market_%d" % i, p, Vector3(2.1, 0.88, 1.15), _m.wood)
		_box("Canopy_%d" % i, p + Vector3.UP * 2.65, Vector3(2.5, 0.18, 1.65),
				_m.red if i % 2 == 0 else _m.purple)
	for i in 8:
		var p := Vector3(9.6 + (i % 4) * 0.72, GROUND_Y + 0.9,
				4.6 + floorf(float(i) / 4.0) * 1.05 + (i % 2) * 0.18)
		_box("Grave_%d" % i, p, Vector3(0.55, 1.1 + (i % 3) * 0.2, 0.24),
				_m.stone, deg_to_rad(-12 + i * 4), Vector3.ONE, deg_to_rad(-6))
	for d in [[Vector3(-10.8, GROUND_Y + 0.4, 6.8), 1.35],
			[Vector3(-7, GROUND_Y + 0.4, 8.8), 1.0],
			[Vector3(11.5, GROUND_Y + 0.45, -3.8), 1.25],
			[Vector3(-11.5, GROUND_Y + 0.42, -5.2), 1.15],
			[Vector3(1, GROUND_Y + 0.38, -11), 0.95],
			[Vector3(11.8, GROUND_Y + 0.42, 6.2), 0.88]]:
		_palm("Palm", d[0], float(d[1]))


func _distant_world() -> void:
	var islands := [[Vector3(-48, WATER_Y + 0.8, -30), 7.5],
			[Vector3(52, WATER_Y + 0.7, -27), 6.8],
			[Vector3(-58, WATER_Y + 0.6, 18), 8.4],
			[Vector3(63, WATER_Y + 0.7, 24), 9.0],
			[Vector3(-25, WATER_Y + 0.5, 54), 6.5],
			[Vector3(28, WATER_Y + 0.65, 62), 8.0],
			[Vector3(-92, WATER_Y + 0.4, -5), 11.0],
			[Vector3(97, WATER_Y + 0.35, -2), 12.0]]
	for i in islands.size():
		var d: Array = islands[i]
		_island("FarIsland_%d" % i, d[0], float(d[1]), i % 2 == 0)
	for i in 4:
		var ship := _build_ship(Vector3.ZERO, 0.72 + i * 0.12, false)
		_orbiters.append({"node": ship, "radius": 39.0 + i * 8.0,
				"y": WATER_Y + 0.82, "speed": (0.03 + i * 0.006) * (-1 if i % 2 else 1),
				"phase": i * 1.67})
	for i in 9:
		var cloud := _cloud("Cloud_%d" % i,
				Vector3(-105 + i * 26, 28 + (i % 3) * 3, -92 + (i % 3) * 12),
				0.72 + (i % 3) * 0.12)
		_drifters.append({"node": cloud, "speed": 0.45 + (i % 3) * 0.13})
	for i in 7:
		var bird := _group("Seagull_%d" % i, Vector3.ZERO)
		_box_to(bird, "WingL", Vector3(-0.32, 0, 0), Vector3(0.7, 0.04, 0.18),
				_m.cream, deg_to_rad(18))
		_box_to(bird, "WingR", Vector3(0.32, 0, 0), Vector3(0.7, 0.04, 0.18),
				_m.cream, deg_to_rad(-18))
		_orbiters.append({"node": bird, "radius": 12.0 + i * 0.8,
				"y": 15.0 + (i % 3) * 1.2, "speed": 0.16 + i * 0.012, "phase": i * 0.82})


func _island(label: String, pos: Vector3, radius: float, tower: bool) -> void:
	_cylinder(label + "Cliff", pos, radius, 3.8, _m.cliff, 20, Vector3(1.3, 1, 0.72))
	_cylinder(label + "Grass", pos + Vector3.UP * 2, radius * 0.88, 0.38,
			_m.grass, 20, Vector3(1.3, 1, 0.72))
	for j in 3:
		var a := TAU * j / 3.0 + radius
		_palm(label + "Palm", pos + Vector3(cos(a) * radius * 0.45, 2.1,
				sin(a) * radius * 0.3), 0.65 + j * 0.09)
	if tower:
		_cylinder(label + "Tower", pos + Vector3(0, 4.25, 0), 0.8, 4.5, _m.stone, 10)
		_cone(label + "Roof", pos + Vector3(0, 6.85, 0), 1.15, 0, 1.2, _m.red, 10)


func _build_ship(pos: Vector3, s: float, bob: bool) -> Node3D:
	var ship := _group("SailingShip", pos)
	ship.scale = Vector3.ONE * s
	_sphere_to(ship, "Hull", Vector3(0, 0.35, 0), 1.25, _m.wood_dark, Vector3(1.8, 0.58, 0.72))
	_box_to(ship, "Deck", Vector3(0, 0.82, 0), Vector3(3.4, 0.22, 1.25), _m.wood)
	_cylinder_to(ship, "Mast", Vector3(0, 2.45, 0), 0.09, 3.8, _m.wood_hi, 8)
	_box_to(ship, "Sail", Vector3(0.05, 2.65, 0), Vector3(0.10, 2.35, 2.35), _m.cream,
			deg_to_rad(8))
	_box_to(ship, "Stripe", Vector3(0.11, 2.65, 0), Vector3(0.05, 0.36, 2.38), _m.red,
			deg_to_rad(8))
	if bob:
		_bobbers.append({"node": ship, "y": pos.y, "speed": 0.85, "phase": pos.x * 0.3, "amount": 0.22})
	return ship


func _cloud(label: String, pos: Vector3, s: float) -> Node3D:
	var cloud := _group(label, pos)
	cloud.scale = Vector3.ONE * s
	for i in 6:
		_sphere_to(cloud, "Puff_%d" % i,
				Vector3((i - 2.5) * 1.0, sin(i * 1.3) * 0.45, cos(i * 0.9) * 0.55),
				1.45 + (i % 3) * 0.32, _m.cloud, Vector3(1.2, 0.72, 0.9))
	return cloud


func _palm(label: String, base: Vector3, s: float) -> void:
	var h := 4.2 * s
	var trunk := _cylinder(label + "Trunk", base + Vector3.UP * h * 0.5, 0.23 * s, h,
			_m.wood_hi, 9, Vector3.ONE, deg_to_rad(-5))
	trunk.rotation.x = deg_to_rad(3)
	var crown := base + Vector3(0.26, h, 0)
	_sphere(label + "Crown", crown, 0.38 * s, _m.wood_dark)
	for i in 8:
		var a := TAU * i / 8.0
		var leaf := _box(label + "Leaf", crown + Vector3(cos(a), 0.02, sin(a)) * 0.92 * s,
				Vector3(0.38, 0.09, 2.35) * s, _m.leaf_hi if i % 2 == 0 else _m.leaf, -a)
		leaf.rotation.z = deg_to_rad(-12 - (i % 2) * 7)


func _lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-54, -32, 0)
	sun.light_color = Color("#ffe3b8")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	_root.add_child(sun)
	for d in [[Vector3(-13, 8, -2), Color("#ffb14d"), 3.0],
			[Vector3(12, 8, 2), Color("#ff542d"), 3.4],
			[Vector3(2, 9, -8), Color("#b957ff"), 2.6],
			[Vector3(-2, 12, 1), Color("#69fff1"), 2.8]]:
		var light := OmniLight3D.new()
		light.position = d[0]
		light.light_color = d[1]
		light.light_energy = d[2]
		light.omni_range = 18.0
		_root.add_child(light)


func _preview_camera(current: bool) -> void:
	var camera := Camera3D.new()
	camera.name = "ArchipelagoPreviewCamera"
	camera.current = current
	camera.position = Vector3(0, 43, 50)
	camera.fov = 52.0
	_root.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0, 3, 0), Vector3.UP)


func _group(label: String, pos: Vector3) -> Node3D:
	return _group_to(_root, label, pos)


func _group_to(parent: Node3D, label: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = label
	n.position = pos
	parent.add_child(n)
	return n


func _box(label: String, pos: Vector3, size: Vector3, mat: Material, yaw := 0.0,
		scale_value := Vector3.ONE, tilt := 0.0) -> MeshInstance3D:
	return _box_to(_root, label, pos, size, mat, yaw, scale_value, tilt)


func _box_to(parent: Node3D, label: String, pos: Vector3, size: Vector3, mat: Material,
		yaw := 0.0, scale_value := Vector3.ONE, tilt := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.rotation = Vector3(0, yaw, tilt)
	n.scale = scale_value
	parent.add_child(n)
	return n


func _cylinder(label: String, pos: Vector3, radius: float, height: float, mat: Material,
		segments := 16, scale_value := Vector3.ONE, tilt := 0.0) -> MeshInstance3D:
	return _cylinder_to(_root, label, pos, radius, height, mat, segments, scale_value, tilt)


func _cylinder_to(parent: Node3D, label: String, pos: Vector3, radius: float,
		height: float, mat: Material, segments := 16, scale_value := Vector3.ONE,
		tilt := 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.rotation.z = tilt
	n.scale = scale_value
	parent.add_child(n)
	return n


func _cone(label: String, pos: Vector3, bottom: float, top: float, height: float,
		mat: Material, segments := 12, scale_value := Vector3.ONE) -> MeshInstance3D:
	return _cone_to(_root, label, pos, bottom, top, height, mat, segments, scale_value)


func _cone_to(parent: Node3D, label: String, pos: Vector3, bottom: float, top: float,
		height: float, mat: Material, segments := 12,
		scale_value := Vector3.ONE) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = segments
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.scale = scale_value
	parent.add_child(n)
	return n


func _sphere(label: String, pos: Vector3, radius: float, mat: Material,
		scale_value := Vector3.ONE) -> MeshInstance3D:
	return _sphere_to(_root, label, pos, radius, mat, scale_value)


func _sphere_to(parent: Node3D, label: String, pos: Vector3, radius: float,
		mat: Material, scale_value := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 14
	mesh.rings = 9
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.scale = scale_value
	parent.add_child(n)
	return n


func _torus(label: String, pos: Vector3, inner: float, outer: float, mat: Material,
		rings := 32, segments := 8, scale_value := Vector3.ONE) -> MeshInstance3D:
	return _torus_to(_root, label, pos, inner, outer, mat, rings, segments, scale_value)


func _torus_to(parent: Node3D, label: String, pos: Vector3, inner: float, outer: float,
		mat: Material, rings := 32, segments := 8,
		scale_value := Vector3.ONE) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = rings
	mesh.ring_segments = segments
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.scale = scale_value
	parent.add_child(n)
	return n
