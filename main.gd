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
## Ten vat trong `Placeholder_<Ten>_<so>` -> scene vat mang. Them loai vat moi: them mot dong o day.
const PLACEHOLDER_SCENES := {
	"Hammer": HAMMER_SCENE,
	"Basketball": BASKETBALL_SCENE,
	"Dart": DART_SCENE,
	"Die": DIE_SCENE,
}

## Bang thang nam tren man hinh bao lau truoc khi ca phong ve phong cho, giay.
const GIAY_XEM_THANG := 6.0

## Vien toi thieu cua chu 3D, tinh theo co chu. Duoi muc nay thi chu mong dinh vao nen va
## khong doc ra — xem `_sua_chu_3d`.
const VIEN_CHU_TOI_THIEU := 0.2

## Mau vien chu hien tai. Doi theo mau den ca phong — xem `ap_mau_den`.
var _vien_chu := Color(0.05, 0.05, 0.07)

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

var _lobby: Lobby = null
## Dang don/xep quan co. CA HAI duong (xep lai, lat mat) deu `await` giua chung — bam nhanh
## hai lan thi lan sau chay XEN VAO giua await cua lan truoc va spawn them mot bo nua: quan
## bi nhan doi. Mot co chan chung ca hai.
##
## ponytail: co CUC BO tung may, khong replicate. Chan duoc nguoi bam lien tay (truong hop
## that su xay ra). Hai nguoi o hai may bam cung mot phan nghin giay thi van lot — neu gap
## thi doi sang mot co tren MatchState.
var _dang_xep := false

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

	# Nha cai tu dang ky la bo phat RPC va tu khai bao la bai cua no.
	dealer.setup(spawner)

	# RPC broadcast di toi moi node da dang ky, khong can qua mot object mang cu the.
	Fusion.register_broadcast_receiver(self)

	get_tree().node_added.connect(_khi_them_node)

	quan_tro.ket_thuc.connect(_khi_xong_minigame)
	# Minigame la mot LOP PHU, ban party van song nguyen ven ben duoi. Khong ngung no lai
	# thi mot phim Space vua ban tank vua tung xuc xac.
	quan_tro.bat_dau.connect(func(): ban_co.tam_dung = true)
	ban_co.het_vong.connect(_khi_het_vong)
	ban_co.van_thang.connect(_khi_thang)
	# HUD chi HIEN THI: no nghe tin hieu chu khong doc thang vao PhaBanCo.
	ban_co.trang_thai_doi.connect(hud.cap_nhat_ban)
	ban_co.chon_huong_doi.connect(hud.cap_nhat_chon_huong)
	hud.lenh.connect(_khi_lenh)

	light_picker.mau_da_chon.connect(request_light)
	light_picker.xin_mau_goc.connect(request_light_reset)

	NetManager.room_joined.connect(_on_room_joined)
	NetManager.room_left.connect(_on_room_left)
	menu.host_requested.connect(NetManager.host_room)
	menu.join_requested.connect(NetManager.join_room)
	menu.refresh_requested.connect(NetManager.refresh_room_list)
	menu.camera_motion_changed.connect(menu_background.set_motion_enabled)

	_show_menu(true)
	NetManager.connect_to_photon()


## M o phong cho mo thang bang chon day du (model, mau, bong bong) thay vi xoay tung
## model mot cach mu. Danh sach van doc tu Player.models va ghi vao property replicate cu.
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


## Moi node vao cay deu di qua day. Hai viec, deu can bat DUNG LUC no xuat hien chu khong
## quet mot lan: chu 3D sinh ra rai rac ca phien, con MatchState thi do Fusion spawn va co
## the toi SAU khi lobby da dung xong.
func _khi_them_node(n: Node) -> void:
	_sua_chu_3d(n)
	var ms := n as MatchState
	if ms != null and not ms.changed.is_connected(_dong_bo_phong):
		ms.changed.connect(_dong_bo_phong)


## Keo trang thai chung cua phong tu MatchState ve. Chay khi nguoi khac doi mau den, va chay
## cho nguoi VAO MUON ngay khi MatchState replicate toi.
##
## ponytail: moi co mau den. `board_mode` cung nam trong MatchState va cung duoc ghi, nhung
## hien KHONG ai doc — nguoi vao muon van thay mat ban mac dinh. Them mot dong o day la xong,
## nhung phai lat ban that cho nguoi do nen de rieng.
func _dong_bo_phong() -> void:
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms == null:
		return
	ap_mau_sang(ms.light_rgb, ms.light_rgb_b)
	_theo_pha(ms)


## Đường nối giữa TRẠNG THÁI PHÒNG và MINIGAME.
##
## `MatchState` (master giữ) tự chạy: ai cũng đứng lên ô sẵn sàng -> đếm ngược -> `PHASE_PLAYING`.
## Trước đây nhánh `PHASE_PLAYING` của nó là một dòng `pass` — pha đổi rồi nhưng không có gì
## xảy ra. Đây chính là chỗ còn thiếu.
##
## CHỈ master gọi `xin_chay`: bản thân nó đã phát RPC cho cả phòng, mười máy cùng gọi là mười
## lệnh chạy cho một ván.
func _theo_pha(ms: MatchState) -> void:
	if ms.phase != MatchState.PHASE_PLAYING or not NetManager.is_master():
		return
	# Vao pha choi thi MO BAN PARTY truoc, khong nhay thang vao minigame.
	if not ban_co.dang_chay() and not quan_tro.dang_chay():
		ban_co.xin_mo([])


## Thi hành một dòng lệnh gõ trong chat.
##
## TẦNG 2 + 3 của lớp xác thực (`LenhChat`): hàm này chạy trên MỌI máy vì lệnh đi RPC tới cả
## phòng, nhưng `duoc_thi_hanh()` chỉ đúng trên máy đang là master VÀ là máy đã phát lệnh.
##
## Máy không đủ quyền vẫn vào tới đây — nó chỉ im lặng đi ra, trừ đúng người gõ thì được báo
## một câu để biết vì sao lệnh không chạy (tầng 1 đã chặn trước, đây là lưới đỡ).
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


## `/mg` trơ trọi thì liệt kê; `/mg <mã>` thì chạy.
##
## Không kiểm `dang_chay()` hộ `QuanTroMiniGame` — nó tự chặn ở `_net_chay`. Kiểm hai nơi là
## hai chỗ phải sửa khi luật đổi.
func _lenh_minigame(doi_so: PackedStringArray) -> void:
	if doi_so.is_empty():
		hud.chat.bao("Minigame: " + ", ".join(quan_tro.DANH_SACH.keys()))
		return
	var ma := doi_so[0].to_lower()
	if not quan_tro.DANH_SACH.has(ma):
		hud.chat.bao("Không có minigame '%s'. Có: %s"
				% [ma, ", ".join(quan_tro.DANH_SACH.keys())])
		return
	if quan_tro.dang_chay():
		hud.chat.bao("Đang có minigame chạy rồi.")
		return
	hud.chat.bao("Chạy %s…" % ma)
	quan_tro.xin_chay(ma)


## Het mot vong luot tren ban -> sang MINIGAME. Chi master phat lenh.
##
## Master chon ma, `xin_chay` phat ma do qua RPC cho ca phong — nen chon ngau nhien o day la
## an toan, moi may van nap dung mot tro.
##
## ponytail: rut ngau nhien tran, co the lap lai tro vua choi. Them bo dem "khong lap lai N
## tro gan nhat" khi nguoi choi bat dau thay nham.
func _khi_het_vong(_thu_tu_cu: Array) -> void:
	if NetManager.is_master() and not quan_tro.dang_chay():
		quan_tro.xin_chay(quan_tro.DANH_SACH.keys().pick_random())


## Hết minigame: master trả phòng về `PHASE_LOBBY`.
##
## Ai còn đứng trên ô sẵn sàng thì `MatchState` lại đếm ngược và vào ván kế — đúng vòng lặp
## của game. Muốn nghỉ thì bước ra khỏi ô.
##
## Het minigame: bang xep hang thanh THU TU LUOT cua vong sau — thang minigame thi duoc di truoc.
##
## Ban party van mo, khong dong lai. Vong moi bat dau ngay.
##
## Khong con RPC rieng o day: `PhaBanCo` tu phat nguyen trang thai ban (thu tu + mau + chia +
## coc + do) trong MOT goi, nen mot duong dong bo la du cho ca ban.
func _khi_xong_minigame(xep_hang: Array) -> void:
	ban_co.tam_dung = false
	ban_co.xin_thu_tu_moi(xep_hang)


## Có người đủ cốc — HẾT VÁN. Hiện bảng thắng, rồi đóng bàn và trả cả phòng về phòng chờ.
##
## Chạy trên MỌI máy, và đó là chuyện đúng: bảng thắng, đóng bàn, kéo nhân vật của mình về
## chỗ đều là việc CỤC BỘ — bàn party được nạp riêng từng máy chứ không phải object mạng.
## Chỉ mỗi khúc đặt lại pha phòng là của master.
func _khi_thang(id: int, coc: int) -> void:
	# Ngưng bàn NGAY. Lượt vẫn đang là của người vừa thắng, và bảng thắng nằm trên màn hình
	# sáu giây — không chặn thì họ bấm Space tung tiếp được, và master lại chốt thêm một lượt
	# nữa cho một ván đã xong. `dong()` gỡ cờ này ra.
	ban_co.tam_dung = true
	hud.bao_thang("%s THẮNG\n%d cốc" % [Player.ten_theo_id(get_tree(), id), coc])
	await get_tree().create_timer(GIAY_XEM_THANG).timeout
	hud.an_thang()
	ban_co.dong()
	_ve_phong_cho()
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms != null and NetManager.is_master():
		ms.phase = MatchState.PHASE_LOBBY


## Dua nhan vat cua may nay ve cho xuat phat trong phong cho.
##
## Ban party nam o y = 100; khong keo ve thi het van la ca phong roi tu do. Buoc ra khoi o san
## sang cung tu tat `is_ready`, nen phong khong dem nguoc vao van moi ngay lap tuc.
func _ve_phong_cho() -> void:
	if _lobby == null:
		return
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_mine:
			p.global_transform = _lobby.spawn_transform(NetManager.local_id() - 1)


## Luat vien chung cho MOI chu 3D trong game.
##
## Bai hoc tu bien "TRAO NIEM TIN — NHAN TAI LOC" cua truong ga: chu 3D mong tren nen kinh
## sang thi khong doc ra, va co chu cang to thi vien cang phai day theo — vien 10 px vua du
## cho chu 40, nhung tren chu 120 no chi con la mot net toc. Do lai ca project: bang diem Thap
## Ha Noi 120/10 (ti le 0.08), Liar Bar va Whack-a-Mole 120/20, bang ten nguoi choi 64/10, va
## mot nhan trong lobby.gd khong co vien nao.
##
## Chi NANG vien, khong bao gio ha: cho nao da tu dat day hon thi giu nguyen y do.
##
## KHONG dung `alpha_cut`: no se lam chu doc depth dung hon, nhung `lobby.gd` dang cho chu mo
## dan theo khoang cach bang alpha (`VISIBILITY_RANGE_FADE_SELF`) — bat alpha_cut vao la chu
## bat tat dot ngot thay vi mo dan. Hai co che nay khong di voi nhau duoc.
##
## Dung `node_added` chu khong quet mot lan luc nap map: chu sinh ra rai rac ca phien — bang
## ten nguoi vao muon, bong bong chat, nhan tren la bai vua chia. Quet mot lan la sot.
##
## ponytail: tin hieu nay ban cho MOI node vao cay, suot phien. Moi lan chi mot phep ep kieu
## — khong do thay tren khung hinh. Neu sau nay thanh van de thi goi tay o tung cho dung
## Label3D thay vi nghe tin hieu.
func _sua_chu_3d(n: Node) -> void:
	var chu := n as Label3D
	if chu == null:
		return
	chu.outline_size = maxi(chu.outline_size, roundi(chu.font_size * VIEN_CHU_TOI_THIEU))
	# Bong bong chat tu tinh mau vien theo mau NEN CUA NO. De mau theo den phong len la chu
	# den tren bong vang mat sach vien trang — dung cai lam no kho doc.
	if not chu.is_in_group("chu_rieng"):
		chu.outline_modulate = _vien_chu


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
		_spawn_placeholders(placeholders)
	for p in placeholders:
		p.queue_free()

	# Vao muon thi MatchState co the da nam san trong cay truoc khi lobby dung xong — luc do
	# `_khi_them_node` da chay qua no roi. Keo lai mot lan o day cho chac.
	_dong_bo_phong()
	var mb := get_tree().get_first_node_in_group("music_box") as MusicBox
	if mb != null:
		mb.dong_bo_vao_muon()


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
		# Thuoc tinh rieng tung vat (vd `tint` cua xuc xac) = metadata cua placeholder, sua trong Inspector.
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
	if _dang_xep or not NetManager.is_master():
		return
	_dang_xep = true
	_clear_pieces(false)
	await get_tree().create_timer(0.3).timeout
	_spawn_set(_board().mode)
	_dang_xep = false


## Bam nut DOI MAU DEN. Mau den la trang thai CA PHONG nen di qua RPC + MatchState, y het
## cach `board_mode` lam voi mat ban co — nguoi vao muon cung bat dung mau.
func request_light(mau_a: Color, mau_b: Color, hai_mau: bool) -> void:
	Fusion.rpc(_net_light, int(mau_a.to_rgba32() >> 8),
			int(mau_b.to_rgba32() >> 8) if hai_mau else -1)


## Tra anh sang ve mau goc cua map.
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


## Doi mau den, roi doi mau VIEN CHU cho khoi trung.
##
## Den hong thi chu vien den van doc duoc, nhung den tim sam thi vien den chim han vao nen.
## Lay do sang cua mau den ma quyet: den sang -> vien toi, den toi -> vien sang.
##
## Chi dung VIEN, khong dung mau chu: mau chu dang mang nghia (ghe xanh la dang ngoi, xam la
## dang khoa, moi lan ga mot mau) — de len la xoa sach may tin hieu do.
func ap_mau_sang(rgb: int, rgb_b: int) -> void:
	if _lobby == null or (rgb == _lobby.mau_sang() and rgb_b == _lobby.mau_sang_b()):
		return                 # da dung mau roi — khong quet lai ca cay node vo ich
	_lobby.dat_mau_sang(rgb, rgb_b)
	# Vien chu bam theo DIEM GIUA cua gradient: chu 3D rai khap phong, khong the moi cai mot kieu.
	var mau := Color.WHITE
	if rgb >= 0:
		mau = Color.hex((rgb << 8) | 0xFF)
		if rgb_b >= 0:
			mau = mau.lerp(Color.hex((rgb_b << 8) | 0xFF), 0.5)
	_vien_chu = (Color(0.05, 0.05, 0.07) if mau.get_luminance() > 0.45
			else Color(0.97, 0.97, 1.0))
	_quet_vien_chu(get_tree().root)


## Chu da sinh ra tu truoc thi phai di sua tan noi; chu sinh ra SAU do di qua `_sua_chu_3d`
## va nhan `_vien_chu` moi ngay luc vao cay.
func _quet_vien_chu(n: Node) -> void:
	var chu := n as Label3D
	if chu != null and not chu.is_in_group("chu_rieng"):
		chu.outline_modulate = _vien_chu
	for c in n.get_children():
		_quet_vien_chu(c)


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
	if board == null or _dang_xep:
		return
	_dang_xep = true

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

	# Spawn SAU khi animation ket thuc han. Luc nay rotation.z da ve 0 va luoi moi da dung
	# xong, nen board.point() tra ve dung toa do — quan roi dung o cua no ngay tu frame dau.
	if NetManager.is_master():
		board_state_mode(next_mode)
		_spawn_set(next_mode)
	# Mo co SAU khi da spawn xong, khong phai ngay sau animation.
	_dang_xep = false


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
