extends Node3D

@export var warning_material: StandardMaterial3D
var _danger_material: Material = null
var _previous_angle: float = 0.0
var _active: bool = false
const SWEEP_STEP: float = 0.02
@onready var visual: MeshInstance3D = $Mat
@onready var area: Area3D = $Vung
@onready var collider: CollisionShape3D = $Vung/Hinh


func _ready() -> void:
	_danger_material = visual.material_override
	hide()


func present(angle: float, dangerous: bool) -> void:
	_previous_angle = rotation.y if _active and dangerous else angle
	rotation.y = angle
	_active = dangerous
	show()
	visual.material_override = _danger_material if dangerous else warning_material
	visual.scale = Vector3.ONE if dangerous else Vector3(1.0, 1.0, 0.3)


func deactivate() -> void:
	_active = false
	hide()


func hits(player: Player) -> bool:
	if not _active:
		return false
	var capsule: CapsuleShape3D = player.get_node("Collision").shape as CapsuleShape3D
	var radius: float = capsule.radius if capsule != null else 0.4
	var shape: BoxShape3D = collider.shape as BoxShape3D
	var difference: float = rotation.y - _previous_angle
	var samples: int = maxi(1, ceili(absf(difference) / SWEEP_STEP))
	for step: int in range(samples + 1):
		var angle: float = lerpf(_previous_angle, rotation.y, float(step) / samples)
		var point: Vector3 = Basis(Vector3.UP, -angle) * (player.global_position - global_position)
		if circle_overlaps_box(Vector2(point.x, point.z), Vector2(shape.size.x, shape.size.z) * 0.5, radius):
			return true
	return false


static func circle_overlaps_box(point: Vector2, half_size: Vector2, radius: float) -> bool:
	var nearest := point.clamp(-half_size, half_size)
	return point.distance_squared_to(nearest) <= radius * radius
