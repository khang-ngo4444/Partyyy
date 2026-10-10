class_name HaiXucXac
extends Node3D

## Hai hột xí ngầu: hai `XucXac3D` (đặt cạnh nhau trong scene) tung cùng lúc, một nhãn chung
## hiện tổng. Hai mặt đều lấy từ RPC của người tung nên mọi máy thấy giống nhau.

var _ten := ""
var _chu_tong := ""

@onready var _trai: XucXac3D = $ViTriTrai/XucXac3D
@onready var _phai: XucXac3D = $ViTriPhai/XucXac3D
@onready var _tong: Label3D = $Tong


func _ready() -> void:
	_phai.da_dung.connect(func(_v: int) -> void:
		_tong.text = "%s\nTUNG ĐƯỢC  %s" % [_ten, _chu_tong])


func tung(so_1: int, so_2: int, ten_nguoi: String) -> void:
	so_1 = clampi(so_1, 1, 6)
	so_2 = clampi(so_2, 1, 6)
	_ten = ten_nguoi
	_chu_tong = "%d + %d = %d" % [so_1, so_2, so_1 + so_2]
	_tong.text = "%s\nĐANG TUNG..." % ten_nguoi
	_tong.visible = true
	_trai.tung(so_1, ten_nguoi)
	await _phai.tung(so_2, ten_nguoi)
	if is_inside_tree():
		_tong.visible = false
