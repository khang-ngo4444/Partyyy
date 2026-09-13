class_name DiceTable
extends Node3D

## Bàn gieo xúc xắc. CHỈ là cái bàn và một bảng cộng điểm.
##
## Không có nút, không có hoạt hình gieo. Hai viên xúc xắc là vật CẦM ĐƯỢC (`Die`) — nhặt
## lên, ném ra, chúng tự lộn nhào rồi nằm một mặt. Bàn chỉ ngồi đó cộng hai viên đang nằm
## trên nó.
##
## Đọc theo VỊ TRÍ, giống `CardSpot`: vị trí và mặt của xúc xắc đã replicate sẵn nên máy nào
## cũng cộng ra cùng một số. Không tốn thêm một byte mạng nào.

@export var table_radius := 0.9
@export var table_height := 0.75
## Đọc lại 4 lần/giây. Đây là bảng số cho người đọc, không phải vật lý.
const REFRESH := 0.25

@onready var board: Label3D = $Result

var _acc := 0.0
var _last := ""


func _ready() -> void:
	add_to_group("dice_table")
	_build_table()
	board.text = "NEM XUC XAC LEN BAN"


## Chỗ đặt viên xúc xắc thứ i lúc mới sinh ra.
func slot(i: int) -> Vector3:
	var a := TAU * i / 2.0
	return global_position + Vector3(sin(a) * table_radius * 0.4, table_height + 0.08,
			cos(a) * table_radius * 0.4)


func _process(delta: float) -> void:
	_acc += delta
	if _acc < REFRESH:
		return
	_acc = 0.0
	var txt := _doc()
	if txt != _last:
		_last = txt
		board.text = txt


## Xúc xắc đang NẰM trên mặt bàn này. Viên đang cầm trên tay không tính — không lọc thì đi
## ngang qua bàn là điểm nhảy loạn.
func _doc() -> String:
	var tong := 0
	var n := 0
	for d in get_tree().get_nodes_in_group("die"):
		var die := d as Die
		# value 0 = vien dang lan, chua co mat ngua.
		if die == null or die.holder_id != 0 or die.value == 0:
			continue
		var v := die.global_position - global_position
		if Vector2(v.x, v.z).length() <= table_radius and absf(v.y - table_height) < 0.5:
			tong += die.value
			n += 1
	if n == 0:
		return "NEM XUC XAC LEN BAN"
	if n == 1:
		return "%d  (moi co 1 vien tren ban)" % tong
	return "%d" % tong


func _build_table() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = table_radius
	cs.height = table_height
	shape.shape = cs
	shape.position.y = table_height * 0.5
	body.add_child(shape)
	add_child(body)

	var top := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = table_radius
	cm.bottom_radius = table_radius * 0.85
	cm.height = table_height
	top.mesh = cm
	top.material_override = _mat(Color("2f5d3f"))
	top.position.y = table_height * 0.5
	add_child(top)

	# Vành gỗ quanh mép: xúc xắc ném hụt thì rơi ra sàn, có vành mới ra dáng bàn gieo.
	var vien := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = table_radius - 0.04
	tm.outer_radius = table_radius + 0.04
	vien.mesh = tm
	vien.material_override = _mat(Color("6b4a2f"))
	vien.position.y = table_height
	add_child(vien)


func _mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	return mat
