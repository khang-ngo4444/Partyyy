extends Control

## HUD: chỉ hiển thị, nghe signal từ các hệ khác.

## Chuyển tiếp lệnh chat cho `main.gd`.
signal lenh(id_nguoi_gui: int, doi_so: PackedStringArray)
signal thue_da_chon(loai: int)

## Dòng được chọn trong bảng chọn mục tiêu; -1 = huỷ.
signal muc_tieu_da_chon(i: int)

const STATUS_REFRESH := 0.2

## Nhãn hành động poker (chỉ vẽ lựa chọn hợp lệ).
const TEN_HD := {0: "[1] CHECK", 1: "[2] THEO", 2: "[3] TỐ", 3: "[4] BỎ", 4: "[5] ALL-IN"}

var _peer_count := 0
var _status_acc := STATUS_REFRESH
var _local_player: Player = null

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
@onready var trang_thai_ca_nhan: PanelContainer = $TrangThaiCaNhan
@onready var chat := $Chat
@onready var bang_thang: Control = $BangThang
@onready var bang_chon: BangChon = $BangChon
@onready var performance_manager: Node = get_node("/root/PerformanceManager")


func _ready() -> void:
	chat.lenh.connect(func(id: int, ds: PackedStringArray): lenh.emit(id, ds))
	bang_ban.thue_da_chon.connect(func(loai: int): thue_da_chon.emit(loai))
	bang_chon.da_chon.connect(func(i: int): muc_tieu_da_chon.emit(i))
	NetManager.room_joined.connect(_on_room_joined)
	NetManager.peer_joined.connect(func(_id, _uid): _refresh_peers())
	NetManager.peer_left.connect(func(_id, _inactive): _refresh_peers())
	NetManager.master_changed.connect(func(_new_id, _old): _on_room_joined())


func _process(delta: float) -> void:
	if not visible:
		return
	# Tâm ngắm chỉ hiện khi chuột đang khoá vào game.
	crosshair.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_ve_luc_nem()
	_status_acc += delta
	if _status_acc < STATUS_REFRESH:
		return
	_status_acc = fmod(_status_acc, STATUS_REFRESH)
	_refresh_status()


## Chữ trạng thái cập nhật thưa (không cần mỗi khung).
func _refresh_status() -> void:
	ping_label.text = "ping %d ms  ·  %d FPS  ·  3D %d%%" % [NetManager.rtt_ms(),
			Engine.get_frames_per_second(),
			roundi(float(performance_manager.get("current_scale")) * 100.0)]
	# Nhân vật tới sau tin peer_joined một nhịp — đếm lại đều.
	_refresh_peers()
	_nhac_bai()
	_nhac_poker()

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


## Thanh lực ném dưới tâm ngắm (chỉ hiện khi giữ E).
func _ve_luc_nem() -> void:
	var muc := -1.0
	if _local_player != null and is_instance_valid(_local_player):
		muc = _local_player.muc_nap()
	luc_nen.visible = muc >= 0.0
	if muc < 0.0:
		return
	luc_muc.size = Vector2(luc_nen.size.x * muc, luc_nen.size.y)
	luc_muc.color = (Color("46a758").lerp(Color("f5d90a"), muc * 2.0) if muc < 0.5
			else Color("f5d90a").lerp(Color("e5484d"), (muc - 0.5) * 2.0))


## Hiện tên phòng để biết hai người có cùng phòng không.
func _on_room_joined() -> void:
	room_label.text = "PHÒNG %s  ·  bạn là #%d%s" % [
		NetManager.room_name, NetManager.local_id(),
		"  ·  CHỦ PHÒNG" if NetManager.is_master() else ""]
	_refresh_peers()


## Hiện số peer và số nhân vật; lệch nhau là lỗi đồng bộ.
func _refresh_peers() -> void:
	_peer_count = NetManager.peers_in_room().size()
	var players := get_tree().get_nodes_in_group("players")
	if _local_player == null or not is_instance_valid(_local_player):
		for n in players:
			if n is Player and n.is_mine:
				_local_player = n
				break
	var nhan_vat := players.size()
	if nhan_vat == _peer_count:
		peers_label.text = "%d người trong phòng" % _peer_count
	else:
		peers_label.text = "%d người trong phòng — mới thấy %d nhân vật" % [
				_peer_count, nhan_vat]


## Nhắc phím cho người đang ngồi bàn bài.
func _nhac_bai() -> void:
	# Ghế ngoài bàn bài (`deck = -1`: sofa, ghế lái tàu) tự nói cách dùng.
	for s: CardSeat in get_tree().get_nodes_in_group("card_seat"):
		if s.toi_dang_ngoi and s.deck < 0:
			card_prompt.text = s.loi_nhac()
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
	card_prompt.text = ("Đang trong ván %s — chờ hết ván mới đứng dậy được" % ten_ban if poker
			else "[1] RÚT THÊM      [2] DỪNG      ·  chờ hết ván mới đứng dậy được")


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
	actions_label.text = "   ".join(dong)

	# Thanh kéo chỉ hiện khi được tố.
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


## Bàn party vừa phát trạng thái mới.
func cap_nhat_ban(tt: Dictionary) -> void:
	bang_ban.cap_nhat(tt)
	trang_thai_ca_nhan.cap_nhat(tt)


## Bảng máu/trang bị chỉ hiện ở bàn party; lúc đó ẩn dòng thông tin phòng chờ.
func cap_nhat_giao_dien_ban(hien: bool, chon: int, duoc_dung: bool) -> void:
	(trang_thai_ca_nhan as TrangThaiCaNhan).dat_giao_dien(hien, chon, duoc_dung)
	$VBox.visible = not hien


func cap_nhat_chon_huong(noi_dung: String, tieu_de := "ĐÃ TUNG XÚC XẮC — CHỌN HƯỚNG") -> void:
	bang_ban.cap_nhat_chon_huong(noi_dung, tieu_de)


## `nhan` rỗng = đóng bảng.
func mo_bang_chon(tieu_de: String, nhan: PackedStringArray) -> void:
	bang_chon.mo(tieu_de, nhan)


func bao_thang(chu: String) -> void:
	bang_thang.hien(chu)


func an_thang() -> void:
	bang_thang.an()


## Phím poker đọc ở đây vì chỉ HUD biết giá trị thanh kéo.
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
