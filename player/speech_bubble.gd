class_name SpeechBubble
extends Node3D

## Bong bóng chữ trên đầu nhân vật.
##
## Thuần hiển thị, mỗi máy tự vẽ. Tin chat đã tới qua RPC ở `Chat` rồi — bong bóng không gửi
## thêm byte nào, cũng không replicate gì.

## Hiện đủ bấy nhiêu giây rồi mới mờ đi.
const GIU := 6.0
const MO := 0.5
## Mép DƯỚI bong bóng nằm ở độ cao này — ngay trên bảng tên (2.05 m).
const DAY := 2.3
const PIXEL := 0.0032
const CO_CHU := 48
## Quá bề ngang này thì xuống dòng. Tính bằng pixel của Label3D, ra khoảng 1.6 m.
const RONG_TOI_DA := 500.0
## Đệm quanh chữ, cũng tính bằng pixel.
const DEM := 22.0

var _chu: Label3D
var _nen: MeshInstance3D
var _mat: StandardMaterial3D
var _tween: Tween


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_nen = MeshInstance3D.new()
	_nen.mesh = QuadMesh.new()
	_nen.material_override = _mat
	_nen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_nen)

	_chu = Label3D.new()
	_chu.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_chu.pixel_size = PIXEL
	_chu.font_size = CO_CHU
	_chu.outline_size = 0
	_chu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chu.width = RONG_TOI_DA
	# Nền và chữ cùng là mặt phẳng quay về camera, trùng chỗ nhau. Không có thứ tự vẽ thì
	# chúng giành nhau từng pixel (nhấp nháy). Cả hai là lớp trong suốt nên xếp được bằng
	# `render_priority`: nền trước, chữ sau.
	_chu.render_priority = 1
	add_child(_chu)
	visible = false


func noi(text: String) -> void:
	_chu.text = text
	var co := ThemeDB.fallback_font.get_multiline_string_size(
			text, HORIZONTAL_ALIGNMENT_CENTER, RONG_TOI_DA, CO_CHU)
	var kich := (co + Vector2(DEM, DEM) * 2.0) * PIXEL
	(_nen.mesh as QuadMesh).size = kich
	# Neo MÉP DƯỚI chứ không neo tâm: tin ba dòng mà neo tâm thì nửa dưới đè lên bảng tên.
	position.y = DAY + kich.y * 0.5
	_dat_alpha(1.0)
	visible = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(GIU)
	_tween.tween_method(_dat_alpha, 1.0, 0.0, MO)
	_tween.tween_callback(hide)


func _dat_alpha(a: float) -> void:
	_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.92 * a)
	_chu.modulate = Color(0.1, 0.1, 0.12, a)
