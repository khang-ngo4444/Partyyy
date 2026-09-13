class_name Card
extends Pickable

## La bai. Co than vat ly nhu moi Pickable nhung LUON KHOA (`dinh_co_dinh`): bai do nha cai dat
## vao o, khong ai cam len duoc — de vat ly dong thi bai truot khoi o, bang diem doc sai.
##
## KHÔNG CÓ LUẬT CHƠI NÀO. Cùng lý do với bàn cờ: bàn bài không luật thì chơi được xì dách,
## tiến lên, phỏm, hay bất cứ trò gì nhóm bạn tự nghĩ ra. Có luật thì chỉ chơi được một trò,
## mà lại phải cãi nhau xem luật nào đúng.

const SUITS := ["clubs", "diamonds", "hearts", "spades"]
const RANKS := ["A", "02", "03", "04", "05", "06", "07", "08", "09", "10", "J", "Q", "K"]
const DECK_SIZE := 52

## Cạnh lá bài. Ảnh Kenney là sprite VUÔNG 64×64 (viền lá bài vẽ sẵn bên trong), nên mặt
## dán cũng phải vuông — kéo thành hình chữ nhật là méo hình.
##
## PHẢI REPLICATE: bài chung to hơn bài riêng, mà master đặt cỡ. Không replicate thì chỉ máy
## master thấy lá to, mọi người khác vẫn thấy cỡ mặc định.
@export var card_size := 0.26:
	set(value):
		card_size = value
		_queue_build()
@export var thickness := 0.012

## Bàn nào rút ra lá này. Hai bàn hai bộ bài riêng — bài rút ở bàn poker không được biến
## mất khỏi bộ của bàn xì dách.
@export var deck_id: int = 0

@export var card_index: int = 0:
	set(value):
		card_index = value
		_queue_build()

## Bài ÚP. Nhà cái giấu một lá cho tới lúc lật — nên phải replicate, không thì mỗi máy
## thấy một kiểu.
@export var face_down: bool = false:
	set(value):
		face_down = value
		_queue_build()

@onready var visual: Node3D = $Visual
@onready var _than: MeshInstance3D = $Visual/Than
@onready var _tren: MeshInstance3D = $Visual/Tren
@onready var _duoi: MeshInstance3D = $Visual/Duoi

## Ảnh bài: card_deck.tres, gán trong Inspector của card.tscn.
@export var bo_bai: CardDeck

var _build_queued := false
## Lá này có được LẬT RIÊNG cho người ở máy NÀY xem không.
##
## Đây là chỗ ĐẦU TIÊN trong cả dự án mà hai máy hiển thị khác nhau. Bắt buộc phải thế:
## poker không giấu bài riêng thì cược mất hết ý nghĩa. Trạng thái MẠNG vẫn là "úp" cho mọi
## người — chỉ riêng cái hình vẽ ra là khác. Không ai ghi gì lên mạng ở đây cả.
##
## Lưu ý thật thà: `card_index` vẫn replicate tới mọi máy, nên ai sửa client vẫn đọc được bài
## người khác. Chơi với bạn bè thì không đáng bận tâm; giấu thật phải để master không gửi
## `card_index` cho người ngoài, và Fusion không có kiểu gửi-riêng-từng-người.
var _lo_cho_toi := false


func _init() -> void:
	dinh_co_dinh = true
	mass = 0.005


func _ready() -> void:
	super()
	add_to_group("card")
	# Bài do nhà cái chia, KHÔNG cầm lên được. Rút khỏi nhóm "pickable" thì vòng ngắm của
	# người chơi không thấy nó nữa — chặn ở gốc, không phải chặn ở chỗ bấm.
	remove_from_group("pickable")
	_build()


## Fusion gửi từng property riêng lẻ, không đảm bảo thứ tự (xem mục 1ab). Hoãn tới cuối
## frame thì lúc đó giá trị đã về đủ.
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


## Bản static: cột hiển thị bài chung cần đọc tên từ chỉ số mà không có object Card trong tay.
static func ten_cua(idx: int) -> String:
	if idx < 0 or idx >= DECK_SIZE:
		return "joker"
	@warning_ignore("integer_division")
	return "%s_%s" % [SUITS[idx / 13], RANKS[idx % 13]]


## 0 = A, 1..8 = 2..9, 9 = 10, 10 = J, 11 = Q, 12 = K
func rank() -> int:
	return card_index % 13


## 0 = chuồn, 1 = rô, 2 = cơ, 3 = bích
func suit() -> int:
	@warning_ignore("integer_division")
	return card_index / 13


## Người ở máy này có đọc được lá này không. Ô đặt bài dùng nó để chấm điểm — chủ bài thấy
## bộ của mình, người khác không thấy gì.
func hien_voi_toi() -> bool:
	return not face_down or _lo_cho_toi


## Bàn bài gọi: lật hình lên cho riêng người ở máy này.
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


## Một mặt bài: node `Tren`/`Duoi` trong card.tscn — vị trí, hướng, vật liệu đặt trong scene.
## Code chỉ chọn ảnh theo lá (card_index / úp) và cỡ theo `card_size` (master đặt, replicate).
func _mat_face(m: MeshInstance3D, tex: Texture2D) -> void:
	(m.mesh as QuadMesh).size = Vector2(card_size, card_size)
	(m.material_override as StandardMaterial3D).albedo_texture = tex
