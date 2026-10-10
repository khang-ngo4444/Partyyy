class_name Die
extends Pickable

## Viên xúc xắc cầm được: mặt ngửa do vật lý quyết, chỉ master mô phỏng rồi ghi `value`.
## Màu: con của `Visual` trong die.tscn, tên node = `tint`.

## Trục → mặt (đo từ model D6_A): +X=2 -X=5 +Y=6 -Y=1 +Z=3 -Z=4.
const MAT_THEO_TRUC := [[Vector3.RIGHT, 2], [Vector3.LEFT, 5], [Vector3.UP, 6],
		[Vector3.DOWN, 1], [Vector3.BACK, 3], [Vector3.FORWARD, 4]]

## Nằm yên chừng này giây thì chốt mặt.
const GIAY_NAM_YEN := 0.3

## Tốc độ xoay ngẫu nhiên lúc thả (rad/s).
const XOAY_TOI_THIEU := 8.0
const XOAY_TOI_DA := 16.0

## Màu viên; setter vì Fusion gửi property sau `_ready()`.
@export var tint := "red":
	set(value_):
		tint = value_
		if is_node_ready():
			_build.call_deferred()

## Mặt đang ngửa, 0 = đang lăn. Master ghi.
@export var value: int = 1

var _yen := 0.0

@onready var visual: Node3D = $Visual


func _init() -> void:
	mass = 0.05
	nay = 0.3
	ma_sat = 0.5
	ham_mat_dat = 1.0
	# Hãm xoay để viên không lăn mãi.
	ham_xoay = 1.5


func _ready() -> void:
	super()
	add_to_group("die")
	_build()


func _khi_bat_dau_bay() -> void:
	value = 0
	_yen = 0.0
	var truc := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	angular_velocity = truc * randf_range(XOAY_TOI_THIEU, XOAY_TOI_DA)


func _khi_bay_vat_ly(delta: float) -> void:
	if value != 0:
		return
	if linear_velocity.length() < 0.05 and angular_velocity.length() < 0.1:
		_yen += delta
		if _yen > GIAY_NAM_YEN:
			value = mat_ngua()
	else:
		_yen = 0.0


## Mặt ngửa: trục nào chỉ lên cao nhất.
func mat_ngua() -> int:
	var cao_nhat := -2.0
	var mat := 6
	for cap in MAT_THEO_TRUC:
		var y: float = (global_transform.basis * (cap[0] as Vector3)).y
		if y > cao_nhat:
			cao_nhat = y
			mat = cap[1]
	return mat


func _build() -> void:
	for c: Node3D in visual.get_children():
		c.visible = c.name == tint
