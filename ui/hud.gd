extends Control

## Chỉ hiển thị. Nghe signal, không đọc thẳng vào Player hay MatchState.

## Chat vừa nhận một dòng lệnh. HUD chuyển tiếp cho `main.gd` — nó không tự thi hành gì.
signal lenh(id_nguoi_gui: int, doi_so: PackedStringArray)

var _peer_count := 0

@onready var room_label: Label = %RoomLabel
@onready var peers_label: Label = %PeersLabel
@onready var ping_label: Label = %PingLabel
@onready var ready_label: Label = %ReadyLabel
@onready var card_prompt: Label = %CardPrompt
@onready var poker_bar: VBoxContainer = %PokerBar
@onready var raise_row: HBoxContainer = %RaiseRow
@onready var raise_label: Label = %RaiseLabel
@onready var raise_slider: HSlider = %RaiseSlider
@onready var actions_label: Label = %Actions
@onready var crosshair: Control = %Crosshair
@onready var luc_nen: ColorRect = %LucNem
@onready var luc_muc: ColorRect = %LucNemMuc
@onready var bang_ban: VBoxContainer = $BangBan
@onready var chat := $Chat
@onready var bang_thang: Control = $BangThang


func _ready() -> void:
	chat.lenh.connect(func(id: int, ds: PackedStringArray): lenh.emit(id, ds))
	NetManager.room_joined.connect(_on_room_joined)
	NetManager.peer_joined.connect(func(_id, _uid): _refresh_peers())
	NetManager.peer_left.connect(func(_id, _inactive): _refresh_peers())
	NetManager.master_changed.connect(func(_new_id, _old): _on_room_joined())


func _process(_delta: float) -> void:
	if not visible:
		return
	ping_label.text = "ping %d ms" % NetManager.rtt_ms()
	# Nhan vat toi SAU tin peer_joined mot nhip, nen phai dem lai deu chu khong chi dem
	# luc co signal.
	_refresh_peers()
	_nhac_bai()
	_nhac_poker()
	# Con trỏ chỉ có nghĩa khi chuột đang bị khoá vào game. Mở màn hình Esc thì tắt đi.
	crosshair.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_ve_luc_nem()

	var ms: MatchState = get_tree().get_first_node_in_group("match_state")
	if ms == null:
		ready_label.text = ""
		return
	match ms.phase:
		ms.PHASE_COUNTDOWN:
			ready_label.text = "BẮT ĐẦU SAU %.0f" % ceilf(ms.countdown)
		ms.PHASE_PLAYING:
			ready_label.text = "VÒNG %d" % ms.round_index
		_:
			ready_label.text = "%d/%d sẵn sàng — đứng lên ô giữa sàn" % [ms.ready_count(), ms.player_count()]


## Thanh lực ném ngay dưới tâm ngắm: xanh → vàng → đỏ theo mức nạp. Chỉ hiện khi đang giữ E.
func _ve_luc_nem() -> void:
	var muc := -1.0
	for n in get_tree().get_nodes_in_group("players"):
		if n is Player and n.is_mine:
			muc = n.muc_nap()
	luc_nen.visible = muc >= 0.0
	if muc < 0.0:
		return
	luc_muc.size = Vector2(luc_nen.size.x * muc, luc_nen.size.y)
	luc_muc.color = (Color("46a758").lerp(Color("f5d90a"), muc * 2.0) if muc < 0.5
			else Color("f5d90a").lerp(Color("e5484d"), (muc - 0.5) * 2.0))


## Hiện TÊN PHÒNG chứ không chỉ số thứ tự người chơi.
##
## Không hiện thì hai người ngồi hai phòng khác nhau mà không ai biết: chủ phòng ngồi một
## mình còn người kia thấy nhân vật của một phiên cũ. Triệu chứng nhìn y hệt lỗi đồng bộ,
## nhưng chữa thì hoàn toàn khác — nên tên phòng phải nằm ngay trên màn hình.
func _on_room_joined() -> void:
	room_label.text = "PHÒNG %s  ·  bạn là #%d%s" % [
		NetManager.room_name, NetManager.local_id(),
		"  ·  CHỦ PHÒNG" if NetManager.is_master() else ""]
	_refresh_peers()


## Đếm CẢ HAI con số và hiện cả hai khi chúng lệch nhau.
##
##   peer  = Photon báo có bao nhiêu máy trong phòng
##   nhân vật = bao nhiêu object Player thật sự có mặt trên máy này
##
## Bình thường hai số bằng nhau. Lệch nhau nghĩa là có người trong phòng mà nhân vật của họ
## chưa tới máy này — đó mới đúng là lỗi đồng bộ, và khác hẳn chuyện ngồi nhầm phòng.
func _refresh_peers() -> void:
	_peer_count = NetManager.peers_in_room().size()
	var nhan_vat := get_tree().get_nodes_in_group("players").size()
	if nhan_vat == _peer_count:
		peers_label.text = "%d người trong phòng" % _peer_count
	else:
		peers_label.text = "%d người trong phòng — mới thấy %d nhân vật" % [
				_peer_count, nhan_vat]


## Nhac phim cho nguoi dang ngoi ban bai. Day la NOTE TREN MAN HINH chu khong phai nut noi
## giua phong — sau ghe moi ban, moi ghe mot cap nut thi man hinh kin chu.
##
## Hoi thang cai ghe (`toi_dang_ngoi`) — ghe tu doc trang thai ban master phat ve.
func _nhac_bai() -> void:
	# Ghe sofa khong dinh gi toi bai bac (`deck = -1`), nhung van phai nhac cach dung day.
	for s in get_tree().get_nodes_in_group("card_seat"):
		if s is GheNgoi and (s as GheNgoi).toi_dang_ngoi:
			card_prompt.text = "Đang ngồi — [Q] đứng dậy  ·  [ESC] menu"
			return

	var dealer := get_tree().get_first_node_in_group("card_dealer") as CardDealer
	if dealer == null:
		card_prompt.text = ""
		return
	var deck := dealer.ban_dang_ngoi()
	if deck < 0:
		card_prompt.text = ""
		return
	var poker := false
	for t: CardTable in get_tree().get_nodes_in_group("card_table"):
		if t.deck_id == deck:
			poker = t.poker
	var ten_ban := "POKER" if poker else "XÌ DÁCH"
	if int(dealer.pha_ban.get(deck, 0)) != CardDealer.PHA_CHOI:
		card_prompt.text = "Đang ngồi tại bàn %s — [Q] đứng dậy  ·  [ESC] menu" % ten_ban
		return
	# Đang có ván: nói luôn là chưa đứng dậy được, thay vì để người chơi bấm Q rồi thấy im lặng.
	card_prompt.text = ("Đang trong ván %s — chờ hết ván mới đứng dậy được" % ten_ban if poker
			else "[1] RÚT THÊM      [2] DỪNG      ·  chờ hết ván mới đứng dậy được")


## Thanh hành động của poker. Chỉ vẽ những lựa chọn HỢP LỆ — ẩn Check khi đã có người cược,
## ẩn Call khi chưa ai cược. Người chơi không bấm nhầm rồi bị chặn im lặng.
const TEN_HD := {0: "[1] CHECK", 1: "[2] THEO", 2: "[3] TỐ", 3: "[4] BỎ", 4: "[5] ALL-IN"}


func _nhac_poker() -> void:
	var d = get_tree().get_first_node_in_group("card_dealer")
	if d == null:
		poker_bar.visible = false
		return
	var deck: int = d.ban_dang_ngoi()
	var la_poker := false
	for t: CardTable in get_tree().get_nodes_in_group("card_table"):
		if t.deck_id == deck:
			la_poker = t.poker
	if deck < 0 or not la_poker:
		poker_bar.visible = false
		return

	var hop_le: Array = d.hanh_dong_hop_le(deck)
	poker_bar.visible = true
	if hop_le.is_empty():
		actions_label.text = "Đang chờ người khác..."
		raise_row.visible = false
		return

	var dong: PackedStringArray = []
	for h in hop_le:
		dong.append(TEN_HD.get(h, "?"))
	# Đồng hồ lượt nằm TRÊN BÀN (CardTable), không ở HUD: người đứng xem cũng phải thấy.
	actions_label.text = "   ".join(dong)

	# Thanh kéo chỉ hiện khi TỐ hợp lệ. Kéo để chọn số chip, rồi bấm 3.
	raise_row.visible = hop_le.has(d.HD_RAISE)
	if raise_row.visible:
		var seat: int = d.ghe_cua_toi(deck)
		var it: int = d.to_toi_thieu(deck)
		var het: int = d.chip_cua(deck, seat)
		raise_slider.min_value = it
		raise_slider.max_value = maxi(het, it)
		if raise_slider.value < it or raise_slider.value > het:
			raise_slider.value = it
		raise_label.text = "Tố %d chip" % int(raise_slider.value)


## Bàn party vừa phát trạng thái mới. `main.gd` nối tín hiệu `PhaBanCo.trang_thai_doi`
## vào đây, HUD chuyển tiếp cho bảng của nó — main.gd không với sâu vào cây con của HUD.
func cap_nhat_ban(tt: Dictionary) -> void:
	bang_ban.cap_nhat(tt)


## Hết ván — hiện bảng thắng. `main.gd` gọi, rồi tự gọi `an_thang()` khi đóng bàn.
func bao_thang(chu: String) -> void:
	bang_thang.hien(chu)


func an_thang() -> void:
	bang_thang.an()


## Phím poker đọc ở HUD chứ không ở CardDealer: chỉ chỗ này mới biết thanh kéo đang ở mức nào.
func _unhandled_input(event: InputEvent) -> void:
	if not poker_bar.visible:
		return
	var d = get_tree().get_first_node_in_group("card_dealer")
	if d == null:
		return
	var deck: int = d.ban_dang_ngoi()
	var hop_le: Array = d.hanh_dong_hop_le(deck)
	if hop_le.is_empty():
		return
	var bam := -1
	for i in 5:
		if event.is_action_pressed("poker_%d" % (i + 1)):
			bam = i
	if bam < 0 or not hop_le.has(bam):
		return
	get_viewport().set_input_as_handled()
	d.request_hanh_dong(deck, bam, int(raise_slider.value))
