extends Control

## HUD: chỉ hiển thị, nghe signal từ các hệ khác.

## Chuyển tiếp lệnh chat cho `main.gd`.
signal lenh(id_nguoi_gui: int, doi_so: PackedStringArray)
signal thue_da_chon(loai: int)
## Kho đồ xin đổi chỗ hai ô túi.
signal doi_cho_do(a: int, b: int)

## Dòng được chọn trong bảng chọn mục tiêu; -1 = huỷ.
signal muc_tieu_da_chon(i: int)

const STATUS_REFRESH := 0.2

## Nhãn hành động poker (chỉ vẽ lựa chọn hợp lệ).
const TEN_HD := {0: "[1] CHECK", 1: "[2] THEO", 2: "[3] TỐ", 3: "[4] BỎ", 4: "[5] ALL-IN"}

var _peer_count := 0
var _status_acc := STATUS_REFRESH
var _local_player: Player = null
var _tren_ban := false
var _dem_cu := -1
var _ready_cu := ""
var _hien_ping := false

@onready var room_label: Label = %RoomLabel
@onready var role_pill: Control = %RolePill
@onready var peers_label: Label = %PeersLabel
@onready var ping_label: Label = %PingLabel
@onready var ready_label: Label = %ReadyLabel
@onready var ready_card: Control = %ReadyCard
@onready var countdown: Label = %Countdown
@onready var lobby_info: Control = %LobbyInfo
@onready var hint_row: HBoxContainer = %HintRow
@onready var card_prompt: Label = %CardPrompt
@onready var poker_bar: Control = %PokerBar
@onready var raise_row: HBoxContainer = %RaiseRow
@onready var raise_label: Label = %RaiseLabel
@onready var raise_slider: HSlider = %RaiseSlider
@onready var actions_label: Label = %Actions
@onready var crosshair: Control = %Crosshair
@onready var luc_nen: ColorRect = %LucNem
@onready var luc_muc: ColorRect = %LucNemMuc
@onready var bang_ban: Control = $BangBan
@onready var trang_thai_ca_nhan: TrangThaiCaNhan = $TrangThaiCaNhan
@onready var chat := $Chat
@onready var bang_thang: Control = $BangThang
@onready var bang_chon: BangChon = $BangChon
@onready var kho_do: KhoDo = $KhoDo
@onready var cam_pill: Control = %CamPill
@onready var cam_label: Label = %CamLabel
@onready var cam_tu_do_hint: Label = %CamTuDoHint
@onready var performance_manager: Node = get_node("/root/PerformanceManager")


func _ready() -> void:
	chat.lenh.connect(func(id: int, ds: PackedStringArray): lenh.emit(id, ds))
	bang_ban.thue_da_chon.connect(func(loai: int): thue_da_chon.emit(loai))
	bang_chon.da_chon.connect(func(i: int): muc_tieu_da_chon.emit(i))
	kho_do.doi_cho.connect(func(a: int, b: int): doi_cho_do.emit(a, b))
	%CamHint.visible = false
	NetManager.room_joined.connect(_on_room_joined)
	NetManager.peer_joined.connect(func(_id, _uid): _refresh_peers())
	NetManager.peer_left.connect(func(_id, _inactive): _refresh_peers())
	NetManager.master_changed.connect(func(_new_id, _old): _on_room_joined())
	hint_row.visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	# Tâm ngắm chỉ hiện khi chuột đang khoá vào game.
	# Camera bay / camera theo dõi người khác: không có gì để ngắm.
	var cam := get_viewport().get_camera_3d()
	crosshair.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
			and not (cam is CameraTuDo or cam is CameraBan)
	_ve_luc_nem()
	_cap_nhat_hien_thi()
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
	var chu := ""
	var dem := -1
	if ms != null:
		match ms.phase:
			ms.PHASE_COUNTDOWN:
				dem = int(ceilf(ms.countdown))
				chu = "BẮT ĐẦU NÀO!"
			ms.PHASE_PLAYING:
				chu = "VÒNG %d" % ms.round_index
			_:
				chu = "%d/%d SẴN SÀNG" % [ms.ready_count(), ms.player_count()]
	ready_label.text = chu
	ready_card.visible = chu != "" and _hien_hoat_dong_sanh()
	if chu != _ready_cu and ready_card.visible:
		UINav.nay(ready_card, 1.1)
	_ready_cu = chu
	# Đếm ngược: số to đập giữa màn.
	countdown.visible = dem > 0 and _hien_hoat_dong_sanh()
	if dem > 0 and dem != _dem_cu:
		countdown.text = str(dem)
		UINav.dap(countdown)
	_dem_cu = dem


## Ẩn thông tin sảnh khi đang ở bàn party hoặc minigame (tránh chữ rò sang màn khác).
func _cap_nhat_hien_thi() -> void:
	var qt = get_tree().get_first_node_in_group("quan_tro")
	var minigame: bool = qt != null and qt.dang_chay()
	cam_pill.visible = _tren_ban and not minigame and cam_label.text != ""
	kho_do.duoc_mo = _tren_ban and not minigame
	if not kho_do.duoc_mo:
		kho_do.dong()
	lobby_info.visible = not _tren_ban and not minigame
	hint_row.visible = false
	cam_tu_do_hint.visible = false
	ping_label.visible = _hien_ping
	if minigame:
		ready_card.visible = false
		countdown.visible = false
	# Bảng bàn tự bật/tắt theo trạng thái; chỉ che tạm lúc minigame.
	bang_ban.modulate.a = 0.0 if minigame else 1.0
	trang_thai_ca_nhan.modulate.a = 0.0 if minigame else 1.0


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_hien_ping = not _hien_ping
		get_viewport().set_input_as_handled()


## Thanh lực ném dưới tâm ngắm (chỉ hiện khi giữ E).
func _ve_luc_nem() -> void:
	var muc := -1.0
	if _local_player != null and is_instance_valid(_local_player):
		muc = _local_player.muc_nap()
	luc_nen.visible = muc >= 0.0
	if muc < 0.0:
		return
	luc_muc.size = Vector2((luc_nen.size.x - 6.0) * muc, luc_nen.size.y - 6.0)
	luc_muc.color = (Color("46a758").lerp(Color("f5d90a"), muc * 2.0) if muc < 0.5
			else Color("f5d90a").lerp(Color("e5484d"), (muc - 0.5) * 2.0))


## Hiện tên phòng để biết hai người có cùng phòng không.
func _on_room_joined() -> void:
	room_label.text = "PHÒNG %s" % NetManager.room_name
	role_pill.visible = NetManager.is_master()
	room_label.tooltip_text = "Bạn là #%d" % NetManager.local_id()
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
		peers_label.text = "%d người" % _peer_count
	else:
		peers_label.text = "%d người · mới thấy %d" % [_peer_count, nhan_vat]


## Nhắc phím cho người đang ngồi bàn bài.
func _nhac_bai() -> void:
	if not _hien_hoat_dong_sanh():
		card_prompt.text = ""
		return
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
		card_prompt.text = "%s · Q đứng dậy" % ten_ban
		return
	card_prompt.text = ("POKER" if poker else "1 Rút thêm · 2 Dừng")


func _nhac_poker() -> void:
	if not _hien_hoat_dong_sanh():
		poker_bar.visible = false
		return
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
		actions_label.text = "Chờ lượt"
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
	kho_do.cap_nhat(tt)


## Bảng máu/trang bị chỉ hiện ở bàn party; lúc đó ẩn dòng thông tin phòng chờ.
func cap_nhat_giao_dien_ban(hien: bool, chon: int, duoc_dung: bool) -> void:
	trang_thai_ca_nhan.dat_giao_dien(hien, chon, duoc_dung)
	_tren_ban = hien


func cap_nhat_chon_huong(noi_dung: String, tieu_de := "") -> void:
	trang_thai_ca_nhan.dat_chon_huong(noi_dung, tieu_de)


## `nhan` rỗng = đóng bảng.
func mo_bang_chon(tieu_de: String, nhan: PackedStringArray) -> void:
	bang_chon.mo(tieu_de, nhan)


## Nhãn chế độ camera bàn ("" = ẩn).
func cap_nhat_camera(nhan: String) -> void:
	if nhan != cam_label.text and nhan != "":
		UINav.nay(cam_pill, 1.08)
	cam_label.text = nhan
	cam_tu_do_hint.visible = false


func _hien_hoat_dong_sanh() -> bool:
	var controller := get_tree().get_first_node_in_group("quan_tro")
	return not _tren_ban and (controller == null or not controller.dang_chay())


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
