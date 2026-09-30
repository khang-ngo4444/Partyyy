@tool
extends Node3D
## Mô hình 3D nguyên bản cho bàn party "Rumble Reef".
## Chỉ dựng phần mỹ thuật; các ô OBan vẫn là node thật trong ban_party.tscn và giữ toàn bộ gameplay.

const WATER_Y := -1.18
const GROUND_Y := 0.58

var _root: Node3D
var _mats: Dictionary = {}


func _ready() -> void:
	_build()


func _build() -> void:
	if get_node_or_null("_GeneratedMap") != null:
		return
	_root = Node3D.new()
	_root.name = "_GeneratedMap"
	add_child(_root)
	_make_materials()
	_build_water_and_island()
	_build_boardwalk()
	_build_centerpiece()
	_build_landmarks()
	_build_rocks_and_palms()
	_build_lighting()
	# Camera chỉ tự bật khi chạy riêng scene để QA; khi được Main instance, camera người chơi giữ quyền.
	if Engine.is_editor_hint() or get_tree().current_scene == get_parent():
		_build_preview_camera(not Engine.is_editor_hint())


func _make_materials() -> void:
	_mats.rock = _material("Cliff rock", Color("#35465a"), 0.94)
	_mats.rock_light = _material("Rock highlights", Color("#596b78"), 0.9)
	_mats.grass = _material("Tropical grass", Color("#4c9b63"), 0.92)
	_mats.grass_dark = _material("Dark grass", Color("#2f6c50"), 0.95)
	_mats.sand = _material("Warm sand", Color("#ddb96f"), 0.88)
	_mats.wood = _material("Boardwalk wood", Color("#6e4030"), 0.91)
	_mats.wood_light = _material("Boardwalk trim", Color("#b66b3f"), 0.82)
	_mats.wood_dark = _material("Dark timber", Color("#35252a"), 0.93)
	_mats.gold = _material("Brass", Color("#f2b84b"), 0.36, 0.56)
	_mats.cyan = _material("Lagoon glow", Color("#35d5cf"), 0.22, 0.05, Color("#1aa69e"), 1.7)
	_mats.water = _material("Ocean", Color(0.035, 0.26, 0.37, 0.88), 0.12, 0.25, Color("#0a5363"), 0.45)
	_mats.red = _material("Festival red", Color("#de4a55"), 0.72)
	_mats.cream = _material("Canvas cream", Color("#f4dfab"), 0.86)
	_mats.purple = _material("Mystic purple", Color("#7d50ca"), 0.52, 0.08, Color("#5e34a5"), 0.42)
	_mats.leaf = _material("Palm leaf", Color("#2f815b"), 0.91)
	_mats.leaf_light = _material("Palm leaf light", Color("#58aa68"), 0.91)
	_mats.bone = _material("Old stone", Color("#a9aa9b"), 0.93)
	_mats.black = _material("Iron", Color("#202733"), 0.55, 0.48)


func _material(label: String, color: Color, roughness: float, metallic := 0.0,
		emission := Color(0, 0, 0, 1), emission_energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.resource_name = label
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


func _build_water_and_island() -> void:
	var ocean_mat: StandardMaterial3D = _mats.water.duplicate()
	ocean_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cylinder("Ocean", Vector3(0, WATER_Y, 0), 19.5, 0.18, ocean_mat, 64, Vector3(1, 1, 0.78))
	# Ba lớp địa hình tạo silhouette thấp, rộng và dễ đọc từ camera chéo trên cao.
	_cylinder("IslandCliff", Vector3(0, -0.28, 0), 10.7, 1.95, _mats.rock, 24,
			Vector3(1.0, 1.0, 0.72))
	_cylinder("IslandShelf", Vector3(-0.35, 0.27, 0.15), 9.95, 0.72, _mats.rock_light, 24,
			Vector3(1.0, 1.0, 0.72))
	_cylinder("GrassCap", Vector3(0.05, GROUND_Y, 0.1), 9.55, 0.32, _mats.grass, 24,
			Vector3(1.0, 1.0, 0.70))
	_cylinder("SandClearing", Vector3(-0.35, GROUND_Y + 0.19, -0.05), 6.9, 0.12, _mats.sand, 24,
			Vector3(1.0, 1.0, 0.69))
	# Các vệt cỏ không đối xứng làm mặt đảo bớt cảm giác hình học hoàn hảo.
	_cylinder("GrassPatchWest", Vector3(-5.4, GROUND_Y + 0.27, -1.0), 2.7, 0.10,
			_mats.grass_dark, 14, Vector3(1.25, 1, 0.72))
	_cylinder("GrassPatchEast", Vector3(5.25, GROUND_Y + 0.27, 1.25), 2.4, 0.10,
			_mats.grass_dark, 14, Vector3(1.2, 1, 0.68))
	# Đầm phát sáng ở giữa giúp chia foreground/background và tạo điểm nhấn board-game.
	_cylinder("LagoonRim", Vector3(0.2, GROUND_Y + 0.29, 0), 2.82, 0.18, _mats.rock, 28,
			Vector3(1.0, 1.0, 0.78))
	_cylinder("Lagoon", Vector3(0.2, GROUND_Y + 0.40, 0), 2.48, 0.08, _mats.cyan, 32,
			Vector3(1.0, 1.0, 0.78))


func _build_boardwalk() -> void:
	var spaces: Array[Node3D] = []
	for child in get_parent().get_children():
		if child is OBan:
			spaces.append(child)
	spaces.sort_custom(func(a: OBan, b: OBan) -> bool: return a.so < b.so)
	if spaces.size() < 2:
		return
	for i in spaces.size():
		var a := spaces[i].position
		var b := spaces[(i + 1) % spaces.size()].position
		var delta := Vector3(b.x - a.x, 0, b.z - a.z)
		var length := maxf(delta.length() - 1.18, 0.35)
		var center := (a + b) * 0.5
		center.y = minf(a.y, b.y) - 0.09
		var yaw := atan2(delta.x, delta.z)
		_box("Path_%02d" % i, center, Vector3(0.88, 0.16, length), _mats.wood, yaw)
		_box("PathTrimL_%02d" % i, center + Vector3(cos(yaw), 0.1, -sin(yaw)) * 0.39,
				Vector3(0.08, 0.13, length), _mats.gold, yaw)
		_box("PathTrimR_%02d" % i, center - Vector3(cos(yaw), 0.1, -sin(yaw)) * 0.39,
				Vector3(0.08, 0.13, length), _mats.gold, yaw)
		for p in 3:
			var t := (float(p) + 1.0) / 4.0
			var pos := a.lerp(b, t)
			pos.y = center.y + 0.12
			_box("Plank_%02d_%d" % [i, p], pos, Vector3(0.94, 0.035, 0.055),
					_mats.wood_light, yaw)


func _build_centerpiece() -> void:
	# Lều lễ hội méo vui mắt, đủ cao để map có landmark nhưng không che đường vòng.
	_cylinder("TentDeck", Vector3(0.2, 1.02, 0), 1.72, 0.28, _mats.wood_dark, 16,
			Vector3(1, 1, 0.78))
	_cylinder("TentBody", Vector3(0.2, 1.82, 0), 1.48, 1.35, _mats.cream, 16,
			Vector3(1, 1, 0.78))
	_cone("TentRoof", Vector3(0.2, 3.02, 0), 1.92, 0.0, 1.15, _mats.red, 16,
			Vector3(1, 1, 0.78))
	_cylinder("TentPole", Vector3(0.2, 3.92, 0), 0.09, 1.3, _mats.gold, 10)
	_cone("TentFlag", Vector3(0.45, 4.48, 0), 0.38, 0.0, 0.72, _mats.purple, 4,
			Vector3(1.35, 1, 0.5), deg_to_rad(45))
	for i in 8:
		var a := TAU * i / 8.0
		var lamp_pos := Vector3(0.2 + cos(a) * 2.5, 1.18, sin(a) * 1.95)
		_sphere("LagoonLamp_%d" % i, lamp_pos, 0.11, _mats.gold)
		_sphere("LagoonGlow_%d" % i, lamp_pos + Vector3.UP * 0.05, 0.075, _mats.cyan)


func _build_landmarks() -> void:
	# Chợ gần ô SHOP.
	_box("ShopCounter", Vector3(-1.0, 1.12, 3.55), Vector3(2.1, 0.72, 0.72), _mats.wood)
	for x in [-1.85, -0.15]:
		_cylinder("ShopPole", Vector3(x, 2.05, 3.55), 0.07, 2.25, _mats.wood_dark, 8)
	_box("ShopCanopy", Vector3(-1.0, 3.02, 3.55), Vector3(2.55, 0.18, 1.25), _mats.red,
			0.0, Vector3.ONE, deg_to_rad(-7))
	_box("ShopStripe", Vector3(-1.0, 3.13, 3.55), Vector3(0.46, 0.04, 1.28), _mats.cream)
	_add_label("SHOP", Vector3(-1.0, 2.15, 3.14), Color("#fff1be"), 54)

	# Rương lớn phía tây; rương gameplay vẫn là màu của ô và có thể di chuyển.
	_box("TreasureChest", Vector3(-5.25, 1.23, 1.15), Vector3(1.35, 0.72, 0.86), _mats.wood)
	_cylinder("ChestLid", Vector3(-5.25, 1.65, 1.15), 0.43, 1.35, _mats.wood_light, 12,
			Vector3(1, 1, 1), deg_to_rad(90))
	_box("ChestBand", Vector3(-5.25, 1.52, 0.70), Vector3(0.23, 0.86, 0.07), _mats.gold)
	_box("ChestLock", Vector3(-5.25, 1.34, 0.67), Vector3(0.32, 0.38, 0.13), _mats.gold)

	# Hai bia đá và cổng xương ở phía đông cho các ô hồi sinh.
	for i in 3:
		var pos := Vector3(5.0 + i * 0.62, 1.12, -1.55 + (i % 2) * 0.35)
		_box("Grave_%d" % i, pos, Vector3(0.42, 0.82 + i * 0.08, 0.18), _mats.bone,
				deg_to_rad(-12 + i * 13), Vector3.ONE, deg_to_rad(-8))
		_sphere("GraveTop_%d" % i, pos + Vector3.UP * (0.44 + i * 0.04), 0.22, _mats.bone)

	# Mỏm nguy hiểm/cột cảnh báo phía nam.
	for i in 5:
		var a := -0.8 + i * 0.4
		_cone("Spike_%d" % i, Vector3(2.2 + i * 0.34, 1.24, -3.75 + sin(a) * 0.2),
				0.17, 0.0, 0.9 + (i % 2) * 0.35, _mats.black, 7,
				Vector3.ONE, a * 0.12)
	_add_label("DANGER", Vector3(2.85, 1.62, -3.25), Color("#ff9b4a"), 42)


func _build_rocks_and_palms() -> void:
	var rock_data := [
		[Vector3(-8.7, 0.72, -3.3), Vector3(1.25, 1.0, 0.9)],
		[Vector3(-6.8, 0.76, 4.7), Vector3(1.05, 1.35, 0.82)],
		[Vector3(7.15, 0.70, 4.15), Vector3(1.4, 0.9, 0.75)],
		[Vector3(8.7, 0.66, -4.1), Vector3(1.05, 0.82, 0.9)],
		[Vector3(-2.0, 0.69, -6.35), Vector3(0.95, 0.7, 0.72)]
	]
	for i in rock_data.size():
		var d: Array = rock_data[i]
		_sphere("CoastRock_%d" % i, d[0], 0.9, _mats.rock, d[1])
		_sphere("CoastRockHi_%d" % i, d[0] + Vector3(0.18, 0.46, 0.06), 0.48,
				_mats.rock_light, (d[1] as Vector3) * 0.72)
	_palm("PalmWest", Vector3(-4.5, 0.88, -3.35), 1.0)
	_palm("PalmNorth", Vector3(3.75, 0.87, 3.8), 0.88)
	_palm("PalmEast", Vector3(5.75, 0.84, -3.0), 0.72)
	# Thùng và cọc giúp lấp các khoảng trống giữa landmark mà không che ô.
	for i in 4:
		var p := Vector3(-3.7 + i * 0.65, 1.0, 2.3 + (i % 2) * 0.25)
		_cylinder("Barrel_%d" % i, p, 0.31, 0.68, _mats.wood, 12)
		_cylinder("BarrelBand_%d" % i, p + Vector3.UP * 0.18, 0.32, 0.07, _mats.black, 12)


func _palm(prefix: String, base: Vector3, scale_factor: float) -> void:
	var trunk_height := 3.15 * scale_factor
	_cylinder(prefix + "Trunk", base + Vector3.UP * trunk_height * 0.5, 0.18 * scale_factor,
			trunk_height, _mats.wood_light, 9, Vector3(1, 1, 1), deg_to_rad(-4))
	var crown := base + Vector3(0.18, trunk_height, 0)
	_sphere(prefix + "Crown", crown, 0.28 * scale_factor, _mats.wood_dark)
	for i in 7:
		var a := TAU * i / 7.0
		var leaf_pos := crown + Vector3(cos(a), 0.04, sin(a)) * 0.72 * scale_factor
		_box(prefix + "Leaf_%d" % i, leaf_pos,
				Vector3(0.28, 0.07, 1.65) * scale_factor,
				_mats.leaf_light if i % 2 == 0 else _mats.leaf, -a,
				Vector3.ONE, deg_to_rad(-15))


func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "MapSun"
	sun.rotation_degrees = Vector3(-58, -35, 0)
	sun.light_color = Color("#ffe2b5")
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	_root.add_child(sun)
	for data in [
		[Vector3(-4.7, 3.0, 1.2), Color("#ffc05a")],
		[Vector3(4.6, 3.0, -1.1), Color("#ff655f")],
		[Vector3(0.2, 3.0, 0), Color("#4ee3d4")]
	]:
		var light := OmniLight3D.new()
		light.position = data[0]
		light.light_color = data[1]
		light.light_energy = 1.35
		light.omni_range = 6.5
		light.shadow_enabled = false
		_root.add_child(light)


func _build_preview_camera(make_current: bool) -> void:
	var camera := Camera3D.new()
	camera.current = make_current
	camera.name = "MapPreviewCamera"
	camera.position = Vector3(0, 17.5, 19.5)
	camera.fov = 48.0
	_root.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0, 0.75, 0), Vector3.UP)


func _box(node_name: String, pos: Vector3, size: Vector3, material: Material,
		yaw := 0.0, node_scale := Vector3.ONE, tilt_z := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation = Vector3(0, yaw, tilt_z)
	node.scale = node_scale
	_root.add_child(node)
	return node


func _cylinder(node_name: String, pos: Vector3, radius: float, height: float,
		material: Material, segments := 16, node_scale := Vector3.ONE,
		tilt_z := 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation.z = tilt_z
	node.scale = node_scale
	_root.add_child(node)
	return node


func _cone(node_name: String, pos: Vector3, bottom_radius: float, top_radius: float,
		height: float, material: Material, segments := 12, node_scale := Vector3.ONE,
		yaw := 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.height = height
	mesh.radial_segments = segments
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation.y = yaw
	node.scale = node_scale
	_root.add_child(node)
	return node


func _sphere(node_name: String, pos: Vector3, radius: float, material: Material,
		node_scale := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.scale = node_scale
	_root.add_child(node)
	return node


func _add_label(value: String, pos: Vector3, color: Color, size: int) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.font_size = size
	label.pixel_size = 0.009
	label.modulate = color
	label.outline_size = 12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_root.add_child(label)
