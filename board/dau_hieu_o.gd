class_name DauHieuO
extends Node3D

## Rào / bẫy / neo nằm trên một ô. Hình và animation "hien" nằm trong mô hình .glb
## (`3d/tao_vat_pham.py`); script chỉ đặt chỗ và bật/tắt.

@onready var _anim: AnimationPlayer = $MoHinh/AnimationPlayer


func dat(vi_tri: Vector3) -> void:
	global_position = vi_tri
	if visible:
		return
	visible = true
	_anim.play("hien")


func an() -> void:
	visible = false
