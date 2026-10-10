class_name ODiem
extends PanelContainer

## Một ô trong dải điểm: hạng, tên, điểm, viền màu nhân vật.

var _vien: StyleBoxFlat = null

@onready var _ten: Label = $Cot/Ten
@onready var _diem: Label = $Cot/Diem


func dat(hang: int, ten: String, mau: Color, chu: String, la_toi: bool) -> void:
	if _vien == null:
		# Nhân bản StyleBox để mỗi ô một màu viền.
		_vien = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
		add_theme_stylebox_override("panel", _vien)
	_vien.border_color = mau
	_vien.border_width_top = 2 if la_toi else 0
	_ten.text = "%d. %s" % [hang, ten]
	_diem.text = chu
	_diem.modulate = Color(1.0, 0.86, 0.3) if hang == 1 else Color.WHITE
