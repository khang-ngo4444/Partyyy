class_name XucXac3D
extends Node3D
## Xúc xắc 3D trước camera; mọi máy diễn cùng kết quả từ RPC.

## Xúc xắc đã nằm yên với mặt `value` (chưa biến mất).
signal da_dung(value: int)

const TOC_VONG := 1.4

## Tắt khi nằm trong `HaiXucXac` (cặp xúc xắc có một nhãn chung).
@export var hien_nhan := true

var _tween: Tween

@onready var _body: Node3D = $DiceBody
@onready var _label: Label3D = $ActionLabel
@onready var _ring: MeshInstance3D = $ResultRing


func _ready() -> void:
	_label.visible = hien_nhan


func _process(delta: float) -> void:
	if visible:
		_ring.rotation.z += delta * TOC_VONG


func tung(value: int, player_name: String) -> void:
	value = clampi(value, 1, 6)
	if _tween != null:
		_tween.kill()
	visible = true
	scale = Vector3.ONE * 0.04
	position = Vector3(0, -0.9, -5.4)
	_body.rotation = Vector3.ZERO
	_label.text = "%s\nĐANG TUNG..." % player_name

	var final_rotation := _rotation_for(value)
	var spinning := final_rotation + Vector3(TAU * 3.0, TAU * 4.0, TAU * 2.0)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE * 1.08, 0.24).set_trans(
			Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "position", Vector3(0, 0.30, -5.8), 0.42).set_trans(
			Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_body, "rotation", spinning, 0.96).set_trans(
			Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", Vector3(0, -0.10, -5.8), 0.22).set_trans(
			Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await _tween.finished
	if not is_inside_tree():
		return
	_body.rotation = final_rotation
	_label.text = "%s\nTUNG ĐƯỢC  %d" % [player_name, value]
	da_dung.emit(value)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE * 1.22, 0.15).set_trans(
			Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(1.05)
	_tween.tween_property(self, "scale", Vector3.ZERO, 0.22).set_trans(
			Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await _tween.finished
	if is_inside_tree():
		visible = false


func _rotation_for(value: int) -> Vector3:
	match value:
		1:
			return Vector3.ZERO
		2:
			return Vector3(0, -PI * 0.5, 0)
		3:
			return Vector3(PI * 0.5, 0, 0)
		4:
			return Vector3(-PI * 0.5, 0, 0)
		5:
			return Vector3(0, PI * 0.5, 0)
		_:
			return Vector3(0, PI, 0)
