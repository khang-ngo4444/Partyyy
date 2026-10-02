class_name ODiem
extends PanelContainer

## MỘT ô trong dải điểm ở đáy màn hình minigame: hạng · tên · điểm, viền dưới màu nhân vật.
##
## Hình ô nằm trong `o_diem.tscn`; `QuanTroMiniGame` chỉ `instantiate()` mỗi người một ô (số người
## chỉ biết lúc vào ván) rồi gọi `dat()`.

@onready var _ten: Label = $Cot/Ten
@onready var _diem: Label = $Cot/Diem
var _vien: StyleBoxFlat = null


func dat(hang: int, ten: String, mau: Color, chu: String, la_toi: bool) -> void:
	if _vien == null:
		# Mỗi ô một màu viền: nhân bản StyleBox gốc một lần, không sửa bản dùng chung.
		_vien = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
		add_theme_stylebox_override("panel", _vien)
	_vien.border_color = mau
	_vien.border_width_top = 2 if la_toi else 0
	_ten.text = "%d. %s" % [hang, ten]
	_diem.text = chu
	_diem.modulate = Color(1.0, 0.86, 0.3) if hang == 1 else Color.WHITE
