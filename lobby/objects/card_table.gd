class_name CardTable
extends Node3D

## Bàn bài dùng chung cho xì dách và poker; master làm nhà cái (chia, lật, tuyên kết quả).
## Mỗi người quyết độc lập, nhà cái đánh một lần khi tất cả đã dừng.
## Ngồi vào ghế là vào ván, chọn bằng phím 1/2.
## Node này chỉ giữ bàn, ghế, ô bài, bảng (dựng sẵn trong ban_poker/ban_xi_dach.tscn);
## luật nằm ở `CardDealer`.

## Khoảng cách giữa các lá trong một hàng.
const CARD_GAP := 0.16
## Bài chung giữa bàn: to và giãn hơn để ai ngồi đâu cũng đọc được.
const CARD_GAP_CHUNG := 0.36
const CARD_SIZE_CHUNG := 0.34
## Nút D nằm giữa tâm bàn và ô của dealer.
const NUT_D_GAN := 0.8

@export var poker := false
## Bộ bài nào; hai bàn phải khác nhau.
@export var deck_id := 0

## Ghế và ô theo thứ tự trong scene (ghế i ứng với ô i).
var seat_nodes: Array[CardSeat] = []
var spots: Array[CardSpot] = []
## Số ghế, đếm từ scene.
var seats: int:
	get:
		return seat_nodes.size()
var _acc := 0.0
var _chip_labels: Array[Label3D] = []

@onready var board: Label3D = $Board
@onready var _spot_cai: CardSpot = $OCai
@onready var _dong_ho: Label3D = $DongHo
## Chỉ bàn poker có bảng cược.
@onready var _pot_label: Label3D = get_node_or_null("Pot")
@onready var _nut_d: MeshInstance3D = get_node_or_null("NutD")


func _ready() -> void:
	add_to_group("card_table")
	for c in get_children():
		if c is CardSeat:
			seat_nodes.append(c)
		elif c is CardSpot and c != _spot_cai:
			spots.append(c)
		elif c is Label3D and c.name.begins_with("Chip"):
			_chip_labels.append(c)


func set_board(txt: String) -> void:
	board.text = txt


## Lật bài riêng của ghế mà máy này đang ngồi (ghế tự đọc trạng thái master phát).
func _process(delta: float) -> void:
	_cap_nhat_dong_ho()
	_acc += delta
	if _acc < 0.25:
		return
	_acc = 0.0
	var o_toi: CardSpot = null
	for i in seat_nodes.size():
		if seat_nodes[i].toi_dang_ngoi and i < spots.size():
			o_toi = spots[i]
	for c in get_tree().get_nodes_in_group("card"):
		var card := c as Card
		if card == null or not card.face_down:
			continue
		card.lo_cuc_bo(o_toi != null and _trong_o(o_toi, card))
	if poker:
		_cap_nhat_cuoc()


func _cap_nhat_cuoc() -> void:
	var d = get_tree().get_first_node_in_group("card_dealer")
	if d == null or _pot_label == null:
		return
	var pot: int = d.pot_cua(deck_id)
	var muc: int = d.muc_cua(deck_id)
	_pot_label.text = "POT %d" % pot if muc <= 0 else "POT %d   ·   cuoc %d" % [pot, muc]
	_pot_label.visible = pot > 0 or muc > 0

	var luot: int = d.luot_cua(deck_id)
	for i in _chip_labels.size():
		var chip: int = d.chip_cua(deck_id, i)
		var co: int = d.co_cua(deck_id, i)
		var cuoc: int = d.cuoc_cua(deck_id, i)
		if chip <= 0 and cuoc <= 0 and co == 0:
			_chip_labels[i].visible = false
			continue
		_chip_labels[i].visible = true
		var duoi := ""
		if co & 1:
			duoi = "  (bo bai)"
		elif co & 2:
			duoi = "  ALL-IN"
		elif cuoc > 0:
			duoi = "  dat %d" % cuoc
		_chip_labels[i].text = "%d%s" % [chip, duoi]
		# Tới lượt ai thì tên sáng vàng.
		_chip_labels[i].modulate = Color("f5d90a") if i == luot else Color("d9d2c5")

	var dl: int = d.dealer_cua(deck_id)
	_nut_d.visible = dl >= 0 and dl < spots.size()
	if _nut_d.visible:
		var o := spots[dl].position
		_nut_d.position = Vector3(o.x * NUT_D_GAN, _nut_d.position.y, o.z * NUT_D_GAN)


## Mỗi máy tự đếm từ số giây còn lại master gửi một lần (`CardDealer.con_lai`).
func _cap_nhat_dong_ho() -> void:
	var d = get_tree().get_first_node_in_group("card_dealer")
	var con: float = d.con_lai(deck_id) if d != null else -1.0
	_dong_ho.visible = con >= 0.0
	if not _dong_ho.visible:
		return
	# Làm tròn lên: số 0 chỉ hiện khi hết thật.
	var giay := ceili(con)
	@warning_ignore("integer_division")
	_dong_ho.text = "%d:%02d" % [giay / 60, giay % 60]
	_dong_ho.modulate = Color("e5484d") if giay <= 3 else Color.WHITE


func _trong_o(o: CardSpot, card: Card) -> bool:
	var d: Vector3 = o.to_local(card.global_position)
	return absf(d.x) <= o.size.x * 0.5 and absf(d.z) <= o.size.y * 0.5


## Số lá tối đa mỗi bên.
func hand_size() -> int:
	return 5


## Số lá riêng mỗi ghế: poker 2 (5 lá chung ở giữa), xì dách tới 5 (ô giữa là nhà cái).
func seat_cards() -> int:
	return 2 if poker else 5


## Vị trí và góc lá thứ `i` trong ô (hệ toạ độ ô); căn giữa theo `n` = số lá đang có.
func slot(seat: int, i: int, n: int) -> Transform3D:
	if seat < 0 or seat >= spots.size():
		return global_transform
	return _cho(spots[seat], i, n)


func slot_cai(i: int, n: int) -> Transform3D:
	if poker:
		var dx := (i - (n - 1) * 0.5) * CARD_GAP_CHUNG
		return Transform3D(_spot_cai.global_transform.basis,
				_spot_cai.to_global(Vector3(dx, 0.02, 0.0)))
	return _cho(_spot_cai, i, n)


## Cỡ lá bài chung; master đặt lên từng lá lúc chia.
func card_size_cai() -> float:
	return CARD_SIZE_CHUNG if poker else 0.26


func _cho(o: CardSpot, i: int, n: int) -> Transform3D:
	var dx := (i - (n - 1) * 0.5) * CARD_GAP
	return Transform3D(o.global_transform.basis, o.to_global(Vector3(dx, 0.02, 0.0)))
