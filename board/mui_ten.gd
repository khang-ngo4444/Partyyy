class_name MuiTen
extends Node3D

## Mũi tên chỉ hướng ở ngã rẽ (`Sang` = đang chọn, `Mo` = không).

const CACH_TAM := 1.25
const CAO := 1.1
const NHAP_NHO := 0.1
const TOC_NHAP_NHO := 4.0

var _goc := Vector3.ZERO
var _t := 0.0

@onready var _sang: Node3D = $Sang
@onready var _mo: Node3D = $Mo


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	global_position = _goc + Vector3.UP * sin(_t * TOC_NHAP_NHO) * NHAP_NHO


func dat(tu: Vector3, toi: Vector3, dang_chon: bool) -> void:
	var huong := toi - tu
	huong.y = 0.0
	if huong.length_squared() < 0.0001:
		huong = Vector3.FORWARD
	huong = huong.normalized()
	_goc = tu + huong * CACH_TAM + Vector3.UP * CAO
	global_position = _goc
	look_at(_goc + huong, Vector3.UP)
	_sang.visible = dang_chon
	_mo.visible = not dang_chon
	visible = true


func an() -> void:
	visible = false
