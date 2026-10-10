class_name Card
extends Pickable

## Lá bài: Pickable luôn khoá (`dinh_co_dinh`), do nhà cái đặt vào ô. Không có luật chơi.

const SUITS := ["clubs", "diamonds", "hearts", "spades"]
const RANKS := ["A", "02", "03", "04", "05", "06", "07", "08", "09", "10", "J", "Q", "K"]
const DECK_SIZE := 52

## Cạnh lá bài (ảnh vuông 64×64). Replicate vì bài chung to hơn bài riêng.
@export var card_size := 0.26:
	set(value):
		card_size = value
		_queue_build()
@export var thickness := 0.012

## Bàn rút ra lá này; mỗi bàn một bộ bài riêng.
@export var deck_id: int = 0
@export var card_index: int = 0:
	set(value):
		card_index = value
		_queue_build()

## Bài úp; replicate để mọi máy thấy giống nhau.
@export var face_down: bool = false:
	set(value):
		face_down = value
		_queue_build()

## Ảnh bài, gán trong card.tscn.
@export var bo_bai: CardDeck

var _build_queued := false

## Lật riêng cho người ở máy này xem (trạng thái mạng vẫn úp).
## ponytail: `card_index` vẫn replicate tới mọi máy nên client sửa được đọc trộm bài.
var _lo_cho_toi := false

@onready var visual: Node3D = $Visual
@onready var _than: MeshInstance3D = $Visual/Than
@onready var _tren: MeshInstance3D = $Visual/Tren
@onready var _duoi: MeshInstance3D = $Visual/Duoi


func _init() -> void:
	dinh_co_dinh = true
	mass = 0.005


func _ready() -> void:
	super()
	add_to_group("card")
	# Bài nhà cái chia không cầm được: rút khỏi nhóm "pickable".
	remove_from_group("pickable")
	_build()


## Hoãn tới cuối frame: Fusion gửi từng property riêng lẻ, không theo thứ tự.
func _queue_build() -> void:
	if _build_queued or not is_node_ready():
		return
	_build_queued = true
	_deferred_build.call_deferred()


func _deferred_build() -> void:
	_build_queued = false
	_build()


func ten() -> String:
	return ten_cua(card_index)


## Tên lá từ chỉ số, không cần object Card.
static func ten_cua(idx: int) -> String:
	if idx < 0 or idx >= DECK_SIZE:
		return "joker"
	@warning_ignore("integer_division")
	return "%s_%s" % [SUITS[idx / 13], RANKS[idx % 13]]


## 0 = A, 1..8 = 2..9, 9 = 10, 10 = J, 11 = Q, 12 = K.
func rank() -> int:
	return card_index % 13


## 0 = chuồn, 1 = rô, 2 = cơ, 3 = bích.
func suit() -> int:
	@warning_ignore("integer_division")
	return card_index / 13


## Người ở máy này đọc được lá này không.
func hien_voi_toi() -> bool:
	return not face_down or _lo_cho_toi


## Lật hình lên cho riêng người ở máy này.
func lo_cuc_bo(on: bool) -> void:
	if _lo_cho_toi == on:
		return
	_lo_cho_toi = on
	_queue_build()


func _build() -> void:
	(_than.mesh as BoxMesh).size = Vector3(card_size, thickness, card_size)
	var up := face_down and not _lo_cho_toi
	var mat := bo_bai.anh(card_index)
	_mat_face(_tren, bo_bai.lung if up else mat)
	_mat_face(_duoi, mat if up else bo_bai.lung)
	var hop := BoxShape3D.new()
	hop.size = Vector3(card_size, thickness, card_size)
	_dat_hinh(hop)


## Một mặt bài (`Tren`/`Duoi` trong card.tscn): chọn ảnh theo lá và cỡ theo `card_size`.
func _mat_face(m: MeshInstance3D, tex: Texture2D) -> void:
	(m.mesh as QuadMesh).size = Vector2(card_size, card_size)
	(m.material_override as StandardMaterial3D).albedo_texture = tex
