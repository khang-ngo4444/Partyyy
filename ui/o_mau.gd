class_name OMau
extends Button

## Ô màu bấm được; StyleBox `resource_local_to_scene` nên mỗi ô một bản.

const VIEN_THUONG := 1
const VIEN_CHON := 4
const MAU_VIEN_THUONG := Color(1, 1, 1, 0.32)


func dat(mau: Color, dang_chon := false) -> void:
	var kieu := get_theme_stylebox("normal") as StyleBoxFlat
	kieu.bg_color = mau
	kieu.set_border_width_all(VIEN_CHON if dang_chon else VIEN_THUONG)
	kieu.border_color = Color.WHITE if dang_chon else MAU_VIEN_THUONG
