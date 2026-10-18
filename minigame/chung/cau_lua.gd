class_name CauLua
extends Area3D

## Quả cầu lửa bay thẳng đều rồi tự tan; mọi máy tự tính đường bay từ một gói (điểm, hướng).

## Tốc bay (m/s).
const TOC_DO := 34.0
## Sống bao lâu (giây).
const SONG := 1.2
const BAN_KINH := 0.55

## Ai bắn (không tự trúng đạn của mình).
var nguoi_ban := 0
var _huong := Vector3.ZERO
var _con := SONG
var _tu_kiem := Vector3.ZERO


## `di_truoc`: số giây quả cầu đã bay trước khi tới máy này (bù trễ mạng).
func ban(tu: Vector3, huong: Vector3, id_nguoi_ban: int, di_truoc := 0.0) -> void:
	_huong = huong.normalized()
	_tu_kiem = tu
	global_position = tu + _huong * TOC_DO * di_truoc
	_con = SONG - di_truoc
	nguoi_ban = id_nguoi_ban


func _physics_process(delta: float) -> void:
	global_position += _huong * TOC_DO * delta
	_con -= delta
	if _con <= 0.0:
		queue_free()


## Quét cả đường bay từ lần kiểm tra trước, gồm đoạn bù trễ; không xuyên người ở FPS thấp.
func trung(p: Node3D) -> bool:
	var from := _tu_kiem
	_tu_kiem = global_position
	return quet_trung(from, global_position, p.global_position)


func huong_bay() -> Vector3:
	return _huong


static func quet_trung(from: Vector3, to: Vector3, feet: Vector3) -> bool:
	var bottom := feet + Vector3.UP * 0.4
	var top := feet + Vector3.UP * 1.4
	return khoang_cach_doan(from, to, bottom, top) <= BAN_KINH + 0.4


## Khoảng cách ngắn nhất giữa hai đoạn 3D, kể cả đoạn đứng yên / song song.
static func khoang_cach_doan(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var d1 := q1 - p1
	var d2 := q2 - p2
	var r := p1 - p2
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var s := 0.0
	var t := 0.0
	if a <= 0.000001 and e <= 0.000001:
		return r.length()
	if a <= 0.000001:
		t = clampf(f / e, 0.0, 1.0)
	else:
		var c := d1.dot(r)
		if e <= 0.000001:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b := d1.dot(d2)
			var denominator := a * e - b * b
			if denominator > 0.000001:
				s = clampf((b * f - c * e) / denominator, 0.0, 1.0)
			t = (b * s + f) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)
	return (p1 + d1 * s).distance_to(p2 + d2 * t)
