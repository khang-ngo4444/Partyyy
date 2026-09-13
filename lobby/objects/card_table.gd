class_name CardTable
extends Node3D

## Bàn bài. Một scene dùng cho cả xì dách và poker — hai trò chỉ khác LUẬT, không khác bàn.
##
## HỆ THỐNG LÀM NHÀ CÁI, và "hệ thống" ở đây là máy master. Master chia bài, master lật bài,
## master tuyên kết quả. Người chơi chỉ gửi hai lựa chọn: rút/dừng (xì dách) hoặc theo/bỏ
## (poker).
##
## NHIỀU NGƯỜI CÙNG CHƠI VỚI NHÀ CÁI. Mỗi người quyết ĐỘC LẬP, không phải chờ lượt nhau;
## khi tất cả đã dừng thì nhà cái mới đánh MỘT lần rồi so với từng người. Sòng bài thật cũng
## xử lý đúng như vậy, và cách này né được toàn bộ chuyện đồng bộ thứ tự lượt.
##
## KHÔNG CÓ NÚT NÀO Ở BÀN. Ngồi vào ghế là vào ván; hết đếm ngược thì hệ thống tự chia.
## Người ngồi chọn bằng PHÍM (1 và 2), nhắc hiện trên HUD của riêng họ.
##
## Node này KHÔNG chạy luật — nó giữ hình hài bàn, ghế, ô đặt bài, bảng thông báo.
## Luật nằm ở `main.gd` vì chỉ chỗ đó mới spawn được lá bài lên mạng.

## Bài xếp thành hàng ngang, cách nhau chừng này — đủ nhìn ra từng lá mà vẫn gọn trong ô.
const CARD_GAP := 0.16
## Bài CHUNG nằm giữa bàn, ai ngồi đâu cũng phải đọc được — nên to hơn và giãn rộng hơn
## bài riêng. Đặt sát mép xa như trước thì người ngồi đối diện nhìn không ra lá gì.
const CARD_GAP_CHUNG := 0.36
const CARD_SIZE_CHUNG := 0.34
## Ghế là scene riêng (model gán sẵn trong card_seat.tscn); số ghế theo `seats` nên vẫn sinh bằng code.
const SEAT_SCENE := preload("res://lobby/objects/card_seat.tscn")

@export var poker := false
## Bộ bài nào. Phải KHÁC NHAU giữa hai bàn, nếu không chia ở bàn này lại hết bài ở bàn kia.
@export var deck_id := 0
## Số ghế. Tối đa 10; 6 là đủ rộng mà bàn không phình to quá.
@export var seats := 6
@export var table_height := 0.75
@export var radius := 1.75

@export var felt_color := Color("1d4a33")
@export var rim_color := Color("6b4a2f")

var board: Label3D = null
var seat_nodes: Array[CardSeat] = []
var spots: Array[CardSpot] = []

var _spot_cai: CardSpot = null
var _acc := 0.0
var _pot_label: Label3D = null
var _chip_labels: Array[Label3D] = []
var _nut_d: MeshInstance3D = null
var _dong_ho: Label3D = null


func _ready() -> void:
	add_to_group("card_table")
	_build_table()
	_build_seats()
	_build_dong_ho()
	if poker:
		_build_bang_cuoc()
	set_board("NGOI VAO GHE DE CHIA BAI")


func set_board(txt: String) -> void:
	board.text = txt


## Lật bài riêng của ghế mà người ở MÁY NÀY đang ngồi, và chỉ ghế đó.
##
## Hỏi thẳng ghế (`toi_dang_ngoi`) — ghế đã tự đọc trạng thái bàn master phát về, không tốn
## thêm byte mạng nào.
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


## Bảng cược: POT giữa bàn, chip từng ghế, nút D đánh dấu dealer.
##
## Tất cả đều là HIỂN THỊ THUẦN, đọc lại từ bản sao trạng thái mà master phát về
## (`CardDealer.ban_cuoc`). Không giữ thêm trạng thái nào ở đây.
func _build_bang_cuoc() -> void:
	_pot_label = Label3D.new()
	_pot_label.font_size = 44
	_pot_label.pixel_size = 0.0026
	_pot_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_pot_label.outline_size = 10
	_pot_label.modulate = Color("f5d90a")
	_pot_label.position = Vector3(0.0, table_height + 0.62, 0.0)
	add_child(_pot_label)

	for i in seats:
		var a := _goc(i)
		var l := Label3D.new()
		l.font_size = 30
		l.pixel_size = 0.0022
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.outline_size = 8
		l.position = Vector3(sin(a) * radius * 0.97, table_height + 0.16, cos(a) * radius * 0.97)
		add_child(l)
		_chip_labels.append(l)

	_nut_d = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.06
	cm.height = 0.02
	_nut_d.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("f2efe6")
	mat.emission_enabled = true
	mat.emission = Color("f2efe6")
	mat.emission_energy_multiplier = 0.5
	_nut_d.material_override = mat
	_nut_d.visible = false
	add_child(_nut_d)


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
		# Tới lượt ai thì tên người đó sáng vàng — nhìn là biết đang chờ ai.
		_chip_labels[i].modulate = Color("f5d90a") if i == luot else Color("d9d2c5")

	var dl: int = d.dealer_cua(deck_id)
	_nut_d.visible = dl >= 0 and dl < seats
	if _nut_d.visible:
		var a := _goc(dl)
		_nut_d.position = Vector3(sin(a) * radius * 0.66, table_height + 0.02, cos(a) * radius * 0.66)


## Đồng hồ đếm ngược nổi trên bàn — ai đứng xem cũng thấy cùng một con số.
##
## Không nằm ở HUD: người đứng ngoài cũng cần biết còn bao lâu thì chia, và HUD chỉ có ở
## máy người ngồi. Cập nhật MỖI FRAME chứ không theo nhịp 0.25 s bên dưới, để số đổi đúng lúc.
func _build_dong_ho() -> void:
	_dong_ho = Label3D.new()
	_dong_ho.font_size = 80
	_dong_ho.pixel_size = 0.0032
	_dong_ho.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dong_ho.outline_size = 16
	_dong_ho.position = Vector3(0.0, table_height + 1.85, 0.0)
	_dong_ho.visible = false
	add_child(_dong_ho)


## Mỗi máy tự đếm từ số giây còn lại master gửi một lần (`CardDealer.con_lai`). Không RPC nào.
func _cap_nhat_dong_ho() -> void:
	var d = get_tree().get_first_node_in_group("card_dealer")
	var con: float = d.con_lai(deck_id) if d != null else -1.0
	_dong_ho.visible = con >= 0.0
	if not _dong_ho.visible:
		return
	# Làm tròn LÊN: còn 9.2 giây hiện 10, còn 0.3 giây hiện 1 — số 0 chỉ hiện khi hết thật.
	var giay := ceili(con)
	@warning_ignore("integer_division")
	_dong_ho.text = "%d:%02d" % [giay / 60, giay % 60]
	_dong_ho.modulate = Color("e5484d") if giay <= 3 else Color.WHITE


func _trong_o(o: CardSpot, card: Card) -> bool:
	var d: Vector3 = o.to_local(card.global_position)
	return absf(d.x) <= o.size.x * 0.5 and absf(d.z) <= o.size.y * 0.5


## Số lá tối đa mỗi bên.
##
## Xì dách cũng chỉ 5: rút tới lá thứ sáu mà chưa quá 21 là chuyện gần như không xảy ra, mà
## chừa chỗ cho nó thì khung ô dài thêm 14 cm — đủ để sáu ô chồng lên nhau.
func hand_size() -> int:
	return 5


## Vị trí VÀ GÓC XOAY của lá thứ i.
##
## Trả về `Transform3D` chứ không phải `Vector3`: ô đặt bài đã được XOAY theo hướng ghế, nên
## lá bài cũng phải xoay theo. Trước đây chỉ trả vị trí, mà lại cộng offset theo trục X của
## THẾ GIỚI — bài trải ngang trong khi cái khung nằm chéo, nên tràn hết ra ngoài khung.
## `to_global()` đặt offset trong hệ toạ độ CỦA Ô, đó mới là chỗ nó thuộc về.
## Poker: mỗi ghế chỉ giữ 2 lá riêng, 5 lá chung nằm ở ô giữa bàn.
## Xì dách: ghế giữ tới 5 lá, ô giữa là bài nhà cái.
func seat_cards() -> int:
	return 2 if poker else 5


## `n` = SỐ LÁ THẬT SỰ đang có trên tay, không phải số chỗ dành sẵn.
##
## Nhà cái mở bài bằng 2 lá trong khi ô chừa chỗ cho 5 — căn theo 5 thì hai lá đó dồn về mép
## trái ô. Căn theo số lá thật thì hàng bài luôn nằm giữa ô, và mỗi lần rút thêm thì cả hàng
## dịch lại cho cân, đúng như nhà cái thật vuốt lại cỗ bài.
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


## Cỡ lá bài chung. Master đặt lên từng lá lúc chia.
func card_size_cai() -> float:
	return CARD_SIZE_CHUNG if poker else 0.26


func _cho(o: CardSpot, i: int, n: int) -> Transform3D:
	var dx := (i - (n - 1) * 0.5) * CARD_GAP
	return Transform3D(o.global_transform.basis, o.to_global(Vector3(dx, 0.02, 0.0)))


## Ghế trải trên vòng cung phía trước, nhà cái ngồi đối diện.
## Trải trên 200° chứ không cả vòng: để chừa hẳn một phía cho nhà cái và bảng thông báo.
## Trải trên 240°: hai ô kề nhau cách nhau càng xa thì càng không chồng lên nhau. Chừa 120°
## còn lại cho nhà cái.
func _goc(i: int) -> float:
	return deg_to_rad(-120.0 + 240.0 * i / float(maxi(seats - 1, 1)))


func _build_table() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = radius
	cs.height = table_height
	shape.shape = cs
	shape.position.y = table_height * 0.5
	body.add_child(shape)
	add_child(body)

	var felt := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius * 0.88
	cm.height = table_height
	cm.radial_segments = 48
	felt.mesh = cm
	felt.material_override = _mat(felt_color)
	felt.position.y = table_height * 0.5
	add_child(felt)

	var vien := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius - 0.09
	tm.outer_radius = radius + 0.05
	tm.rings = 48
	vien.mesh = tm
	vien.material_override = _mat(rim_color)
	vien.position.y = table_height
	add_child(vien)

	board = Label3D.new()
	board.font_size = 36
	board.pixel_size = 0.0026
	board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	board.outline_size = 12
	board.position = Vector3(0.0, table_height + 1.05, 0.0)
	add_child(board)

	var ten := Label3D.new()
	ten.text = "POKER" if poker else "XI DACH"
	ten.font_size = 40
	ten.pixel_size = 0.0024
	ten.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ten.outline_size = 12
	ten.modulate = Color("d9c98a")
	ten.position = Vector3(0.0, table_height + 1.45, 0.0)
	add_child(ten)

	# Poker: bài chung nằm phẳng, LỆCH về phía nhà cái (−Z, phía không có ghế) — tay và ghế
	# người ngồi không che, và tấm bảng đứng phía sau không che bài phẳng.
	#   0.4·r: gần hơn thì hàng bài đè lên ô của hai ghế ngoài cùng (±120°); xa hơn thì hàng
	#   bài rộng 1.9 m tràn ra khỏi dây cung của mặt bàn.
	# Xì dách: nhà cái ngồi đối diện dãy khách, đúng như bàn thật.
	if poker:
		_spot_cai = _make_spot(Vector3(0.0, table_height, -radius * 0.4), "BAI CHUNG", 5)
		_spot_cai.size = Vector2(CARD_GAP_CHUNG * 4 + CARD_SIZE_CHUNG + 0.1,
				CARD_SIZE_CHUNG + 0.1)
		# Bảng đứng ở MÉP bàn phía nhà cái: bài nằm phẳng nhìn từ ghế thì bị bẹp, cần dựng lên.
		var bang := CommunityBoard.new()
		bang.spot = _spot_cai
		bang.position = Vector3(0.0, table_height, -(radius - 0.16))
		add_child(bang)
	else:
		_spot_cai = _make_spot(Vector3(0.0, table_height, -radius * 0.55), "NHA CAI", 5)


func _build_seats() -> void:
	for i in seats:
		var a := _goc(i)
		# Ô KHÔNG có chữ khi trống. Sáu chữ "GHE n" nổi trên mặt bàn che hết bảng kết quả.
		var o := _make_spot(
				Vector3(sin(a) * radius * 0.82, table_height, cos(a) * radius * 0.82),
				"", seat_cards())
		# Ô của ghế phải nhìn được bài chung thì mới chấm được bộ 7 lá.
		if poker:
			o.chung = _spot_cai
		# Xoay ô hướng về phía ghế, để hàng bài nằm ngang trước mặt người ngồi.
		o.rotation.y = a
		spots.append(o)

		var s := SEAT_SCENE.instantiate() as CardSeat
		# Tên chỉ để dễ nhận trong cây node khi gỡ lỗi — số bàn/số ghế đọc qua `deck`/`index`.
		s.name = "Seat%d_%d" % [deck_id, i]
		s.deck = deck_id
		s.index = i
		# Tâm ghế cách mép bàn 0.45 m — ghế sâu ~0.45 m nên mép trước ghế chỉ cách bàn ~0.2 m:
		# ngồi xuống là với tới bài. Trước đây 0.85 m, ngồi mà cách bàn cả sải tay.
		s.position = Vector3(sin(a) * (radius + 0.45), 0.0, cos(a) * (radius + 0.45))
		s.rotation.y = a + PI
		add_child(s)
		seat_nodes.append(s)


func _make_spot(pos: Vector3, nhan: String, so_la: int) -> CardSpot:
	var s := Node3D.new()
	s.set_script(load("res://lobby/objects/card_spot.gd"))
	s.mode = CardSpot.Mode.POKER if poker else CardSpot.Mode.BLACKJACK
	s.label_text = nhan
	s.size = Vector2(CARD_GAP * (so_la - 1) + 0.34, 0.38)
	s.position = pos
	add_child(s)
	return s


func _mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	return mat
