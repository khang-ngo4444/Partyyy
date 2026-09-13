class_name CardSpot
extends Node3D

## Một ô đặt bài trên bàn. Đọc những lá đang NẰM trong ô rồi hiện số.
##
## Đọc theo VỊ TRÍ chứ không giữ danh sách riêng: lá bài đã replicate vị trí sẵn rồi, nên
## máy nào cũng tự tính ra cùng một con số. Không tốn thêm một byte mạng nào.
##
## Phép tính điểm nằm ở đây dưới dạng HÀM STATIC, để nhà cái (chạy trên máy master) và ô
## hiển thị dùng CHUNG một đoạn mã. Hai bản sao của luật cộng 21 là hai cơ hội lệch nhau.

enum Mode { BLACKJACK, POKER }

const HAND_NAMES := [
	"Mau thau", "Mot doi", "Hai doi", "Xam", "Sanh",
	"Thung", "Cu lu", "Tu quy", "Thung pha sanh",
]

@export var mode: int = Mode.BLACKJACK
## Ô là HÌNH CHỮ NHẬT, đúng hình bộ bài nằm trong nó. Vòng tròn trước đây to hơn bài rất
## nhiều nên sáu ô chồng lấn lên nhau kín cả mặt bàn.
@export var size := Vector2(1.6, 0.6)
## Chữ hiện khi ô TRỐNG. Để rỗng thì ô im lặng — mặt bàn sáu ô mà ô nào cũng có chữ nổi
## thì đọc bảng kết quả không nổi nữa.
@export var label_text := ""

## Ô BÀI CHUNG của bàn poker. Ô của mỗi ghế trỏ tới đây để cộng 5 lá chung vào 2 lá riêng —
## đúng luật Texas Hold'em: bộ mạnh nhất ghép từ CẢ BẢY lá.
var chung: CardSpot = null

## Đọc lại 4 lần/giây, không phải mỗi frame. Đây là bảng số cho người đọc, không phải vật lý.
const REFRESH := 0.25

var _acc := 0.0
var _readout: Label3D
var _last := ""


func _ready() -> void:
	add_to_group("card_spot")
	_build()


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


## Lá ĐỌC ĐƯỢC trong ô này, theo góc nhìn của MÁY NÀY.
##
## Bỏ qua lá úp — nếu tính thì bảng của nhà cái lộ luôn lá tẩy. Nhưng lá riêng của chính
## người ở máy này thì tính, vì họ đọc được nó (xem `Card.lo_cuc_bo`). Hệ quả cố ý: ô của
## bạn hiện bộ bài của bạn, ô người khác im lặng.
func cards() -> Array[Card]:
	var out: Array[Card] = []
	for c in get_tree().get_nodes_in_group("card"):
		var card := c as Card
		if card == null or not card.hien_voi_toi():
			continue
		# `to_local()` chứ KHÔNG phải trừ vị trí rồi so trục thế giới.
		#
		# Ô đã được XOAY theo hướng ghế. So theo trục thế giới thì hàng bài nằm chéo, và lá
		# ngoài cùng rơi ra khỏi khung tính — ghế có 2 lá mà chỉ đếm được 1, điểm hiện sai.
		# Cùng một lỗi với chỗ đặt bài đã sửa ở mục 1at, sót lại ở chỗ ĐỌC.
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


## Cộng át là 11 trước, quá 21 thì hạ dần từng con xuống 1. Đây chính là chỗ người ta hay
## cộng sai, nên nó đáng để máy làm hộ. `ranks` là chỉ số 0..12 (0 = át).
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


## Hạng bài 5 lá, 0 = mậu thầu ... 8 = thùng phá sảnh.
##
## Chỉ nhận ĐÚNG 5 lá. Bài 6-7 lá thì gọi `best_rank()`.
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

	# Át đứng ĐẦU trong mảng (chỉ số 0) nên phải quy về 14 để bắt sảnh 10-J-Q-K-A.
	var cao: Array[int] = []
	for r in ranks:
		cao.append(14 if r == 0 else r + 1)
	cao.sort()
	var sanh: bool = dem.size() == 5 and cao[4] - cao[0] == 4
	# Sảnh nhỏ A-2-3-4-5: át tính là 1, không phải 14.
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


## ĐIỂM đầy đủ của một bộ 5 lá: hạng + lá cao + kicker, gói vào MỘT số nguyên so sánh được.
##
## Chỉ so hạng thôi là không đủ — ba người cùng "một đôi" sẽ hoà cả ba, trong khi thực tế
## đôi K ăn đôi 5. Mã hoá theo cơ số 15 (lá cao nhất là át = 14, cần 15 giá trị):
##     điểm = hạng·15⁵ + v1·15⁴ + v2·15³ + v3·15² + v4·15 + v5
## v1..v5 là các lá theo THỨ TỰ QUAN TRỌNG của từng hạng, không phải theo thứ tự trên tay.
static func poker_score(ranks: Array[int], suits: Array[int]) -> int:
	var cat := poker_rank(ranks, suits)

	# Quy át về 14 rồi gom theo số lá trùng.
	var cao: Array[int] = []
	for r in ranks:
		cao.append(14 if r == 0 else r + 1)
	var dem := {}
	for v in cao:
		dem[v] = int(dem.get(v, 0)) + 1

	# Sảnh nhỏ A-2-3-4-5: át tính là 1, nên lá cao của sảnh là 5.
	var la_sanh := cat == 4 or cat == 8
	if la_sanh:
		var sx := cao.duplicate()
		sx.sort()
		var dinh: int = sx[4]
		if sx == ([2, 3, 4, 5, 14] as Array[int]):
			dinh = 5
		return _goi(cat, [dinh])

	# Xếp theo: nhiều lá trùng trước, rồi lá to trước. Đúng thứ tự quan trọng của mọi hạng
	# còn lại — tứ quý, cù lũ, xám, hai đôi, một đôi, thùng, mậu thầu đều dùng chung.
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


## Điểm của bộ 5 lá MẠNH NHẤT ghép được từ 5, 6 hay 7 lá.
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


## Hạng bộ 5 lá MẠNH NHẤT ghép được từ 5, 6 hay 7 lá.
##
## Texas Hold'em cho 2 lá riêng + 5 lá chung = 7 lá, phải thử hết C(7,5) = 21 tổ hợp. Hai
## mươi mốt lần chấm điểm mỗi phần tư giây là không đáng kể, nên duyệt thẳng chứ không cần
## thuật toán khôn hơn.
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


## Khung chữ nhật: bốn thanh mảnh, không phải mặt phẳng đặc — đặc thì che mất mặt nỉ.
func _build() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d9c98a")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	const DAY := 0.03
	for canh in [
		[Vector3(0.0, 0.0, -size.y * 0.5), Vector3(size.x, 0.01, DAY)],
		[Vector3(0.0, 0.0, size.y * 0.5), Vector3(size.x, 0.01, DAY)],
		[Vector3(-size.x * 0.5, 0.0, 0.0), Vector3(DAY, 0.01, size.y)],
		[Vector3(size.x * 0.5, 0.0, 0.0), Vector3(DAY, 0.01, size.y)],
	]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = canh[1]
		m.mesh = bm
		m.material_override = mat
		m.position = canh[0] + Vector3(0.0, 0.012, 0.0)
		add_child(m)

	_readout = Label3D.new()
	_readout.text = label_text
	_readout.visible = label_text != ""
	_readout.font_size = 32
	_readout.pixel_size = 0.0022
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.outline_size = 8
	_readout.position = Vector3(0.0, 0.3, 0.0)
	add_child(_readout)
