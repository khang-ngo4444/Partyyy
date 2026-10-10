class_name Vet
extends Area3D

## Một đoạn tường sáng sau lưng người chơi (hình và va chạm cùng kéo dài theo `scale`).

## Chiều dài gốc của mesh theo Z.
const DAI_GOC := 1.0
## Bề dày tường; mỗi đoạn dài thêm chừng này để chỗ rẽ không hở khe.
const DAY := 0.3

## Chủ vệt.
var nguoi := 0
## `gio()` lúc đặt.
var luc := 0.0


func dat(chu: int, gio_van: float, tu: Vector3, den: Vector3, vat_lieu: Material) -> void:
	nguoi = chu
	luc = gio_van
	var dai := tu.distance_to(den)
	global_position = (tu + den) * 0.5
	if dai > 0.001:
		# `look_at` quay -Z theo hướng đi.
		look_at(Vector3(den.x, global_position.y, den.z), Vector3.UP)
		scale.z = (dai + DAY) / DAI_GOC
	if vat_lieu != null:
		($Mat as MeshInstance3D).material_override = vat_lieu
