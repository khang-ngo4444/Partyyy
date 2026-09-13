extends Node3D

## Vỏ bọc tồn tại suốt phiên chơi. Fusion nạp map vào SceneRoot, còn node này không
## bao giờ bị gỡ.
##
## Trách nhiệm: điều phối. Nghe NetManager, bật/tắt màn hình, nạp map, spawn player.
## KHÔNG chứa logic di chuyển, không chứa luật chơi — luật hai game bài nằm ở CardDealer.

const PLAYER_SCENE := preload("res://player/player.tscn")
const LOBBY_SCENE := preload("res://lobby/lobby.tscn")
const MATCH_STATE_SCENE := preload("res://net/match_state.tscn")
const CHESS_PIECE_SCENE := preload("res://lobby/objects/chess_piece.tscn")
const DIE_SCENE := preload("res://lobby/objects/die.tscn")
const BASKETBALL_SCENE := preload("res://lobby/objects/basketball.tscn")
const DART_SCENE := preload("res://lobby/objects/dart.tscn")
const HAMMER_SCENE := preload("res://lobby/objects/hammer.tscn")
const GOLF_BALL_SCENE := preload("res://lobby/objects/golf_ball.tscn")
const PUTTER_SCENE := preload("res://lobby/objects/putter.tscn")
## Ten vat trong `Placeholder_<Ten>_<so>` -> scene vat mang. Them loai vat moi: them mot dong o day.
const PLACEHOLDER_SCENES := {
	"GolfBall": GOLF_BALL_SCENE,
	"Putter": PUTTER_SCENE,
	"Hammer": HAMMER_SCENE,
	"Basketball": BASKETBALL_SCENE,
	"Dart": DART_SCENE,
}

## Tran so quan caro. Van caro tren ban 28x28 co the dung toi 150-200 quan, moi quan la mot
## object mang — day se la phep thu lon nhat cua du an. De o day de ha xuong ma khong sua code.
const MAX_CARO_STONES := 200

## Xep du bo co vua len ban. Hang sau theo thu tu chuan, hang truoc la tot.
const BACK_ROW := [
	ChessPiece.Kind.ROOK, ChessPiece.Kind.KNIGHT, ChessPiece.Kind.BISHOP, ChessPiece.Kind.QUEEN,
	ChessPiece.Kind.KING, ChessPiece.Kind.BISHOP, ChessPiece.Kind.KNIGHT, ChessPiece.Kind.ROOK,
]

## Xep bo co tuong. Quan dung tren GIAO DIEM, luoi 9 cot x 10 hang.
##   hang 0: xe ma tuong si tuong(soai) si tuong ma xe
##   hang 2: phao o cot 1 va 7
##   hang 3: nam con tot o cot 0,2,4,6,8
const XIANGQI_BACK := [
	ChessPiece.XKind.CHARIOT, ChessPiece.XKind.HORSE, ChessPiece.XKind.ELEPHANT,
	ChessPiece.XKind.ADVISOR, ChessPiece.XKind.GENERAL, ChessPiece.XKind.ADVISOR,
	ChessPiece.XKind.ELEPHANT, ChessPiece.XKind.HORSE, ChessPiece.XKind.CHARIOT,
]

var _lobby: Node3D = null

@onready var spawner: FusionSpawner = $FusionSpawner
@onready var scene_root: Node3D = $SceneRoot
@onready var dealer: CardDealer = $CardDealer
@onready var menu: Control = $UILayer/MainMenu
@onready var hud: Control = $UILayer/HUD


func _ready() -> void:
	# Fusion tự nạp và gắn scene vào đây khi master gọi load_scene() (dùng ở phần bàn cờ).
	Fusion.set_scene_load_mode(Fusion.SCENE_LOAD_AUTO)
	Fusion.set_scene_parent(scene_root)
	spawner.add_spawnable_scene(PLAYER_SCENE)
	spawner.add_spawnable_scene(MATCH_STATE_SCENE)
	spawner.add_spawnable_scene(CHESS_PIECE_SCENE)
	spawner.add_spawnable_scene(DIE_SCENE)
	spawner.add_spawnable_scene(BASKETBALL_SCENE)
	spawner.add_spawnable_scene(DART_SCENE)
	spawner.add_spawnable_scene(HAMMER_SCENE)
	spawner.add_spawnable_scene(GOLF_BALL_SCENE)
	spawner.add_spawnable_scene(PUTTER_SCENE)

	# Nha cai tu dang ky la bo phat RPC va tu khai bao la bai cua no.
	dealer.setup(spawner)

	# RPC broadcast di toi moi node da dang ky, khong can qua mot object mang cu the.
	Fusion.register_broadcast_receiver(self)

	NetManager.room_joined.connect(_on_room_joined)
	NetManager.room_left.connect(_on_room_left)
	menu.host_requested.connect(NetManager.host_room)
	menu.join_requested.connect(NetManager.join_room)

	_show_menu(true)
	NetManager.connect_to_photon()


func _on_room_joined() -> void:
	_show_menu(false)

	# Phòng chờ luôn có mặt nên máy nào cũng tự nạp — chưa cần tới load_scene() của Fusion.
	_lobby = LOBBY_SCENE.instantiate()
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
		elif b.name == "CaroReset":
			b.pressed.connect(request_caro_reset)
		elif b.name == "PenguinStep":
			b.pressed.connect(request_penguin_step)
		elif b.name == "PenguinStop":
			b.pressed.connect(request_penguin_stop)
		elif b.name == "RaceButton":
			b.pressed.connect(request_chicken_race)
		elif b.name.begins_with("Bet"):
			# Nut do ChickenRace tu dung nen so lan nam ngay trong ten.
			var lane := int(b.name.substr(3))
			b.pressed.connect(func(): request_bet(lane))

	# Mỗi client TỰ spawn nhân vật của mình; Fusion phát lệnh spawn cho các máy khác,
	# và cache lại cho người vào muộn.
	var player: Node3D = spawner.spawn(PLAYER_SCENE)
	player.global_transform = _lobby.spawn_transform(NetManager.local_id() - 1)

	# MatchState do master giu. Chi spawn neu chua co — master moi duoc bau se thay
	# cai cu qua replication chu khong spawn them cai thu hai.
	# Moc toa do `Placeholder_<Vat>_<so>` trong cac scene mini-game: master sinh vat mang tai do,
	# may nao cung xoa moc ngay sau (xem _spawn_placeholders).
	var placeholders := _lobby.find_children("Placeholder_*", "Node3D", true, false)
	if NetManager.is_master() and get_tree().get_first_node_in_group("match_state") == null:
		spawner.spawn(MATCH_STATE_SCENE)
		_spawn_set(_board().mode)
		_spawn_xuc_xac()
		_spawn_placeholders(placeholders)
	for p in placeholders:
		p.queue_free()


## Hai vien xuc xac nam san tren ban, KHONG co nut gieo. Nhat len va nem la mot cu gieo —
## Mat ngua do vat ly quyet; master doc mat luc vien nam yen (xem Die).
func _spawn_xuc_xac() -> void:
	var ban := get_tree().get_first_node_in_group("dice_table") as DiceTable
	if ban == null:
		return
	for i in 2:
		var d: Die = spawner.spawn(DIE_SCENE)
		d.tint = "red" if i == 0 else "yellow"
		d.global_position = ban.slot(i)


## Master sinh vat mang tai dung vi tri/huong cua tung placeholder (xep bang Editor / Physics Placer).
## Cho de lai (`cho_mac_dinh`) cung lay tu do. Placeholder bi xoa ngay sau, o _on_room_joined.
func _spawn_placeholders(placeholders: Array[Node]) -> void:
	for p: Node3D in placeholders:
		var ten := String(p.name).trim_prefix("Placeholder_").get_slice("_", 0)
		var scene: PackedScene = PLACEHOLDER_SCENES.get(ten)
		if scene == null:
			push_error("Placeholder khong ro vat: %s" % p.name)
			continue
		var vat: Pickable = spawner.spawn(scene)
		vat.global_transform = Transform3D(p.global_basis.orthonormalized(), p.global_position)
		vat.cho_mac_dinh = vat.global_position


func _spawn_chess_set() -> void:
	var board := get_tree().get_first_node_in_group("snap_surface") as ChessBoard
	if board == null:
		push_error("Khong tim thay ban co trong lobby")
		return

	# side 0 (trang) o hang 0-1, side 1 (den) o hang 6-7.
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
	var p: ChessPiece = spawner.spawn(CHESS_PIECE_SCENE)
	p.game = game
	p.kind = kind
	p.side = side
	p.global_position = board.point(col, row) + Vector3(0.0, 0.02, 0.0)


## Xoa sach ban co roi xep lai. Cung mot co che se dung cho nut LAT MAT.
##
## Quan co do MASTER so huu vinh vien, nen day chi la mot RPC toi master roi master tu lam
## het. Khong con man chuyen quyen so huu nao.
func request_board_reset() -> void:
	Fusion.rpc(_net_reset_board)


@rpc("any_peer", "call_local")
func _net_reset_board() -> void:
	if not NetManager.is_master():
		return
	_clear_pieces(false)
	await get_tree().create_timer(0.3).timeout
	_spawn_set(_board().mode)


## Dua ga. Master gieo MOT hat giong roi gui di; moi may tu chay cung mot phep tinh nen ra
## cung mot cuoc dua. Khong dong bo vi tri tung con ga.
func request_chicken_race() -> void:
	var race := _race()
	if race == null or race.running():
		return
	Fusion.rpc(_net_chicken_race, randi())


## Penguin Cross. NGUOI BUOC tu gieo (xem muc 1aj) roi gui ket qua sang; may khac chi dien lai.
@rpc("any_peer", "call_local")
func _net_penguin_start(player_id: int) -> void:
	var pc := _penguin()
	if pc != null:
		pc.begin(player_id)


## Chua ai buoc thi DI TIEP la nut bat dau. Hai nut thay vi ba — buoc dau tien va buoc thu
## hai la cung mot hanh dong duoi mat nguoi choi.
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


## Dat niem tin vao mot con. La SU KIEN nen gui thang RPC, khong can state replicate -
## danh sach chi co y nghia cho toi luc cuoc dua ket thuc.
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


## Lat mat ban: co vua <-> co tuong. Dung lai dung co che cua reset, chi them phan day
## nguoi ra va xoay ban.
func request_board_flip() -> void:
	var dang_co_vua := _board().mode == ChessBoard.Mode.CHESS
	var next := ChessBoard.Mode.XIANGQI if dang_co_vua else ChessBoard.Mode.CHESS
	Fusion.rpc(_net_flip_board, next)


@rpc("any_peer", "call_local")
func _net_flip_board(next_mode: int) -> void:
	var board := _board()
	if board == null:
		return

	# Ai dang dung tren ban thi TU hat minh ra. Moi may chi lo cho nguoi choi cua no —
	# theo dung nguyen tac "thu gi day nguoi choi deu re, mien la ho tu ap len minh".
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not p.is_mine:
			continue
		if board.contains(p.global_position):
			var away := (p.global_position - board.global_position)
			away.y = 0.0
			if away.length() < 0.1:
				away = Vector3.FORWARD
			p.velocity = away.normalized() * 9.0 + Vector3.UP * 6.0

	# Don quan TRUOC khi lat: quan cu phai bien mat het roi ban moi bat dau xoay, khong
	# de quan co vua bay theo mat ban nua chung.
	if NetManager.is_master():
		_clear_pieces(false)

	await board.flip_to(next_mode)

	if not NetManager.is_master():
		return
	# Spawn SAU khi animation ket thuc han. Luc nay rotation.z da ve 0 va luoi moi da dung
	# xong, nen board.point() tra ve dung toa do — quan roi dung o cua no ngay tu frame dau.
	board_state_mode(next_mode)
	_spawn_set(next_mode)


## Ghi mat ban hien tai vao MatchState de nguoi vao muon dung dung mat.
func board_state_mode(m: int) -> void:
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms != null:
		ms.board_mode = m


## Ban co vua/tuong. Co HAI ban trong nhom snap_surface nen phai loc theo che do.
func _board() -> ChessBoard:
	for b: ChessBoard in get_tree().get_nodes_in_group("snap_surface"):
		if b.mode != ChessBoard.Mode.CARO:
			return b
	return null


## Xoa quan theo BO, khong xoa sach tat ca — hai ban co cung ton tai trong phong.
##
## Lap KHONG kieu roi loc bang `is`: nhom "pickable" gio con co ca la bai, ma la bai khong
## co thuoc tinh `game`. Lap `for p: ChessPiece in ...` la vo ngay khi them mot loai
## Pickable moi — loc o day thi moi loai sau nay deu an toan.
func _clear_pieces(caro: bool) -> void:
	for p in get_tree().get_nodes_in_group("pickable"):
		if p is ChessPiece and (p.game == ChessPiece.Game.CARO) == caro:
			spawner.despawn(p)


## Hop quan caro. Bam mot cai la co ngay mot quan TRONG TAY — master spawn roi gan holder_id
## luon, khong phai nhat lai tu dat.
func request_stone(side: int) -> void:
	Fusion.rpc(_net_give_stone, side, NetManager.local_id())


@rpc("any_peer", "call_local")
func _net_give_stone(side: int, player_id: int) -> void:
	if not NetManager.is_master():
		return
	# Lap KHONG kieu roi loc bang `is`. Nhom "pickable" gio co ca xuc xac, ma xuc xac khong
	# co thuoc tinh `game` — gan no vao mot bien kieu ChessPiece la vo ngay.
	# (Da vo dung nhu vay: "Trying to assign value of type 'die.gd' to 'chess_piece.gd'".)
	var n := 0
	for p in get_tree().get_nodes_in_group("pickable"):
		if p is ChessPiece and p.game == ChessPiece.Game.CARO:
			n += 1
	if n >= MAX_CARO_STONES:
		return
	var s: ChessPiece = spawner.spawn(CHESS_PIECE_SCENE)
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
	_show_menu(true)
	if _lobby != null:
		_lobby.queue_free()
		_lobby = null


func _show_menu(show_menu: bool) -> void:
	menu.visible = show_menu
	hud.visible = not show_menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if show_menu else Input.MOUSE_MODE_CAPTURED
