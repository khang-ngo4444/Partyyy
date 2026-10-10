class_name QuanTuong
extends Node3D

## Quân cờ tướng: đĩa + chữ Hán nằm ngửa; `dat()` chọn chữ và màu mực theo bên.

const MUC := [Color("b8322c"), Color("1c1a18")]
const CHU := [
	["兵", "炮", "俥", "傌", "相", "仕", "帥"],
	["卒", "砲", "車", "馬", "象", "士", "將"],
]


func dat(ben: int, loai: int) -> void:
	var chu := $Chu as MeshInstance3D
	var bo: Array = CHU[ben % 2]
	(chu.mesh as TextMesh).text = bo[loai % bo.size()]
	(chu.material_override as StandardMaterial3D).albedo_color = MUC[ben % 2]
