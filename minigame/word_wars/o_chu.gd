class_name OChu
extends Node3D

## Bệ chữ cản đường; đứng cạnh rồi bấm E. Nút lún ngắn khi nhập đúng.

@export var chu := "A":
	set(v):
		chu = v
		if is_node_ready():
			($Chu as Label3D).text = v

## Vùng đứng.
@onready var vung: Area3D = $Vung
var _nhan: Tween


func _ready() -> void:
	($Chu as Label3D).text = chu


func nhan() -> void:
	if _nhan != null:
		_nhan.kill()
	_nhan = create_tween()
	_nhan.set_parallel(true)
	_nhan.tween_property($Mat, "position:y", 1.46, 0.07)
	_nhan.tween_property($Chu, "position:y", 1.60, 0.07)
	_nhan.chain().tween_property($Mat, "position:y", 1.60, 0.18)
	_nhan.parallel().tween_property($Chu, "position:y", 1.74, 0.18)
