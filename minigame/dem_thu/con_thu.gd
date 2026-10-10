class_name ConThu
extends Node3D

## Một con thú chạy từ phải sang trái; vị trí là hàm của thời gian.

## Qua mép trái chừng này thì tan.
const X_HET := -16.0
const NHUN_CAO := 0.25
const NHUN_NHIP := 10.0

var _x0 := 0.0
var _z := 0.0
var _toc := 0.0
var _t0 := 0.0


## Quay mặt sang trái (model nhìn về +Z).
func chay(x0: float, z: float, toc: float, t0: float) -> void:
	_x0 = x0
	_z = z
	_toc = toc
	_t0 = t0
	rotation.y = -PI * 0.5


## false = đã chạy hết.
func dat_luc(t: float) -> bool:
	var x := _x0 - _toc * (t - _t0)
	if x < X_HET:
		return false
	position = Vector3(x, absf(sin((t - _t0) * NHUN_NHIP)) * NHUN_CAO, _z)
	return true
