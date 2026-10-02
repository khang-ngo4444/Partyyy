class_name OChu
extends Node3D

## MỘT ô chữ nằm trên sàn Word Wars. Đứng lên ô rồi bấm E là gõ chữ của ô.
##
## Mặt ô, chữ in trên mặt và vùng đứng đều là node trong `o_chu.tscn`; 26 ô A–Z đặt sẵn trong
## `san_chu.tscn`, mỗi ô mang `chu` riêng. Script không dựng gì.

@export var chu := "A":
	set(v):
		chu = v
		if is_node_ready():
			($Chu as Label3D).text = v

## Vùng đứng. Hỏi `overlaps_body` thẳng vào nó — ô nhìn thấy CHÍNH LÀ ô tính, không chép số.
@onready var vung: Area3D = $Vung


func _ready() -> void:
	($Chu as Label3D).text = chu
