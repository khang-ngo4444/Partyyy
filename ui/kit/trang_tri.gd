extends Control

## Trang trí nền kiểu ảnh mẫu: sao 4 cánh và chấm màu bay lên, đung đưa, lấp lánh.
## Vẽ thủ công, không texture. Tắt chuyển động khi UINav.giam_chuyen_dong.

const BIEN_DO_DUNG_DUA := 14.0
const TAN_SO_DUNG_DUA := 0.7
const TAN_SO_LAP_LANH := 2.2
## Hạt mờ dần trong khoảng này ở đỉnh và đáy (tỉ lệ chiều cao), không bật ra đột ngột.
const VUNG_MO := 0.12

@export var so_sao := 14
@export var so_cham := 12
@export var mau_sao := Color(1, 1, 1, 0.95)
@export var mau_cham: Array[Color] = [
	Color("FFD54F", 0.85), Color("F78FA7", 0.8), Color("4FC3F7", 0.8), Color("FFFFFF", 0.75),
]

var _hat: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in so_sao:
		_hat.append(_tao_hat(rng, true, rng.randf_range(8, 22), mau_sao))
	for i in so_cham:
		_hat.append(_tao_hat(rng, false, rng.randf_range(3, 8), mau_cham[i % mau_cham.size()]))


func _tao_hat(rng: RandomNumberGenerator, la_sao: bool, co: float, mau: Color) -> Dictionary:
	return {
		"x": rng.randf(), "y": rng.randf(), "co": co, "pha": rng.randf() * TAU, "mau": mau, "la_sao": la_sao,
		"toc_do": rng.randf_range(0.015, 0.05),
	}


func _process(delta: float) -> void:
	if not is_visible_in_tree() or UINav.giam_chuyen_dong:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	for hat: Dictionary in _hat:
		# Bay lên rồi quay lại từ đáy.
		var y := fposmod(float(hat.y) - _t * float(hat.toc_do), 1.0)
		var vi_tri := Vector2(float(hat.x) * size.x + sin(_t * TAN_SO_DUNG_DUA + float(hat.pha)) * BIEN_DO_DUNG_DUA, y * size.y)
		var mau: Color = hat.mau
		mau.a *= minf(smoothstep(0.0, VUNG_MO, y), smoothstep(0.0, VUNG_MO, 1.0 - y))
		var co := float(hat.co) * (0.75 + 0.25 * sin(_t * TAN_SO_LAP_LANH + float(hat.pha)))
		if hat.la_sao:
			_ve_sao(vi_tri, co, mau)
		else:
			draw_circle(vi_tri, co, mau, true, -1.0, true)


func _ve_sao(p: Vector2, r: float, mau: Color) -> void:
	var diem := PackedVector2Array()
	for i in 8:
		var goc := i * PI / 4.0
		var rr := r if i % 2 == 0 else r * 0.28
		diem.append(p + Vector2(cos(goc), sin(goc)) * rr)
	draw_colored_polygon(diem, mau)
