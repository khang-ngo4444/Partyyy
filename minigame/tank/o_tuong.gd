class_name OTuong
extends Node2D

## MỘT ô tường trong đấu trường Tank.
##
## Hình nằm trong `o_tuong.tscn`. Script này **không dựng node nào** — nó chỉ đổi màu theo
## loại, y như `o_ban.gd` làm với vật liệu ô bàn cờ.
##
## Sửa bản đồ = mở `ban_do_tank.tscn` lên kéo ô trong editor, không đụng tới code.

## Gạch vỡ được khi trúng đạn, thép thì không. Đó là toàn bộ khác biệt giữa hai loại.
enum Loai { GACH, THEP }

@export var loai: Loai = Loai.GACH:
	set(value):
		loai = value
		if is_node_ready():
			_ve()

## Hai màu theo đúng thứ tự enum `Loai`, đặt sẵn trong `o_tuong.tscn`. Mọi instance thừa
## hưởng mảng này nên từng ô chỉ cần đặt `loai`.
@export var mau: Array[Color] = []

@onready var _mau: ColorRect = $Mau


func _ready() -> void:
	_ve()


func _ve() -> void:
	if loai >= 0 and loai < mau.size():
		_mau.color = mau[loai]
