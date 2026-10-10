class_name VatTrenO
extends Node3D

## Vật nổi trên ô (Rương báu, Chó ngao): đặt lên ô và xoay node `Than`.

const CAO_TREN_O := 1.3
const GIAY_DOI_CHO := 0.8
const TOC_DO_XOAY := 0.9

@onready var _than: Node3D = $Than


func _process(delta: float) -> void:
	if visible:
		_than.rotation.y += delta * TOC_DO_XOAY


func dat_len(vi_tri_o: Vector3) -> void:
	var dich := vi_tri_o + Vector3.UP * CAO_TREN_O
	if not visible:
		global_position = dich
		visible = true
		return
	if global_position.is_equal_approx(dich):
		return
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(self, "global_position", dich,
			GIAY_DOI_CHO)


func an() -> void:
	visible = false
