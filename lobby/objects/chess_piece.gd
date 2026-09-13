class_name ChessPiece
extends Pickable

## Quan co. Nhat / nem / vat ly that ke thua tu Pickable — o day chi dung hinh va hinh va cham.
##
## Ba bộ quân khác nhau ở cách vẽ:
##   Cờ vua   — model glTF thật (asset/chess_set)
##   Cờ tướng — trụ dẹt + chữ Hán nổi trên mặt
##   Caro     — trụ dẹt trơn

enum Game { CHESS, XIANGQI, CARO }
enum Kind { PAWN, ROOK, BISHOP, KNIGHT, QUEEN, KING }
enum XKind { SOLDIER, CANNON, CHARIOT, HORSE, ELEPHANT, ADVISOR, GENERAL }

## Đỏ và đen như bàn cờ tướng thật, không dùng trắng/đen như cờ vua.
const XIANGQI_DISC := [Color("f0e3c8"), Color("f0e3c8")]
const XIANGQI_INK := [Color("b8322c"), Color("1c1a18")]

## Chữ trên quân khác nhau giữa hai bên — đúng như bàn cờ tướng thật.
const XIANGQI_GLYPHS := [
	["兵", "炮", "俥", "傌", "相", "仕", "帥"],
	["卒", "砲", "車", "馬", "象", "士", "將"],
]

## Quân cờ vua: mỗi quân một scene trong lobby/objects/chess/ — cỡ và hướng mặt chỉnh ngay trong
## scene đó. Thứ tự: trắng tốt, xe, tượng, mã, hậu, vua; rồi đen cùng thứ tự. Gán trong Inspector
## của chess_piece.tscn.
@export var chess_scenes: Array[PackedScene] = []

@export var game: int = Game.CHESS:
	set(value):
		game = value
		_queue_build()

@export var kind: int = Kind.PAWN:
	set(value):
		kind = value
		_queue_build()

## Quân caro: đường kính thật, tính bằng mét (không nhân piece_scale).
@export var caro_radius := 0.085

## 0 = trắng / đỏ, 1 = đen.
@export var side: int = 0:
	set(value):
		side = value
		_queue_build()

## Chỉ còn dùng cho cờ tướng — số liệu _build_xiangqi() viết theo đơn vị nhỏ nên phải nhân.
@export var piece_scale := 1.65

@onready var visual: Node3D = $Visual

var _build_queued := false


func _init() -> void:
	mass = 0.3
	nay = 0.15
	ma_sat = 0.7
	ham_mat_dat = 1.5
	ham_xoay = 0.8


func _ready() -> void:
	super()
	_build()


## Fusion gửi từng property về RIÊNG LẺ và KHÔNG đảm bảo thứ tự. Dựng ngay trong setter thì
## có lúc `kind` đã là quân cờ tướng mà `game` vẫn còn là cờ vua — và nó đi tiện một quân
## không tồn tại.
##
## Gom lại: hoãn tới cuối frame, lúc đó cả ba giá trị đã về đủ. Tiện thể bớt được hai lần
## dựng lại thừa.
func _queue_build() -> void:
	if _build_queued or not is_node_ready():
		return
	_build_queued = true
	_deferred_build.call_deferred()


func _deferred_build() -> void:
	_build_queued = false
	_build()


func _build() -> void:
	for c in visual.get_children():
		c.queue_free()
	match game:
		Game.XIANGQI:
			visual.scale = Vector3.ONE * piece_scale
			_build_xiangqi()
			_dat_hinh(_tru(0.105 * piece_scale, 0.055 * piece_scale), Vector3(0.0, 0.028 * piece_scale, 0.0))
		Game.CARO:
			visual.scale = Vector3.ONE
			_build_caro()
			_dat_hinh(_tru(caro_radius, 0.09), Vector3(0.0, 0.045, 0.0))
		_:
			visual.scale = Vector3.ONE
			_build_chess()
			# Model co vua hinh la: hinh loi bam theo luoi de quan nga, lan dung dang.
			_dat_hinh(_hinh_loi_tu_luoi(visual, "%d|%d" % [kind, side]))


func _tru(ban_kinh: float, cao: float) -> CylinderShape3D:
	var tru := CylinderShape3D.new()
	tru.radius = ban_kinh
	tru.height = cao
	return tru


## Quân caro: đúng một trụ dẹt. Không cần model — ở khoảng cách xa thì khối trơn màu tương
## phản còn dễ đọc hơn model chi tiết.
func _build_caro() -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = caro_radius
	cm.bottom_radius = caro_radius
	cm.height = 0.09
	m.mesh = cm
	m.material_override = _mat(Color("f2efe6") if side % 2 == 0 else Color("1a1a1e"))
	m.position = Vector3(0.0, 0.045, 0.0)
	visual.add_child(m)


func _build_chess() -> void:
	var i := side % 2 * 6 + kind
	if kind < 0 or kind > Kind.KING or i >= chess_scenes.size():
		return                      # giá trị chưa khớp nhau, chờ lần dựng sau
	visual.add_child(chess_scenes[i].instantiate())


## Quân cờ tướng: trụ dẹt + chữ Hán nổi nằm ngửa trên mặt. Font mặc định của Godot vẽ
## được chữ Hán nên không cần tải font riêng — đã kiểm.
func _build_xiangqi() -> void:
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.105
	cm.bottom_radius = 0.105
	cm.height = 0.055
	disc.mesh = cm
	disc.material_override = _mat(XIANGQI_DISC[side % 2])
	disc.position = Vector3(0.0, 0.028, 0.0)
	visual.add_child(disc)

	var glyphs: Array = XIANGQI_GLYPHS[side % 2]
	var t := TextMesh.new()
	t.text = glyphs[kind % glyphs.size()]
	t.font_size = 64
	t.pixel_size = 0.0022
	t.depth = 0.012
	var label := MeshInstance3D.new()
	label.mesh = t
	label.material_override = _mat(XIANGQI_INK[side % 2])
	# Nằm ngửa lên trời, đọc được khi đứng cạnh bàn.
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	label.position = Vector3(0.0, 0.058, 0.0)
	visual.add_child(label)


func _mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	# Bảo hiểm cho hướng mặt của lưới tự sinh: sai chiều thì vẫn nhìn thấy, không mất hình.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
