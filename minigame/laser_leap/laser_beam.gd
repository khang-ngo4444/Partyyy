extends Node3D

@export var warning_material: StandardMaterial3D
var _danger_material: Material
var _previous_position := Vector3.ZERO
var _active := false
@onready var visual: MeshInstance3D = $Mat
@onready var collider: CollisionShape3D = $Vung/Hinh


func _ready() -> void:
	_danger_material = visual.material_override
	hide()


func present(axis: int, offset: float, dangerous: bool) -> void:
	var next := Vector3(0, position.y, offset) if axis == 0 else Vector3(offset, position.y, 0)
	_previous_position = position if _active and dangerous else next
	position = next
	rotation.y = 0.0 if axis == 0 else PI * 0.5
	_active = dangerous
	show()
	visual.material_override = _danger_material if dangerous else warning_material
	visual.scale = Vector3.ONE if dangerous else Vector3(1, 1, 0.3)


func deactivate() -> void:
	_active = false
	hide()


func hits(player: Player) -> bool:
	if not _active:
		return false
	var capsule := player.get_node("Collision").shape as CapsuleShape3D
	var radius := capsule.radius if capsule != null else 0.4
	var shape := collider.shape as BoxShape3D
	var point := to_local(player.global_position)
	var movement := basis.inverse() * (_previous_position - position)
	# Test the complete translated strip, so a slow frame cannot skip a crossing.
	var center := Vector2(0, movement.z * 0.5)
	var half_size := Vector2(shape.size.x, shape.size.z + absf(movement.z)) * 0.5
	return circle_overlaps_box(Vector2(point.x, point.z) - center, half_size, radius)


static func circle_overlaps_box(point: Vector2, half_size: Vector2, radius: float) -> bool:
	var nearest := point.clamp(-half_size, half_size)
	return point.distance_squared_to(nearest) <= radius * radius
