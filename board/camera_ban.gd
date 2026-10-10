class_name CameraBan
extends Camera3D

## Camera bàn khi không phải lượt mình: bám người đang đi lượt.

## Độ lệch so với người được bám (toạ độ thế giới).
@export var lech := Vector3(0.0, 8.0, 7.0)
@export var muot := 3.5

var _theo: Node3D = null


func _process(delta: float) -> void:
	if _theo == null or not is_instance_valid(_theo) or not current:
		return
	var nhin := _theo.global_position + Vector3.UP
	var dich := Transform3D(Basis(), _theo.global_position + lech).looking_at(nhin, Vector3.UP)
	global_transform = global_transform.interpolate_with(dich, clampf(muot * delta, 0.0, 1.0))


## Lần đầu bật lên thì xuất phát từ camera đang dùng để chuyển mượt.
func theo(n: Node3D) -> void:
	_theo = n
	if n == null or current:
		return
	var cu := get_viewport().get_camera_3d()
	if cu != null and cu != self:
		global_transform = cu.global_transform
	make_current()
