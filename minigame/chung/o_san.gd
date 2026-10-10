class_name OSan
extends Node3D

## Một ô sàn: bật/tắt (cả va chạm) và đổi vật liệu.

@export var vat_lieu_thuong: StandardMaterial3D = null

@onready var _mat: MeshInstance3D = $Mat
@onready var _than: StaticBody3D = $Than


func dat(hien: bool) -> void:
	visible = hien
	_than.collision_layer = 1 if hien else 0
	if hien:
		_mat.material_override = vat_lieu_thuong


## `null` = màu thường.
func son(vat_lieu: StandardMaterial3D) -> void:
	_mat.material_override = vat_lieu if vat_lieu != null else vat_lieu_thuong
