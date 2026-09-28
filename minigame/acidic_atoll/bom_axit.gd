class_name BomAxit
extends Node3D

## MỘT quả bom đang rơi xuống đảo, rồi nổ.
##
## Hình quả bom, vòng đánh dấu chỗ rơi, quầng nổ và vùng sát thương đều là node trong
## `bom_axit.tscn`. Script chỉ lo **rơi — nổ — tan**.
##
## ## Vòng đánh dấu có trước quả bom
##
## Nó hiện ngay lúc bom bắt đầu rơi, ở đúng chỗ bom sẽ chạm. Không có nó thì trò này là xổ số:
## nhìn lên trời đoán quỹ đạo trong khi vẫn phải nhìn xuống sàn mà chạy. Có nó thì người chơi
## đọc được sàn và trò thành chuyện né, chứ không phải chuyện may.
##
## ## Vùng nổ CHÍNH LÀ quầng sáng nhìn thấy
##
## `No/Hinh` lấy đúng bán kính của `Quang`. Không có con số tầm nổ nào chép tay trong code —
## bản Laser Leap đầu tiên làm thế và đẻ ra vùng "nhìn thấy nhưng vô hại".

## Bom xuất hiện ở độ cao này so với mặt đảo.
const CAO_ROI := 20.0
## Rơi hết chừng này giây. Đây là thời gian người chơi có để tránh vòng đánh dấu.
const GIAY_ROI := 1.5
## Quầng nổ nở ra rồi tắt trong chừng này giây.
const GIAY_NO := 0.4

var _t := 0.0
var _no := false

@onready var _qua: Node3D = $Qua
@onready var _dau: Node3D = $Dau
@onready var _quang: Node3D = $Quang
@onready var _no_vung: Area3D = $No


func _ready() -> void:
	_quang.visible = false
	_no_vung.monitoring = false


## Đặt bom vào đúng chỗ nó sẽ chạm đất rồi thả.
func tha(cho_cham: Vector3) -> void:
	global_position = cho_cham


## Quầng nổ đang sống: lúc này `vung()` mới có nghĩa.
func dang_no() -> bool:
	return _no


func vung() -> Area3D:
	return _no_vung


func _process(delta: float) -> void:
	_t += delta
	if not _no:
		var k := clampf(_t / GIAY_ROI, 0.0, 1.0)
		_qua.position.y = lerpf(CAO_ROI, 0.0, k)
		if k >= 1.0:
			_bung()
		return
	if _t >= GIAY_ROI + GIAY_NO:
		queue_free()


func _bung() -> void:
	_no = true
	_qua.visible = false
	_dau.visible = false
	_quang.visible = true
	_no_vung.monitoring = true
