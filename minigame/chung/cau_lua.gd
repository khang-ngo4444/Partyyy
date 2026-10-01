class_name CauLua
extends Area3D

## MỘT quả cầu lửa đang bay.
##
## Hình dạng, hạt lửa và hộp va chạm nằm trong `cau_lua.tscn`. Script chỉ lo **bay và tự
## chết** — đó là toàn bộ việc của nó.
##
## ## Hộp va chạm CHÍNH LÀ node nhìn thấy
##
## `Area3D` + `CollisionShape3D` lấy đúng bán kính của quả cầu trong `.tscn`. Không có con số
## tầm bắn nào chép tay trong code — bản Laser Leap đầu tiên làm thế và đẻ ra vùng "nhìn thấy
## nhưng vô hại" (xem `ASSET-CAN-THEM.md`).
##
## ## Bay thẳng đều nên KHÔNG cần đồng bộ
##
## Tốc độ không đổi, hướng không đổi. Mọi máy nhận cùng một gói `(điểm bắn, hướng)` rồi tự
## tính ra cùng một đường bay. Cả đời quả cầu tốn đúng **một** gói tin — chính là gói sinh ra nó.

## Bay nhanh cỡ nào, m/s. Chậm quá thì né được bằng cách đi bộ; nhanh quá thì không kịp thấy.
const TOC_DO := 16.0
## Sống bao lâu rồi tự tan, giây. `16 × 1.6 = 25 m` — vừa đủ băng qua sân 23 m.
const SONG := 1.6

## Ai bắn. Máy nhận đọc để khỏi cho người bắn tự trúng đạn của mình.
var nguoi_ban := 0

var _huong := Vector3.ZERO
var _con := SONG


func ban(tu: Vector3, huong: Vector3, id_nguoi_ban: int) -> void:
	global_position = tu
	_huong = huong.normalized()
	nguoi_ban = id_nguoi_ban


func _physics_process(delta: float) -> void:
	global_position += _huong * TOC_DO * delta
	_con -= delta
	if _con <= 0.0:
		queue_free()
