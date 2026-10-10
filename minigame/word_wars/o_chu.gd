class_name OChu
extends Node3D

## Một ô chữ trên sàn: đứng lên rồi bấm E là gõ chữ của ô.

@export var chu := "A":
	set(v):
		chu = v
		if is_node_ready():
			($Chu as Label3D).text = v

## Vùng đứng.
@onready var vung: Area3D = $Vung


func _ready() -> void:
	($Chu as Label3D).text = chu
