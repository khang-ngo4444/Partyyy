class_name Die
extends Pickable

## Vien xuc xac CAM DUOC. Nhat len, nem ra, no lan bang vat ly that roi nam mot mat.
##
## Mat ngua do VAT LY quyet, khong ai chon truoc. Chi master mo phong nen moi may thay dung mot
## ket qua: vi tri va goc xoay deu tu master replicate sang. Master doc mat ngua luc vien nam yen
## roi ghi vao `value` (replicate) cho ban xuc xac cong diem.

const MODEL := "res://asset/kaykit_boardgame/Models/D6_A_%s.gltf"
## Model canh 0.75 don vi. Nhan so nay ra vien 0.14 m — cam vua tay, dung doc duoc.
const DIE_SCALE := 0.19
const CANH_MODEL := 0.75

## Truc cua vien nao chi len troi thi mat do ngua. DO TU HINH HOC CHAM cua D6_A, khong doan:
##     +X=2  -X=5  +Y=6  -Y=1  +Z=3  -Z=4
## Tong 21 nhu xuc xac that, ba cap mat doi nhau deu cong bang 7.
const MAT_THEO_TRUC := [[Vector3.RIGHT, 2], [Vector3.LEFT, 5], [Vector3.UP, 6],
		[Vector3.DOWN, 1], [Vector3.BACK, 3], [Vector3.FORWARD, 4]]
## Nam yen chung nay giay thi chot mat.
const GIAY_NAM_YEN := 0.3
## Luc tha, master cho vien xoay ngau nhien trong khoang nay (rad/s) — moi lan gieo mot ket qua.
const XOAY_TOI_THIEU := 8.0
const XOAY_TOI_DA := 16.0

## Mau vien. Co setter vi Fusion gui property ve SAU `_ready()`.
@export var tint := "red":
	set(value_):
		tint = value_
		if is_node_ready():
			_build.call_deferred()

## Mat dang ngua, 0 = dang lan. Master ghi; may khac nhan qua replication.
@export var value: int = 1

var _yen := 0.0


func _init() -> void:
	mass = 0.05
	nay = 0.3
	ma_sat = 0.5
	ham_mat_dat = 1.0
	# Ham xoay du lon de vien khong lan mai.
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


## Mat dang ngua theo goc xoay hien tai: truc nao cua vien chi len cao nhat.
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
	for c in get_children():
		if c is Node3D and not (c is FusionSharedReplicator) and not (c is CollisionShape3D):
			c.queue_free()
	var packed := load(MODEL % tint) as PackedScene
	if packed == null:
		push_error("Die: khong nap duoc " + MODEL % tint)
		return
	var inst := packed.instantiate() as Node3D
	inst.scale = Vector3.ONE * DIE_SCALE
	add_child(inst)
	var hop := BoxShape3D.new()
	hop.size = Vector3.ONE * CANH_MODEL * DIE_SCALE
	_dat_hinh(hop)
