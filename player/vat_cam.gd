class_name VatCam
extends Node3D

## Món đang chọn, nổi xoay trên đầu nhân vật cho cả phòng thấy.
## Cỡ hình = `scale` của node này trong `player.tscn` (không đặt trong code).
## Lúc dùng món, model này được cất (`DungDo._net_cam`); hiệu ứng thật là scene riêng
## trong thế giới (`board/hieu_ung/`).

const TOC_XOAY := 1.6

@export var danh_muc: DanhMucVatPham = null

var _mon := ""
var _hinh: Node3D = null


func _process(delta: float) -> void:
	if _hinh != null:
		rotation.y += delta * TOC_XOAY


## Rỗng = cất đi.
func hien(mon: String) -> void:
	if mon == _mon:
		return
	_mon = mon
	if _hinh != null:
		_hinh.queue_free()
	_hinh = null
	var hinh := danh_muc.tim(mon) if danh_muc != null else null
	if hinh == null or hinh.mo_hinh == null:
		return
	_hinh = hinh.mo_hinh.instantiate() as Node3D
	add_child(_hinh)
