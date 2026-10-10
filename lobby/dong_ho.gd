extends Node3D

## Một mặt đồng hồ trên tháp; kim chạy theo giờ máy.

const CAP_NHAT := 0.25

var _acc := CAP_NHAT

@onready var _kim_gio: Node3D = $KimGio
@onready var _kim_phut: Node3D = $KimPhut


func _process(delta: float) -> void:
	_acc += delta
	if _acc < CAP_NHAT:
		return
	_acc = fmod(_acc, CAP_NHAT)
	var now := Time.get_time_dict_from_system()
	var phut: float = now.minute + now.second / 60.0
	var gio := fmod(now.hour, 12.0) + phut / 60.0
	# Nhìn từ trước mặt (+Z), quay dương là ngược kim — nên đổi dấu.
	_kim_gio.rotation.z = -TAU * gio / 12.0
	_kim_phut.rotation.z = -TAU * phut / 60.0
