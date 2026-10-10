class_name BanDoTank
extends Node2D

## Đấu trường Tank: lưới ô, tường đặt sẵn trong scene (bản đồ đối xứng dựng tay).
## Ngoài biên coi như thép.

const O := 32.0
## Ô trống (không có node).
const TRONG := -1

@export var rong := 25
@export var cao := 17

## Ô -> node tường; null = trống. Tra bằng `y * rong + x`.
var _tuong: Array[OTuong] = []
var _cho: Array[Vector2] = []


func _ready() -> void:
	_tuong.resize(rong * cao)
	for t: OTuong in find_children("*", "OTuong", true, false):
		var i := chi_so_tai(to_local(t.global_position))
		if i >= 0:
			_tuong[i] = t
	for m: Marker2D in find_children("*", "Marker2D", true, false):
		_cho.append(to_local(m.global_position))
	if _cho.is_empty():
		push_error("BanDoTank: '%s' khong co Marker2D nao. Ban do phai co cho sinh." % name)


func kich_thuoc() -> Vector2:
	return Vector2(rong, cao) * O


## Chỗ sinh theo thứ tự trong scene (hai chỗ liền nhau ở xa nhau).
func cho_sinh() -> Array[Vector2]:
	return _cho


## `TRONG`, `GACH` hoặc `THEP`.
func loai_tai(p: Vector2) -> int:
	var i := chi_so_tai(p)
	if i < 0:
		return OTuong.Loai.THEP           # ngoài biên: tường cứng, đạn tan, xe không ra được
	return _tuong[i].loai if _tuong[i] != null else TRONG


## Số hiệu ô chứa điểm `p`; -1 = ngoài bản đồ.
func chi_so_tai(p: Vector2) -> int:
	var x := floori(p.x / O)
	var y := floori(p.y / O)
	if x < 0 or y < 0 or x >= rong or y >= cao:
		return -1
	return y * rong + x


func pha(ix: int) -> void:
	if ix < 0 or ix >= _tuong.size():
		return
	var t := _tuong[ix]
	if t != null and t.loai == OTuong.Loai.GACH:
		_tuong[ix] = null
		t.queue_free()
