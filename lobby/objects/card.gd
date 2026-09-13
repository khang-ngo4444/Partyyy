class_name Card
extends Pickable

## La bai. Co than vat ly nhu moi Pickable nhung LUON KHOA (`dinh_co_dinh`): bai do nha cai dat
## vao o, khong ai cam len duoc — de vat ly dong thi bai truot khoi o, bang diem doc sai.
##
## KHÔNG CÓ LUẬT CHƠI NÀO. Cùng lý do với bàn cờ: bàn bài không luật thì chơi được xì dách,
## tiến lên, phỏm, hay bất cứ trò gì nhóm bạn tự nghĩ ra. Có luật thì chỉ chơi được một trò,
## mà lại phải cãi nhau xem luật nào đúng.

const DIR := "res://asset/kenney_playing-cards/PNG/Cards (medium)/"
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
	for c in visual.get_children():
		c.queue_free()

	# Thân bài: hộp mỏng màu trắng, để nhìn nghiêng vẫn thấy độ dày.
	var than := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(card_size, thickness, card_size)
	than.mesh = bm
	than.material_override = _mat_color(Color("f4f1ea"))
	visual.add_child(than)

	var up := face_down and not _lo_cho_toi
	var tren := "card_back.png" if up else "card_%s.png" % ten()
	var duoi := "card_%s.png" % ten() if up else "card_back.png"
	_mat_face(DIR + tren, thickness * 0.5 + 0.001, -90.0)
	_mat_face(DIR + duoi, -thickness * 0.5 - 0.001, 90.0)
	var hop := BoxShape3D.new()
	hop.size = Vector3(card_size, thickness, card_size)
	_dat_hinh(hop)


## Một mặt bài: QuadMesh nằm ngang, dán ảnh. Quad mặc định đứng thẳng (mặt phẳng XY) nên
## phải quay 90° quanh X cho nó nằm ngửa.
func _mat_face(path: String, y: float, pitch_deg: float) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		push_error("Card: không nạp được " + path)
		return
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(card_size, card_size)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	# Ảnh là pixel art 64×64. Lọc mịn làm nhoè hết chấm — phải để NEAREST.
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position.y = y
	m.rotation_degrees.x = pitch_deg
	visual.add_child(m)


func _mat_color(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	return mat
