class_name ThanhMau
extends CanvasLayer

## Máu + thanh máu dùng chung cho minigame: `mo()`, `tru()`, `het()`.

## Máu đầy (đặt trong scene của trò).
@export var toi_da := 100.0

var mau := 0.0
var _rong := 0.0

@onready var _muc: ColorRect = $Khung/Muc


func _ready() -> void:
	_rong = _muc.size.x
	visible = false


## Mở thanh và nạp đầy máu.
func mo() -> void:
	mau = toi_da
	visible = true
	_ve()


## Đóng thanh (gọi trong `dung_som`).
func dong() -> void:
	visible = false


## Trừ máu theo tốc `moi_giay`.
func tru(moi_giay: float, delta: float) -> void:
	mau = maxf(mau - moi_giay * delta, 0.0)
	_ve()


func het() -> bool:
	return mau <= 0.0


func _ve() -> void:
	_muc.size.x = _rong * clampf(mau / toi_da, 0.0, 1.0)
