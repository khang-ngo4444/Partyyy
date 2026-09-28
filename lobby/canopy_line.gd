@tool
extends Path3D

## Canopy Line — tàu lượn chạy vòng trong nhà kính (sheet A-201 §1.4).
## Mô phỏng thuần hình: không vật lý, không va chạm, không đồng bộ mạng. Mọi máy lấy vị trí
## xe từ ĐỒNG HỒ HỆ THỐNG nên ai cũng thấy xe ở gần đúng một chỗ mà không cần gửi gì.
##
## Điểm lấy từ tài liệu, NHƯNG đã sửa những chỗ đường ray theo đúng số của tài liệu sẽ đâm vào
## tháp hoặc thấp hơn luật của chính tài liệu (>= 2.6 m trên sàn đi được) — kiểm bằng cách lấy mẫu
## đường cong thật:
##   - Xoắn ốc quanh tháp: tài liệu chỉ có 2 điểm mỗi nửa vòng nên dây cung cắt xuyên thân tháp và
##     ban công. Chia mỗi 1/4 vòng một điểm (P09b, P10b), bán kính đủ né góc ban công vuông.
##   - Gác chuông: vào từ +X ra -X dọc trục (P11 -> P12 -> P12b), cao 11.2 cho lọt dưới quả chuông.
##   - Ga dời về z -11.5; đoạn thấp chạy trong hành lang có rào ở lối đi phía bắc (P15b, P15c, P02).
##   - P14 1.5 -> 3.0, P15 2.6 -> 3.3 (đường cong võng xuống dưới 2.6 giữa hai điểm).
##   - Tay cầm P04 2.5 m chứ không phải 4 m: 4 m đẩy đường cong xuyên kính tường đông.
## PTS / TILT / P04_HANDLE do công cụ bố trí ghi vào; sửa tay thì kiểm lại khoảng hở.

const PTS := [
	Vector3(0.0, 0.4, -11.5),  # P01
	Vector3(0.0, 2.6, -16.3),  # P02
	Vector3(16.2, 4.5, -2.0),  # P03
	Vector3(11.5, 7.0, 11.5),  # P04
	Vector3(-11.5, 9.0, 11.5),  # P05
	Vector3(-16.2, 9.0, -2.0),  # P06
	Vector3(-6.0, 6.0, -13.5),  # P07
	Vector3(2.0, 3.0, -8.0),  # P08
	Vector3(6.5, 4.0, 0.0),  # P09
	Vector3(0.0, 5.0, 5.9),  # P09b
	Vector3(-5.0, 5.6, 0.0),  # P10
	Vector3(0.0, 8.6, -6.0),  # P10b
	Vector3(2.4, 11.2, 0.0),  # P11
	Vector3(0.0, 11.2, 0.0),  # P12
	Vector3(-2.8, 11.2, 0.0),  # P12b
	Vector3(-3.0, 6.5, 9.0),  # P13
	Vector3(-15.6, 3.0, 3.0),  # P14
	Vector3(-7.0, 3.3, -12.0),  # P15
	Vector3(-1.0, 3.4, -5.6),  # P15b
	Vector3(0.0, 1.4, -9.6),  # P15c
]
const TILT := [0, 0, 18, 12, 24, 22, -10, 0, 28, 30, 34, 38, 40, 20, 0, -8, 14, 6, 4, 0]
const P04_HANDLE := 2.5
const LAP_SECONDS := 105.0
const SLEEPER_GAP := 1.2

@export var sleeper_material: Material


func _ready() -> void:
	curve = _build_curve()
	_build_sleepers()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	$Car.progress_ratio = fmod(Time.get_unix_time_from_system(), LAP_SECONDS) / LAP_SECONDS


## Tay cầm mượt kiểu Catmull-Rom (Godot không tự làm mượt khi add_point). Hai ngoại lệ theo tài liệu:
## P04 tay cầm dọc -X để giữ đỉnh phẳng, P08 rút tay vào còn 1.5 m để cú lao giữ độ dốc.
func _build_curve() -> Curve3D:
	var c := Curve3D.new()
	c.bake_interval = 0.2
	c.up_vector_enabled = true
	var n := PTS.size()
	for i in n + 1:           # +1: lặp lại P01 để khép vòng
		var k := i % n
		var out: Vector3 = (PTS[(k + 1) % n] - PTS[k - 1]) / 6.0
		var inn := -out
		if k == 3:
			out = Vector3(-P04_HANDLE, 0.0, 0.0)
			inn = Vector3(P04_HANDLE, 0.0, 0.0)
		elif k == 7:
			inn = inn.normalized() * 1.5
		c.add_point(PTS[k], inn, out)
		c.set_point_tilt(i, deg_to_rad(TILT[k]))
	return c


func _build_sleepers() -> void:
	var old := get_node_or_null("Sleepers")
	if old != null:
		old.free()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.06, 0.16)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	var length := curve.get_baked_length()
	mm.instance_count = int(length / SLEEPER_GAP)
	for i in mm.instance_count:
		mm.set_instance_transform(i, curve.sample_baked_with_rotation(i * SLEEPER_GAP, true, true))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Sleepers"
	mmi.multimesh = mm
	mmi.material_override = sleeper_material
	add_child(mmi)
