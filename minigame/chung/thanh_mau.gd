class_name ThanhMau
extends CanvasLayer

## MÁU + thanh máu, dùng chung cho mọi minigame không giết người trong một lần chạm.
##
## Trò nào cần thì kéo `thanh_mau.tscn` vào `.tscn` của nó rồi gọi `mo()` / `tru()` / `het()`.
## Không trò nào phải tự nhớ bề rộng thanh, tự kẹp tỉ lệ, hay tự đặt lại máu đầu ván nữa.
##
## ## Vì sao tách ra đúng lúc này
##
## Hai trò đầu (Searing Spotlights, Magma & Mages) mỗi trò tự chép: 5 biến giống nhau trong
## script và một khối `CanvasLayer + ColorRect + ColorRect` giống nhau trong `.tscn`. Chép hai
## lần thì rẻ hơn dựng một tầng mới, nên lúc đó để vậy và ghi `ponytail:` hẹn trò thứ ba.
##
## Acidic Atoll là trò thứ ba. Giữ lời hẹn.
##
## ## Thanh máu PHẢI luôn hiện
##
## Ở Spotlights, lúc tối hẳn người chơi không thấy nhân vật mình đâu — thanh máu là tín hiệu DUY
## NHẤT báo "đang bị nướng, chạy đi". Nên nó là một phần của luật chơi, không phải đồ trang trí.

## Máu đầy là bao nhiêu. Trò đặt trong `.tscn` của nó.
@export var toi_da := 100.0

var mau := 0.0

@onready var _muc: ColorRect = $Khung/Muc
var _rong := 0.0


func _ready() -> void:
	_rong = _muc.size.x
	visible = false


## Mở thanh và nạp đầy máu. Gọi trong `_dung_san()`.
func mo() -> void:
	mau = toi_da
	visible = true
	_ve()


## Đóng thanh. Gọi trong `dung_som()` — không đóng thì thanh máu còn treo giữa phòng chờ.
func dong() -> void:
	visible = false


## Trừ máu. `moi_giay` là tốc trừ, hàm tự nhân với `delta` của khung hình này.
func tru(moi_giay: float, delta: float) -> void:
	mau = maxf(mau - moi_giay * delta, 0.0)
	_ve()


func het() -> bool:
	return mau <= 0.0


func _ve() -> void:
	_muc.size.x = _rong * clampf(mau / toi_da, 0.0, 1.0)
