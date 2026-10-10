class_name ChessPiece
extends Pickable

## Quân cờ (kế thừa Pickable), ở đây chỉ dựng hình và hình va chạm.
## Cờ vua: model glTF; cờ tướng: trụ dẹt + chữ Hán; caro: trụ dẹt trơn.

enum Game { CHESS, XIANGQI, CARO }
enum Kind { PAWN, ROOK, BISHOP, KNIGHT, QUEEN, KING }
enum XKind { SOLDIER, CANNON, CHARIOT, HORSE, ELEPHANT, ADVISOR, GENERAL }

## Chạm mặt và chậm hơn ngưỡng này thì gióng về ô gần nhất.
const NGUONG_DUNG := 0.35
const NGUONG_XOAY := 1.2

## Mỗi quân cờ vua một scene: trắng tốt, xe, tượng, mã, hậu, vua; rồi đen cùng thứ tự.
@export var chess_scenes: Array[PackedScene] = []
@export var quan_tuong_scene: PackedScene
## Quân caro: [trắng, đen].
@export var caro_scenes: Array[PackedScene] = []
@export var game: int = Game.CHESS:
	set(value):
		game = value
		_queue_build()
@export var kind: int = Kind.PAWN:
	set(value):
		kind = value
		_queue_build()

## Đường kính quân caro, mét.
@export var caro_radius := 0.085

## 0 = trắng / đỏ, 1 = đen.
@export var side: int = 0:
	set(value):
		side = value
		_queue_build()

## Tỉ lệ cho cờ tướng (quan_tuong.tscn dựng theo đơn vị nhỏ).
@export var piece_scale := 1.65

var _build_queued := false

@onready var visual: Node3D = $Visual


func _init() -> void:
	mass = 0.3
	nay = 0.15
	ma_sat = 0.7
	ham_mat_dat = 1.5
	ham_xoay = 0.8


func _ready() -> void:
	super()
	_build()


## Master gióng quân về đúng ô sau khi nằm yên hẳn; kéo mềm bằng `lerp` để không giật.
func _khi_bay_vat_ly(delta: float) -> void:
	if linear_velocity.length() > NGUONG_DUNG or angular_velocity.length() > NGUONG_XOAY:
		return
	if get_contact_count() == 0:
		return  # đang lơ lửng
	var ban := _ban_cua_minh()
	if ban == null:
		return

	var dich := ban.nearest_point(global_position)
	dich.y = global_position.y  # độ cao để vật lý lo, chỉ gióng XZ
	var k := clampf(delta * 10.0, 0.0, 1.0)
	var moi := global_position.lerp(dich, k)

	# Dựng thẳng: quân tròn ngã ra là lăn mãi.
	var huong := global_basis.get_rotation_quaternion()
	var thang := Quaternion(Vector3.UP, global_rotation.y)
	global_transform = Transform3D(Basis(huong.slerp(thang, k)), moi)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


## Bàn đúng loại: quân caro về bàn caro, cờ vua/tướng về bàn cờ.
func _ban_cua_minh() -> ChessBoard:
	for b: ChessBoard in get_tree().get_nodes_in_group("snap_surface"):
		if (b.mode == ChessBoard.Mode.CARO) != (game == Game.CARO):
			continue
		if b.contains(global_position):
			return b
	return null


## Hoãn dựng tới cuối frame: Fusion gửi từng property riêng lẻ, không theo thứ tự.
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
			var q := quan_tuong_scene.instantiate() as QuanTuong
			visual.add_child(q)
			q.dat(side, kind)
			_dat_hinh(_tru(0.105 * piece_scale, 0.055 * piece_scale), Vector3(0.0, 0.028 * piece_scale, 0.0))
		Game.CARO:
			visual.scale = Vector3.ONE
			visual.add_child(caro_scenes[side % 2].instantiate())
			_dat_hinh(_tru(caro_radius, 0.09), Vector3(0.0, 0.045, 0.0))
		_:
			visual.scale = Vector3.ONE
			_build_chess()
			# Model cờ vua: hình lồi theo lưới để quân ngã đúng dáng.
			_dat_hinh(_hinh_loi_tu_luoi(visual, "%d|%d" % [kind, side]))


func _tru(ban_kinh: float, cao: float) -> CylinderShape3D:
	var tru := CylinderShape3D.new()
	tru.radius = ban_kinh
	tru.height = cao
	return tru


func _build_chess() -> void:
	var i := side % 2 * 6 + kind
	if kind < 0 or kind > Kind.KING or i >= chess_scenes.size():
		return  # giá trị chưa khớp, chờ lần dựng sau
	visual.add_child(chess_scenes[i].instantiate())
