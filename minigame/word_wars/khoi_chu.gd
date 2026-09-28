class_name KhoiChu
extends Node3D

## MỘT khối chữ cái rơi xuống sân.
##
## Hình khối, chữ trên mặt và vùng đấm đều là node trong `khoi_chu.tscn`. Script chỉ lo
## **rơi xuống, nằm đó, rồi tan**.
##
## ## Vì sao KHÔNG phải `RigidBody3D` như guide ghi
##
## Khối rơi tự do va vào nhau thì mỗi máy ra một đống khác nhau — vật lý Godot không hứa hẹn
## cho ra cùng kết quả trên hai máy khác cấu hình. Mà trò này là trò ĐUA: hai người cùng ghép
## một từ, người thấy chữ "H" nằm gần chân mình mà người kia thấy nó văng ra mép sân là thua
## oan vì máy chứ không phải vì tay. Rơi thẳng tới một chỗ tính sẵn từ hạt giống thì mọi máy
## bày ra đúng một bàn cờ, và không tốn gói tin nào.

## Khối xuất hiện ở độ cao này rồi rơi xuống.
const CAO_ROI := 14.0
## Rơi hết chừng này giây.
const GIAY_ROI := 1.2
## Nằm lại chừng này giây rồi tan. Không có thì sân kín đặc chữ sau nửa phút.
const SONG := 13.0
## Tâm khối nằm ở độ cao này khi đã chạm sàn.
const CAO_DAT := 0.55

## Chữ cái của khối. Máy đọc để biết người chơi vừa đấm trúng chữ gì.
var chu := ""

var _t := 0.0

@onready var _than: Node3D = $Than
@onready var vung: Area3D = $Vung


## Thả khối chữ `ky_tu` xuống đúng chỗ `cho` (toạ độ thế giới, y bị bỏ qua).
func dat(ky_tu: String, cho: Vector3) -> void:
	chu = ky_tu
	global_position = Vector3(cho.x, cho.y + CAO_DAT, cho.z)
	($Than/Chu as Label3D).text = ky_tu


func _process(delta: float) -> void:
	_t += delta
	# Vùng đấm đi theo khối đang rơi, không đứng sẵn dưới đất: đấm được thứ chưa chạm sàn thì
	# người chơi sẽ đấm vào chỗ trống, vì mắt họ thấy khối còn lơ lửng.
	_than.position.y = lerpf(CAO_ROI, 0.0, clampf(_t / GIAY_ROI, 0.0, 1.0))
	vung.position.y = _than.position.y
	if _t >= GIAY_ROI + SONG:
		queue_free()
