extends Node3D

## Node gốc suốt phiên chơi: điều phối màn hình, nạp sảnh, spawn người chơi, nối bàn party
## với minigame. Không chứa luật chơi.

## Bảng thắng hiện bao lâu trước khi về phòng chờ (giây).
const GIAY_XEM_THANG := 6.0

## Viền tối thiểu của chữ 3D, tính theo cỡ chữ (xem `_sua_chu_3d`).
const VIEN_CHU_TOI_THIEU := 0.2

## Trần số quân caro (mỗi quân là một object mạng).
const MAX_CARO_STONES := 200

## Hàng sau của cờ vua.
const BACK_ROW := [
	ChessPiece.Kind.ROOK, ChessPiece.Kind.KNIGHT, ChessPiece.Kind.BISHOP, ChessPiece.Kind.QUEEN,
	ChessPiece.Kind.KING, ChessPiece.Kind.BISHOP, ChessPiece.Kind.KNIGHT, ChessPiece.Kind.ROOK,
]

## Hàng quân cờ tướng (lưới 9×10 giao điểm).
const XIANGQI_BACK := [
	ChessPiece.XKind.CHARIOT, ChessPiece.XKind.HORSE, ChessPiece.XKind.ELEPHANT,
	ChessPiece.XKind.ADVISOR, ChessPiece.XKind.GENERAL, ChessPiece.XKind.ADVISOR,
	ChessPiece.XKind.ELEPHANT, ChessPiece.XKind.HORSE, ChessPiece.XKind.CHARIOT,
]

## Các scene Fusion sinh ra.
@export var player_scene: PackedScene = null
@export var lobby_scene: PackedScene = null
@export var match_state_scene: PackedScene = null
@export var chess_piece_scene: PackedScene = null

## Vật mang theo, đặt bằng `Placeholder_<Ten>_<so>` trong map (`hammer.tscn` → `Hammer`).
@export var vat_mang_scenes: Array[PackedScene] = []

## Màu viền chữ hiện tại, đổi theo màu đèn (xem `ap_mau_sang`).
var _vien_chu := Color(0.05, 0.05, 0.07)
var _lobby: Lobby = null

## Đang dọn/xếp quân cờ — chặn bấm liên tiếp gây nhân đôi bộ quân.
## ponytail: cờ cục bộ từng máy; hai máy bấm cùng lúc vẫn lọt.
var _dang_xep := false
var _dang_vao_sanh := false

@onready var spawner: FusionSpawner = $FusionSpawner
@onready var scene_root: Node3D = $SceneRoot
@onready var dealer: CardDealer = $CardDealer
@onready var menu: Control = $UILayer/MainMenu
@onready var menu_background: Node3D = $MenuBackground
@onready var hud: Control = $UILayer/HUD
@onready var picker: Control = $UILayer/CharacterPicker
@onready var light_picker: Control = $UILayer/LightPicker
@onready var music_picker: Control = $UILayer/MusicPicker
@onready var quan_tro: QuanTroMiniGame = $QuanTro
@onready var ban_co: PhaBanCo = $BanCo
@onready var dung_do: DungDo = $BanCo/DungDo


func _ready() -> void:
	Fusion.set_scene_load_mode(Fusion.SCENE_LOAD_AUTO)
	Fusion.set_scene_parent(scene_root)
	for sc in [player_scene, match_state_scene, chess_piece_scene] + vat_mang_scenes:
		spawner.add_spawnable_scene(sc)

	dealer.setup(spawner)

	Fusion.register_broadcast_receiver(self)

	get_tree().node_added.connect(_khi_them_node)

	quan_tro.ket_thuc.connect(_khi_xong_minigame)
	# Minigame phủ lên bàn: ngưng bàn để phím không vừa chơi vừa tung xúc xắc.
	quan_tro.bat_dau.connect(func(): ban_co.tam_dung = true)
	ban_co.het_vong.connect(_khi_het_vong)
	ban_co.van_thang.connect(_khi_thang)
	ban_co.trang_thai_doi.connect(hud.cap_nhat_ban)
	ban_co.chon_huong_doi.connect(hud.cap_nhat_chon_huong)
	dung_do.giao_dien_doi.connect(hud.cap_nhat_giao_dien_ban)
	dung_do.can_chon.connect(hud.mo_bang_chon)
	dung_do.goi_y_doi.connect(func(noi_dung: String) -> void:
		hud.cap_nhat_chon_huong(noi_dung, "CHỌN MỤC TIÊU"))
	hud.muc_tieu_da_chon.connect(dung_do.chon)
	hud.thue_da_chon.connect(ban_co.xin_chon_thue)
	hud.lenh.connect(_khi_lenh)

	light_picker.mau_da_chon.connect(request_light)
	light_picker.xin_mau_goc.connect(request_light_reset)

	NetManager.room_joined.connect(_on_room_joined)
	NetManager.room_left.connect(_on_room_left)
	menu.host_requested.connect(NetManager.host_room)
	menu.join_requested.connect(NetManager.join_room)
	menu.refresh_requested.connect(NetManager.refresh_room_list)
	menu.camera_motion_changed.connect(menu_background.set_motion_enabled)
	menu.gameplay_confirmed.connect(_khi_xac_nhan_gameplay)
	menu.setup_leave_requested.connect(NetManager.leave_room)

	_show_menu(true)
	NetManager.connect_to_photon()


## M ở phòng chờ: mở bảng chọn nhân vật.
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("change_model") or _lobby == null or picker.visible:
		return
	if $UILayer/PauseMenu.visible or light_picker.visible or music_picker.visible:
		return
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms != null and ms.phase != MatchState.PHASE_LOBBY:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	get_viewport().set_input_as_handled()
	picker.mo()


## Mọi node vào cây: sửa viền chữ 3D và bắt MatchState khi nó được spawn.
func _khi_them_node(n: Node) -> void:
	_sua_chu_3d(n)
	var ms := n as MatchState
	if ms != null and not ms.changed.is_connected(_dong_bo_phong):
		ms.changed.connect(_dong_bo_phong)
		_dong_bo_phong.call_deferred()


## Lấy trạng thái chung của phòng (màu đèn, mặt bàn cờ) từ MatchState — cả cho người vào muộn.
func _dong_bo_phong() -> void:
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms == null:
		return
	if not ms.setup_complete:
		if _lobby == null:
			menu.show_room_setup(NetManager.is_master(), ms.gameplay_settings())
		return
	ban_co.dat_cai_dat(ms.gameplay_settings())
	if _lobby == null:
		_vao_sanh()
		return
	ap_mau_sang(ms.light_rgb, ms.light_rgb_b)
	# Người vào muộn: bàn cờ theo mặt đang dùng (đang lật thì `flip_to` tự lo).
	var ban := _board()
	if ban != null and not _dang_xep and ban.mode != ms.board_mode:
		ban.mode = ms.board_mode
		ban.rebuild()
	_theo_pha(ms)


## Pha phòng → minigame/bàn party. CHỈ master gọi `xin_chay` (nó tự phát RPC).
func _theo_pha(ms: MatchState) -> void:
	if ms.phase != MatchState.PHASE_PLAYING or not NetManager.is_master():
		return
	# Vào pha chơi thì mở bàn party trước.
	if not ban_co.dang_chay() and not quan_tro.dang_chay():
		ban_co.xin_mo([])


## Thi hành lệnh chat. Chạy trên mọi máy; chỉ master đã phát lệnh mới thi hành.
func _khi_lenh(id_nguoi_gui: int, doi_so: PackedStringArray) -> void:
	if doi_so.is_empty():
		return
	var ten := doi_so[0]
	if not LenhChat.duoc_thi_hanh(id_nguoi_gui, NetManager.local_id(), NetManager.is_master()):
		if id_nguoi_gui == NetManager.local_id():
			hud.chat.bao(LenhChat.KHONG_PHAI_CHU)
		return

	match ten:
		"help":
			hud.chat.bao(LenhChat.bang_tro_giup())
		"mg":
			_lenh_minigame(doi_so.slice(1))
		_:
			hud.chat.bao("Không có lệnh '%s'. Gõ /help." % ten)


## `/mg` thì liệt kê; `/mg <mã>` thì chạy.
func _lenh_minigame(doi_so: PackedStringArray) -> void:
	if doi_so.is_empty():
		hud.chat.bao("Minigame: " + ", ".join(quan_tro.danh_sach()))
		return
	var ma := doi_so[0].to_lower()
	if not quan_tro.co_tro(ma):
		hud.chat.bao("Không có minigame '%s'. Có: %s"
				% [ma, ", ".join(quan_tro.danh_sach())])
		return
	if quan_tro.dang_chay():
		hud.chat.bao("Đang có minigame chạy rồi.")
		return
	hud.chat.bao("Chạy %s…" % ma)
	quan_tro.xin_chay(ma)


## Hết một vòng bàn → minigame (Còi trọng tài thì đúng trò đã chọn).
## ponytail: rút ngẫu nhiên trần, có thể lặp trò vừa chơi.
func _khi_het_vong(_thu_tu_cu: Array) -> void:
	if NetManager.is_master() and not quan_tro.dang_chay():
		var coi := str(ban_co.tt.get("coi", ""))
		if quan_tro.co_tro(coi):
			quan_tro.xin_chay(coi)
			return
		var danh_sach := quan_tro.danh_sach()
		if not danh_sach.is_empty():
			quan_tro.xin_chay(str(danh_sach[randi() % danh_sach.size()]))


## Hết minigame: xếp hạng thành thứ tự lượt vòng sau.
func _khi_xong_minigame(xep_hang: Array) -> void:
	ban_co.tam_dung = false
	ban_co.xin_thu_tu_moi(xep_hang)


## Hết ván: hiện bảng thắng, đóng bàn, về phòng chờ (mọi máy; master đặt lại pha phòng).
func _khi_thang(id: int) -> void:
	# Ngưng bàn ngay để không ai tung thêm trong lúc hiện bảng thắng.
	ban_co.tam_dung = true
	var coc := int((ban_co.tt.get("coc", {}) as Dictionary).get(LuatBan.khoa(id), 0))
	hud.bao_thang("%s THẮNG\n%d Cúp" % [Player.ten_theo_id(get_tree(), id), coc])
	await get_tree().create_timer(GIAY_XEM_THANG).timeout
	hud.an_thang()
	ban_co.dong()
	_ve_phong_cho()
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms != null and NetManager.is_master():
		ms.phase = MatchState.PHASE_LOBBY


## Đưa nhân vật của máy này về chỗ xuất phát trong phòng chờ.
func _ve_phong_cho() -> void:
	if _lobby == null:
		return
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_mine:
			p.global_transform = _lobby.spawn_transform(NetManager.local_id() - 1)


## Luật viền chung cho mọi chữ 3D: chữ càng to viền càng dày; chỉ nâng, không hạ.
## Không dùng `alpha_cut` vì sảnh làm mờ chữ theo khoảng cách bằng alpha.
func _sua_chu_3d(n: Node) -> void:
	var chu := n as Label3D
	if chu == null:
		return
	chu.outline_size = maxi(chu.outline_size, roundi(chu.font_size * VIEN_CHU_TOI_THIEU))
	# Bong bóng chat tự tính màu viền theo màu nền của nó.
	if not chu.is_in_group("chu_rieng"):
		chu.outline_modulate = _vien_chu


func _on_room_joined() -> void:
	_show_menu(true)
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if NetManager.is_master() and ms == null:
		ms = spawner.spawn(match_state_scene) as MatchState
	menu.show_room_setup(NetManager.is_master(),
			ms.gameplay_settings() if ms != null else GameplaySettings.defaults())
	if ms != null:
		_dong_bo_phong()


func _khi_xac_nhan_gameplay(value: Dictionary) -> void:
	if not NetManager.is_master():
		return
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms == null:
		return
	ms.gameplay_settings_json = GameplaySettings.encode(value)
	ms.setup_complete = true


func _vao_sanh() -> void:
	if _lobby != null or _dang_vao_sanh:
		return
	_dang_vao_sanh = true
	_show_menu(false)

	_lobby = lobby_scene.instantiate()
	scene_root.add_child(_lobby)
	for b: Pressable in _lobby.find_children("*", "Node3D", true, false).filter(
			func(n): return n is Pressable):
		if b.name == "ResetButton":
			b.pressed.connect(request_board_reset)
		elif b.name == "FlipButton":
			b.pressed.connect(request_board_flip)
		elif b.name == "CaroWhite":
			b.pressed.connect(func(): request_stone(0))
		elif b.name == "CaroBlack":
			b.pressed.connect(func(): request_stone(1))
		elif b.name == "MusicButton":
			b.pressed.connect(music_picker.mo)
		elif b.name == "LightButton":
			b.pressed.connect(light_picker.mo)
		elif b.name == "ModelButton":
			b.pressed.connect(picker.mo)
		elif b.name == "CaroReset":
			b.pressed.connect(request_caro_reset)
		elif b.name == "PenguinStep":
			b.pressed.connect(request_penguin_step)
		elif b.name == "PenguinStop":
			b.pressed.connect(request_penguin_stop)
		elif b.name == "RaceButton":
			b.pressed.connect(request_chicken_race)
		elif b.name.begins_with("Bet"):
			# Nút ChickenRace mang số làn trong tên.
			var lane := int(b.name.substr(3))
			b.pressed.connect(func(): request_bet(lane))

	# Mỗi máy tự spawn nhân vật của mình; Fusion phát cho các máy khác.
	var player: Node3D = spawner.spawn(player_scene)
	player.global_transform = _lobby.spawn_transform(NetManager.local_id() - 1)

	# Mốc `Placeholder_<Vat>_<so>`: master sinh vật mang tại đó, mọi máy xoá mốc.
	var placeholders := _lobby.find_children("Placeholder_*", "Node3D", true, false)
	if NetManager.is_master():
		_spawn_set(_board().mode)
		_spawn_placeholders(placeholders)
	for p in placeholders:
		p.queue_free()

	# Vào muộn: MatchState có thể đã có trước khi sảnh dựng xong.
	_dong_bo_phong()
	var mb := get_tree().get_first_node_in_group("music_box") as MusicBox
	if mb != null:
		mb.dong_bo_vao_muon()
	_dang_vao_sanh = false


func _vat_mang(ten: String) -> PackedScene:
	for sc in vat_mang_scenes:
		if sc != null and sc.resource_path.get_file().get_basename().capitalize() == ten:
			return sc
	return null


## Master sinh vật mang tại vị trí/hướng của từng placeholder.
func _spawn_placeholders(placeholders: Array[Node]) -> void:
	for p: Node3D in placeholders:
		var ten := String(p.name).trim_prefix("Placeholder_").get_slice("_", 0)
		var scene := _vat_mang(ten)
		if scene == null:
			push_error("Placeholder khong ro vat: %s" % p.name)
			continue
		var vat: Pickable = spawner.spawn(scene)
		# Metadata của placeholder (vd `tint`) gán sang vật.
		for k in p.get_meta_list():
			if not String(k).begins_with("_"):
				vat.set(k, p.get_meta(k))
		vat.global_transform = Transform3D(p.global_basis.orthonormalized(), p.global_position)
		vat.cho_mac_dinh = vat.global_position


func _spawn_chess_set() -> void:
	var board := get_tree().get_first_node_in_group("snap_surface") as ChessBoard
	if board == null:
		push_error("Khong tim thay ban co trong lobby")
		return

	# side 0 (trắng) hàng 0-1, side 1 (đen) hàng 6-7.
	for side in 2:
		var back_row := 0 if side == 0 else board.rows() - 1
		var pawn_row := 1 if side == 0 else board.rows() - 2
		for col in board.cols():
			_place_piece(board, BACK_ROW[col], side, col, back_row)
			_place_piece(board, ChessPiece.Kind.PAWN, side, col, pawn_row)


func _spawn_xiangqi_set() -> void:
	var board := _board()
	if board == null:
		return
	for side in 2:
		var back := 0 if side == 0 else board.rows() - 1
		var cannon := 2 if side == 0 else board.rows() - 3
		var soldier := 3 if side == 0 else board.rows() - 4
		for col in board.cols():
			_place_piece(board, XIANGQI_BACK[col], side, col, back, ChessPiece.Game.XIANGQI)
		for col in [1, 7]:
			_place_piece(board, ChessPiece.XKind.CANNON, side, col, cannon,
					ChessPiece.Game.XIANGQI)
		for col in [0, 2, 4, 6, 8]:
			_place_piece(board, ChessPiece.XKind.SOLDIER, side, col, soldier,
					ChessPiece.Game.XIANGQI)


func _place_piece(board: ChessBoard, kind: int, side: int, col: int, row: int,
		game := ChessPiece.Game.CHESS) -> void:
	var p: ChessPiece = spawner.spawn(chess_piece_scene)
	p.game = game
	p.kind = kind
	p.side = side
	p.global_position = board.point(col, row) + Vector3(0.0, 0.02, 0.0)


## Xoá bàn cờ rồi xếp lại (master làm, quân do master sở hữu).
func request_board_reset() -> void:
	Fusion.rpc(_net_reset_board)


@rpc("any_peer", "call_local")
func _net_reset_board() -> void:
	if _dang_xep or not NetManager.is_master():
		return
	_dang_xep = true
	_clear_pieces(false)
	await get_tree().create_timer(0.3).timeout
	_spawn_set(_board().mode)
	_dang_xep = false


## Đổi màu đèn: trạng thái cả phòng, đi qua RPC + MatchState.
func request_light(mau_a: Color, mau_b: Color, hai_mau: bool) -> void:
	Fusion.rpc(_net_light, int(mau_a.to_rgba32() >> 8),
			int(mau_b.to_rgba32() >> 8) if hai_mau else -1)


func request_light_reset() -> void:
	Fusion.rpc(_net_light, -1, -1)


@rpc("any_peer", "call_local")
func _net_light(rgb: int, rgb_b: int) -> void:
	ap_mau_sang(rgb, rgb_b)
	if NetManager.is_master():
		var ms := get_tree().get_first_node_in_group("match_state") as MatchState
		if ms != null:
			ms.light_rgb = rgb
			ms.light_rgb_b = rgb_b


## Đổi màu đèn rồi chọn màu viền chữ tương phản (đèn sáng → viền tối).
func ap_mau_sang(rgb: int, rgb_b: int) -> void:
	if _lobby == null or (rgb == _lobby.mau_sang() and rgb_b == _lobby.mau_sang_b()):
		return
	_lobby.dat_mau_sang(rgb, rgb_b)
	# Viền theo màu giữa của gradient.
	var mau := Color.WHITE
	if rgb >= 0:
		mau = Color.hex((rgb << 8) | 0xFF)
		if rgb_b >= 0:
			mau = mau.lerp(Color.hex((rgb_b << 8) | 0xFF), 0.5)
	_vien_chu = (Color(0.05, 0.05, 0.07) if mau.get_luminance() > 0.45
			else Color(0.97, 0.97, 1.0))
	_quet_vien_chu(get_tree().root)


## Sửa viền cho chữ đã có sẵn trong cây.
func _quet_vien_chu(n: Node) -> void:
	var chu := n as Label3D
	if chu != null and not chu.is_in_group("chu_rieng"):
		chu.outline_modulate = _vien_chu
	for c in n.get_children():
		_quet_vien_chu(c)


## Đua gà: master gieo một hạt giống, mọi máy tự tính ra cùng cuộc đua.
func request_chicken_race() -> void:
	var race := _race()
	if race == null or race.running():
		return
	Fusion.rpc(_net_chicken_race, randi())


## Penguin Cross: người bước tự gieo rồi gửi kết quả.
@rpc("any_peer", "call_local")
func _net_penguin_start(player_id: int) -> void:
	var pc := _penguin()
	if pc != null:
		pc.begin(player_id)


## Chưa ai bước thì "đi tiếp" là bắt đầu.
func request_penguin_step() -> void:
	var pc := _penguin()
	if pc == null:
		return
	if not pc.busy():
		Fusion.rpc(_net_penguin_start, NetManager.local_id())
		return
	if pc.walker_id != NetManager.local_id():
		return
	Fusion.rpc(_net_penguin_step, randf() < pc.survive_chance())


@rpc("any_peer", "call_local")
func _net_penguin_step(song: bool) -> void:
	var pc := _penguin()
	if pc != null:
		pc.advance(song)


func request_penguin_stop() -> void:
	var pc := _penguin()
	if pc == null or pc.walker_id != NetManager.local_id():
		return
	Fusion.rpc(_net_penguin_stop)


@rpc("any_peer", "call_local")
func _net_penguin_stop() -> void:
	var pc := _penguin()
	if pc != null:
		pc.stop()


func _penguin() -> PenguinCross:
	return get_tree().get_first_node_in_group("penguin_cross") as PenguinCross


## Đặt cược một con gà.
func request_bet(lane: int) -> void:
	var race := _race()
	if race == null or race.running():
		return
	Fusion.rpc(_net_bet, lane, NetManager.local_id())


@rpc("any_peer", "call_local")
func _net_bet(lane: int, player_id: int) -> void:
	var race := _race()
	if race != null:
		race.toggle_bet(lane, player_id)


@rpc("any_peer", "call_local")
func _net_chicken_race(seed_value: int) -> void:
	var race := _race()
	if race != null and not race.running():
		race.start(seed_value)


func _race() -> ChickenRace:
	return get_tree().get_first_node_in_group("chicken_race") as ChickenRace


## Lật mặt bàn: cờ vua <-> cờ tướng.
func request_board_flip() -> void:
	var dang_co_vua := _board().mode == ChessBoard.Mode.CHESS
	var next := ChessBoard.Mode.XIANGQI if dang_co_vua else ChessBoard.Mode.CHESS
	Fusion.rpc(_net_flip_board, next)


@rpc("any_peer", "call_local")
func _net_flip_board(next_mode: int) -> void:
	var board := _board()
	if board == null or _dang_xep:
		return
	_dang_xep = true

	# Ai đang đứng trên bàn thì tự hất mình ra.
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not p.is_mine:
			continue
		if board.contains(p.global_position):
			var away := (p.global_position - board.global_position)
			away.y = 0.0
			if away.length() < 0.1:
				away = Vector3.FORWARD
			p.velocity = away.normalized() * 9.0 + Vector3.UP * 6.0

	# Dọn quân trước khi lật.
	if NetManager.is_master():
		_clear_pieces(false)

	await board.flip_to(next_mode)

	# Spawn sau khi lật xong để toạ độ ô đúng.
	if NetManager.is_master():
		board_state_mode(next_mode)
		_spawn_set(next_mode)
	_dang_xep = false


## Ghi mặt bàn vào MatchState cho người vào muộn.
func board_state_mode(m: int) -> void:
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms != null:
		ms.board_mode = m


## Có hai bàn trong nhóm snap_surface — lọc theo chế độ.
func _board() -> ChessBoard:
	for b: ChessBoard in get_tree().get_nodes_in_group("snap_surface"):
		if b.mode != ChessBoard.Mode.CARO:
			return b
	return null


## Xoá quân theo bộ. Lặp không kiểu rồi lọc bằng `is` vì nhóm "pickable" có nhiều loại.
func _clear_pieces(caro: bool) -> void:
	for p in get_tree().get_nodes_in_group("pickable"):
		if p is ChessPiece and (p.game == ChessPiece.Game.CARO) == caro:
			spawner.despawn(p)


## Bấm hộp caro: master spawn quân và đặt vào tay luôn.
func request_stone(side: int) -> void:
	Fusion.rpc(_net_give_stone, side, NetManager.local_id())


@rpc("any_peer", "call_local")
func _net_give_stone(side: int, player_id: int) -> void:
	if not NetManager.is_master():
		return
	# Lọc bằng `is`: nhóm "pickable" có cả xúc xắc, bài.
	var n := 0
	for p in get_tree().get_nodes_in_group("pickable"):
		if p is ChessPiece and p.game == ChessPiece.Game.CARO:
			n += 1
	if n >= MAX_CARO_STONES:
		return
	var s: ChessPiece = spawner.spawn(chess_piece_scene)
	s.game = ChessPiece.Game.CARO
	s.side = side
	s.holder_id = player_id


func request_caro_reset() -> void:
	Fusion.rpc(_net_reset_caro)


@rpc("any_peer", "call_local")
func _net_reset_caro() -> void:
	if NetManager.is_master():
		_clear_pieces(true)


func _spawn_set(m: int) -> void:
	if m == ChessBoard.Mode.XIANGQI:
		_spawn_xiangqi_set()
	else:
		_spawn_chess_set()


func _on_room_left() -> void:
	_dang_vao_sanh = false
	ban_co.dong()
	quan_tro.huy()
	picker.visible = false
	light_picker.visible = false
	music_picker.visible = false
	_show_menu(true)
	if _lobby != null:
		_lobby.queue_free()
		_lobby = null


func _show_menu(show_menu: bool) -> void:
	menu.visible = show_menu
	menu_background.set_menu_active(show_menu)
	hud.visible = not show_menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if show_menu else Input.MOUSE_MODE_CAPTURED
