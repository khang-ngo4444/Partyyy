class_name XucXac3D
extends Node3D
## Xúc xắc 3D trước camera: mọi máy đều thấy cùng hoạt cảnh từ kết quả RPC của master.

var _body: Node3D
var _label: Label3D
var _ring: MeshInstance3D
var _tween: Tween


func _ready() -> void:
	_build()
	visible = false
	set_process(true)


func _process(delta: float) -> void:
	if visible and _ring != null:
		_ring.rotation.z += delta * 1.4


func _build() -> void:
	_body = Node3D.new()
	_body.name = "DiceBody"
	add_child(_body)

	var white := StandardMaterial3D.new()
	white.albedo_color = Color("#fff4dc")
	white.roughness = 0.28
	white.emission_enabled = true
	white.emission = Color("#6d7e99")
	white.emission_energy_multiplier = 0.12

	var black := StandardMaterial3D.new()
	black.albedo_color = Color("#121927")
	black.roughness = 0.4
	black.emission_enabled = true
	black.emission = Color("#020308")
	black.emission_energy_multiplier = 0.2

	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("#ffb72d")
	gold.metallic = 0.65
	gold.roughness = 0.25
	gold.emission_enabled = true
	gold.emission = Color("#8b3906")
	gold.emission_energy_multiplier = 0.7

	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 1.22
	var cube := MeshInstance3D.new()
	cube.name = "IvoryCube"
	cube.mesh = cube_mesh
	cube.material_override = white
	_body.add_child(cube)

	# Khung vàng mảnh cho silhouette rõ trên cả nền biển sáng lẫn tối.
	for axis in 3:
		for a in [-1.0, 1.0]:
			for b in [-1.0, 1.0]:
				var edge_mesh := CylinderMesh.new()
				edge_mesh.top_radius = 0.025
				edge_mesh.bottom_radius = 0.025
				edge_mesh.height = 1.20
				edge_mesh.radial_segments = 6
				var edge := MeshInstance3D.new()
				edge.mesh = edge_mesh
				edge.material_override = gold
				if axis == 0:
					edge.rotation.z = PI * 0.5
					edge.position = Vector3(0, a * 0.61, b * 0.61)
				elif axis == 1:
					edge.position = Vector3(a * 0.61, 0, b * 0.61)
				else:
					edge.rotation.x = PI * 0.5
					edge.position = Vector3(a * 0.61, b * 0.61, 0)
				_body.add_child(edge)

	_add_face(1, Vector3(0, 0, 1), Vector3.RIGHT, Vector3.UP, black)
	_add_face(6, Vector3(0, 0, -1), Vector3.LEFT, Vector3.UP, black)
	_add_face(2, Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3.UP, black)
	_add_face(5, Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3.UP, black)
	_add_face(3, Vector3(0, 1, 0), Vector3.RIGHT, Vector3(0, 0, -1), black)
	_add_face(4, Vector3(0, -1, 0), Vector3.RIGHT, Vector3(0, 0, 1), black)

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.86
	ring_mesh.outer_radius = 1.04
	ring_mesh.rings = 36
	ring_mesh.ring_segments = 8
	_ring = MeshInstance3D.new()
	_ring.name = "ResultRing"
	_ring.mesh = ring_mesh
	_ring.material_override = gold
	_ring.position.z = -0.78
	_ring.rotation.x = PI * 0.5
	add_child(_ring)

	_label = Label3D.new()
	_label.name = "ActionLabel"
	_label.position = Vector3(0, 1.35, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 64
	_label.outline_size = 16
	_label.pixel_size = 0.008
	_label.modulate = Color("#fff2bd")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


func _add_face(value: int, normal: Vector3, right: Vector3, up: Vector3,
		material: Material) -> void:
	for p in _pattern(value):
		var mesh := SphereMesh.new()
		mesh.radius = 0.095
		mesh.height = 0.19
		mesh.radial_segments = 10
		mesh.rings = 6
		var pip := MeshInstance3D.new()
		pip.name = "Pip_%d" % value
		pip.mesh = mesh
		pip.material_override = material
		pip.position = normal * 0.625 + right * p.x * 0.31 + up * p.y * 0.31
		pip.scale = Vector3.ONE if absf(normal.y) < 0.5 else Vector3(1, 0.58, 1)
		_body.add_child(pip)


func _pattern(value: int) -> Array[Vector2]:
	var c := Vector2.ZERO
	var tl := Vector2(-1, 1)
	var top_right := Vector2(1, 1)
	var bl := Vector2(-1, -1)
	var br := Vector2(1, -1)
	var ml := Vector2(-1, 0)
	var mr := Vector2(1, 0)
	match value:
		1:
			return [c]
		2:
			return [tl, br]
		3:
			return [tl, c, br]
		4:
			return [tl, top_right, bl, br]
		5:
			return [tl, top_right, c, bl, br]
		_:
			return [tl, top_right, ml, mr, bl, br]


func tung(value: int, player_name: String) -> void:
	value = clampi(value, 1, 6)
	if _tween != null:
		_tween.kill()
	visible = true
	scale = Vector3.ONE * 0.04
	position = Vector3(0, -0.9, -5.4)
	_body.rotation = Vector3.ZERO
	_label.text = "%s\nĐANG TUNG..." % player_name

	var final_rotation := _rotation_for(value)
	var spinning := final_rotation + Vector3(TAU * 3.0, TAU * 4.0, TAU * 2.0)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE * 1.08, 0.24).set_trans(
			Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "position", Vector3(0, 0.30, -5.8), 0.42).set_trans(
			Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_body, "rotation", spinning, 0.96).set_trans(
			Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", Vector3(0, -0.10, -5.8), 0.22).set_trans(
			Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await _tween.finished
	if not is_inside_tree():
		return
	_body.rotation = final_rotation
	_label.text = "%s\nTUNG ĐƯỢC  %d" % [player_name, value]
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE * 1.22, 0.15).set_trans(
			Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(1.05)
	_tween.tween_property(self, "scale", Vector3.ZERO, 0.22).set_trans(
			Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await _tween.finished
	if is_inside_tree():
		visible = false


func _rotation_for(value: int) -> Vector3:
	match value:
		1:
			return Vector3.ZERO
		2:
			return Vector3(0, -PI * 0.5, 0)
		3:
			return Vector3(PI * 0.5, 0, 0)
		4:
			return Vector3(-PI * 0.5, 0, 0)
		5:
			return Vector3(0, PI * 0.5, 0)
		_:
			return Vector3(0, PI, 0)
