extends Control

## Trang trí nền kiểu ảnh mẫu: sao 4 cánh lấp lánh + gạch đứt đoạn trôi nhẹ.
## Vẽ thủ công, không texture. Tắt chuyển động khi UINav.giam_chuyen_dong.

@export var so_sao := 14
@export var so_gach := 8
@export var mau_sao := Color(1, 1, 1, 0.95)
@export var mau_gach := Color("F58A2C")

var _sao: Array = []   # [vị trí tỉ lệ, cỡ, pha]
var _gach: Array = []  # [vị trí tỉ lệ, dài, pha]
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in so_sao:
		_sao.append([Vector2(rng.randf(), rng.randf()), rng.randf_range(8, 22), rng.randf() * TAU])
	for i in so_gach:
		_gach.append([Vector2(rng.randf(), rng.randf()), rng.randf_range(30, 70), rng.randf() * TAU])


func _process(delta: float) -> void:
	if not is_visible_in_tree() or UINav.giam_chuyen_dong:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	for s in _sao:
		var p: Vector2 = s[0] * size
		var k: float = s[1] * (0.75 + 0.25 * sin(_t * 2.2 + s[2]))
		_ve_sao(p, k)
	for g in _gach:
		var p: Vector2 = g[0] * size + Vector2(sin(_t * 0.6 + g[2]) * 6.0, 0)
		var dai: float = g[1]
		for i in 3:
			var x := p.x + i * (dai * 0.45)
			draw_line(Vector2(x, p.y), Vector2(x + dai * 0.28, p.y), mau_gach, 5.0, true)


func _ve_sao(p: Vector2, r: float) -> void:
	var diem := PackedVector2Array()
	for i in 8:
		var goc := i * PI / 4.0
		var rr := r if i % 2 == 0 else r * 0.28
		diem.append(p + Vector2(cos(goc), sin(goc)) * rr)
	draw_colored_polygon(diem, mau_sao)
