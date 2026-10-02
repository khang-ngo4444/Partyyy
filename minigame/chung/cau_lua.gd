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

## Bay nhanh cỡ nào, m/s. 16 thì cả phòng thấy quả cầu lết tới rồi mới bị hất — chậm quá, trúng
## mà như không trúng. 26 vẫn kịp thấy (băng sân 23 m mất ~0,9 s).
const TOC_DO := 26.0
## Sống bao lâu rồi tự tan, giây. `26 × 1.0 = 26 m` — vừa đủ băng qua sân 23 m.
const SONG := 1.0

## Ai bắn. Máy nhận đọc để khỏi cho người bắn tự trúng đạn của mình.
var nguoi_ban := 0

var _huong := Vector3.ZERO
var _con := SONG


## `di_truoc`: số giây quả cầu ĐÃ bay trước khi tới máy này. Gói bắn tới máy khác trễ nửa RTT;
## không bù thì trên máy nạn nhân quả cầu luôn tới muộn chừng đó, và cú hất trễ theo.
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
