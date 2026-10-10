class_name CauLua
extends Area3D

## Quả cầu lửa bay thẳng đều rồi tự tan; mọi máy tự tính đường bay từ một gói (điểm, hướng).

## Tốc bay (m/s).
const TOC_DO := 26.0
## Sống bao lâu (giây).
const SONG := 1.0

## Ai bắn (không tự trúng đạn của mình).
var nguoi_ban := 0
var _huong := Vector3.ZERO
var _con := SONG


## `di_truoc`: số giây quả cầu đã bay trước khi tới máy này (bù trễ mạng).
func ban(tu: Vector3, huong: Vector3, id_nguoi_ban: int, di_truoc := 0.0) -> void:
	_huong = huong.normalized()
	global_position = tu + _huong * TOC_DO * di_truoc
	_con = SONG - di_truoc
	nguoi_ban = id_nguoi_ban


func _physics_process(delta: float) -> void:
	global_position += _huong * TOC_DO * delta
	_con -= delta
	if _con <= 0.0:
		queue_free()
