class_name CardSpot
extends Node3D

## Ô đặt bài: đọc các lá đang nằm trong ô (theo vị trí đã replicate) rồi hiện điểm.
## Hàm tính điểm là static để nhà cái và ô dùng chung.

enum Mode { BLACKJACK, POKER }

const HAND_NAMES := [
	"Mau thau", "Mot doi", "Hai doi", "Xam", "Sanh",
	"Thung", "Cu lu", "Tu quy", "Thung pha sanh",
]

## Đọc lại 4 lần/giây.
const REFRESH := 0.25

@export var mode: int = Mode.BLACKJACK

## Kích thước khung chữ nhật của ô.
@export var size := Vector2(1.6, 0.6)

## Chữ hiện khi ô trống; rỗng = im lặng.
@export var label_text := ""

## Ô bài chung của bàn poker; ô ghế cộng 5 lá chung vào 2 lá riêng.
@export var chung: CardSpot = null
var _acc := 0.0
var _last := ""

## Khung ô (`Canh*`) và chữ điểm dựng sẵn trong scene bàn.
@onready var _readout: Label3D = $Readout


func _ready() -> void:
	add_to_group("card_spot")


func _process(delta: float) -> void:
	_acc += delta
	if _acc < REFRESH:
		return
	_acc = 0.0
	var txt := _doc()
	if txt != _last:
		_last = txt
		_readout.text = txt
		_readout.visible = txt != ""


## Lá đọc được ở máy này: bỏ lá úp, trừ lá riêng của chính mình (`Card.lo_cuc_bo`).
func cards() -> Array[Card]:
	var out: Array[Card] = []
	for c in get_tree().get_nodes_in_group("card"):
		var card := c as Card
		if card == null or not card.hien_voi_toi():
			continue
		# `to_local()` vì ô đã xoay theo ghế.
		var d: Vector3 = to_local(card.global_position)
		if absf(d.x) <= size.x * 0.5 and absf(d.z) <= size.y * 0.5:
			out.append(card)
	return out


func _doc() -> String:
	var cs := cards()
	if cs.is_empty():
		return label_text
	if mode == Mode.POKER:
		var tat_ca := cs.duplicate()
		if chung != null:
			tat_ca.append_array(chung.cards())
		if tat_ca.size() < 5:
			return "%d la" % tat_ca.size()
		var ranks: Array[int] = []
		var suits: Array[int] = []
		for c in tat_ca:
			ranks.append(c.rank())
			suits.append(c.suit())
		return HAND_NAMES[best_rank(ranks, suits)]

	var vals: Array[int] = []
	for c in cs:
		vals.append(c.rank())
	var tong := blackjack_total(vals)
	if tong > 21:
		return "%d - QUA 21" % tong
	if tong == 21 and cs.size() == 2:
		return "XI DACH!"
	return "%d" % tong


## Điểm xì dách: át tính 11, quá 21 thì hạ dần về 1. `ranks` 0..12 (0 = át).
static func blackjack_total(ranks: Array[int]) -> int:
	var tong := 0
	var at := 0
	for r in ranks:
		if r == 0:
			tong += 11
			at += 1
		else:
			tong += mini(r + 1, 10)
	while tong > 21 and at > 0:
		tong -= 10
		at -= 1
	return tong


## Hạng bài đúng 5 lá: 0 = mậu thầu … 8 = thùng phá sảnh. 6–7 lá dùng `best_rank()`.
static func poker_rank(ranks: Array[int], suits: Array[int]) -> int:
	var dem := {}
	for r in ranks:
		dem[r] = int(dem.get(r, 0)) + 1
	var so_luong: Array[int] = []
	for r in dem:
		so_luong.append(dem[r])
	so_luong.sort()
	so_luong.reverse()

	var thung := true
	for s in suits:
		if s != suits[0]:
			thung = false
			break

	# Át quy về 14 để bắt sảnh 10-J-Q-K-A.
	var cao: Array[int] = []
	for r in ranks:
		cao.append(14 if r == 0 else r + 1)
	cao.sort()
	var sanh: bool = dem.size() == 5 and cao[4] - cao[0] == 4
	# Sảnh nhỏ A-2-3-4-5: át tính 1.
	if dem.size() == 5 and cao == ([2, 3, 4, 5, 14] as Array[int]):
		sanh = true

	if thung and sanh: return 8
	if so_luong[0] == 4: return 7
	if so_luong[0] == 3 and so_luong[1] == 2: return 6
	if thung: return 5
	if sanh: return 4
	if so_luong[0] == 3: return 3
	if so_luong[0] == 2 and so_luong[1] == 2: return 2
	if so_luong[0] == 2: return 1
	return 0


## Điểm bộ 5 lá gói vào một số nguyên so sánh được: hạng·15⁵ + v1·15⁴ + … + v5.
## v1..v5 là các lá theo thứ tự quan trọng của từng hạng.
static func poker_score(ranks: Array[int], suits: Array[int]) -> int:
	var cat := poker_rank(ranks, suits)

	# Át quy về 14 rồi gom theo số lá trùng.
	var cao: Array[int] = []
	for r in ranks:
		cao.append(14 if r == 0 else r + 1)
	var dem := {}
	for v in cao:
		dem[v] = int(dem.get(v, 0)) + 1

	# Sảnh nhỏ: lá cao là 5.
	var la_sanh := cat == 4 or cat == 8
	if la_sanh:
		var sx := cao.duplicate()
		sx.sort()
		var dinh: int = sx[4]
		if sx == ([2, 3, 4, 5, 14] as Array[int]):
			dinh = 5
		return _goi(cat, [dinh])

	# Nhiều lá trùng trước, rồi lá to trước — đúng cho mọi hạng còn lại.
	var nhom: Array = []
	for v in dem:
		nhom.append([int(dem[v]), int(v)])
	nhom.sort_custom(func(a, b):
		if a[0] != b[0]:
			return a[0] > b[0]
		return a[1] > b[1])
	var thu_tu: Array[int] = []
	for g in nhom:
		thu_tu.append(int(g[1]))
	return _goi(cat, thu_tu)


static func _goi(cat: int, vs: Array[int]) -> int:
	var d := cat
	for i in 5:
		d = d * 15 + (vs[i] if i < vs.size() else 0)
	return d


## Điểm bộ 5 lá mạnh nhất ghép từ 5–7 lá.
static func best_score(ranks: Array[int], suits: Array[int]) -> int:
	var n := ranks.size()
	if n < 5:
		return 0
	var tot := 0
	for a in n:
		for b in range(a + 1, n):
			for c in range(b + 1, n):
				for d in range(c + 1, n):
					for e in range(d + 1, n):
						var r: Array[int] = [ranks[a], ranks[b], ranks[c], ranks[d], ranks[e]]
						var t: Array[int] = [suits[a], suits[b], suits[c], suits[d], suits[e]]
						tot = maxi(tot, poker_score(r, t))
	return tot


## Tên hạng đọc ra từ điểm.
static func ten_hang(diem: int) -> String:
	@warning_ignore("integer_division")
	var cat: int = diem / (15 * 15 * 15 * 15 * 15)
	return HAND_NAMES[clampi(cat, 0, HAND_NAMES.size() - 1)]


## Hạng bộ 5 lá mạnh nhất từ 5–7 lá (duyệt hết C(7,5) = 21 tổ hợp).
static func best_rank(ranks: Array[int], suits: Array[int]) -> int:
	var n := ranks.size()
	if n < 5:
		return 0
	if n == 5:
		return poker_rank(ranks, suits)
	var tot := 0
	for a in n:
		for b in range(a + 1, n):
			for c in range(b + 1, n):
				for d in range(c + 1, n):
					for e in range(d + 1, n):
						var r: Array[int] = [ranks[a], ranks[b], ranks[c], ranks[d], ranks[e]]
						var t: Array[int] = [suits[a], suits[b], suits[c], suits[d], suits[e]]
						tot = maxi(tot, poker_rank(r, t))
	return tot
