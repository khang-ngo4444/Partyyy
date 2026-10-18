class_name QuanTroMiniGame
extends Node

## Quản trò: nạp minigame, đếm ngược, chạy, thu bảng xếp hạng. Master gieo hạt giống cho mọi máy.
## Minigame nằm trên lớp phủ (CanvasLayer) để không gỡ cây scene của Fusion.

signal ket_thuc(xep_hang: Array)

## Minigame vừa phủ lên (mọi máy) — bàn party phải ngưng nhận phím.
signal bat_dau()

## Đếm ngược trước khi bắt đầu (giây).
const DEM_NGUOC := 5.0

## Hiện kết quả bao lâu.
const XEM_KET_QUA := 5.0

## Sắp lại dải điểm mỗi chừng này giây.
const NHIP_DIEM := 0.25

## Các minigame (kéo scene vào Inspector). Mã của trò = tên file scene.
@export var tro_choi: Array[PackedScene] = []
@export var o_diem_scene: PackedScene = null

var _game: MiniGame = null
var _dang_chay := false
var _ids: Array = []
var _cho_diem := 0.0

@onready var _lop: CanvasLayer = $Lop
@onready var _nen: ColorRect = $Lop/Nen
@onready var _khung: Control = $Lop/Khung
@onready var _huong_dan: Control = $Lop/HuongDan
@onready var _the_gioi_thieu: Control = %TheGioiThieu
@onready var _tieu: Label = %Tieu
@onready var _luat: Label = %Luat
@onready var _dem: Label = %Dem
@onready var _the_ket_qua: Control = %TheKetQua
@onready var _ket_qua: Label = %KetQua

## Dải điểm dùng chung ở đáy màn hình.
@onready var _bang_diem: HBoxContainer = $Lop/BangDiem
@onready var _dong_ho: Label = $Lop/Clock


func _ready() -> void:
	add_to_group("quan_tro")
	Fusion.register_broadcast_receiver(self)
	_lop.visible = false


func dang_chay() -> bool:
	return _dang_chay


func ma_dang_choi() -> String:
	return _game.scene_file_path.get_file().get_basename() if is_instance_valid(_game) else ""


func danh_sach() -> PackedStringArray:
	var ra := PackedStringArray()
	for sc in tro_choi:
		if sc != null:
			ra.append(_ma(sc))
	return ra


func co_tro(ma: String) -> bool:
	return _tim(ma) != null


func _pool_state() -> Dictionary:
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms == null or ms.minigame_pool_json.strip_edges().is_empty():
		return {}
	var parser := JSON.new()
	if parser.parse(ms.minigame_pool_json) != OK:
		return {}
	return parser.data if parser.data is Dictionary else {}


func chon_tro_ngau_nhien(uu_tien: String = "") -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return PoolMiniGame.chon(_pool_state(), danh_sach(), rng, uu_tien)


func _ghi_tro_da_choi(ma: String) -> void:
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms != null and ms.sync.has_authority():
		ms.minigame_pool_json = JSON.stringify(PoolMiniGame.da_choi(_pool_state(), danh_sach(), ma))


func _tim(ma: String) -> PackedScene:
	for sc in tro_choi:
		if sc != null and _ma(sc) == ma:
			return sc
	return null


static func _ma(sc: PackedScene) -> String:
	return sc.resource_path.get_file().get_basename()


## Ai cũng gọi được; chỉ master phát lệnh và gieo hạt.
func xin_chay(ma: String) -> void:
	if $Session.supports(ma):
		$Session.start_match(ma)
		return
	if _dang_chay:
		return
	var ids: Array = []
	for p: Player in get_tree().get_nodes_in_group("players"):
		ids.append(p.player_id())
	ids.sort()
	Fusion.rpc(_net_chay, ma, randi(), ids)


@rpc("any_peer", "call_local")
func _net_chay(ma: String, hat_giong: int, ids: Array) -> void:
	var scene := _tim(ma)
	if _dang_chay or scene == null:
		return
	_dang_chay = true
	_ghi_tro_da_choi(ma)
	bat_dau.emit()
	_lop.visible = true
	_ket_qua.text = ""
	# Thả chuột để bấm được UI.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_game = scene.instantiate() as MiniGame
	_khung.add_child(_game)
	_game.xong.connect(_khi_xong, CONNECT_ONE_SHOT)
	# Trò 3D dựng sân thật — không che nền.
	_nen.visible = _game.che_nen

	_tieu.text = _game.ten
	_luat.text = HuongDanNhanh.tom_tat(ma)
	_huong_dan.visible = true
	_the_ket_qua.visible = false
	%Mo.visible = false
	UINav.xuat_hien([_the_gioi_thieu], 0.0, 0.7)
	for i in range(int(DEM_NGUOC), 0, -1):
		_dem.text = str(i)
		UINav.dap(_dem)
		await get_tree().create_timer(1.0).timeout
		if not _dang_chay:
			return          # có người huỷ giữa chừng
	_huong_dan.visible = false
	_game.bat_dau(ids, hat_giong)
	_ids = ids.duplicate()
	_dung_bang_diem()


## Mỗi người một ô; trò không có điểm thì không hiện.
func _dung_bang_diem() -> void:
	for c in _bang_diem.get_children():
		_bang_diem.remove_child(c)
		c.queue_free()
	if o_diem_scene == null or _ids.is_empty() or not HuongDanNhanh.co_diem_rieng(ma_dang_choi()) or is_nan(_game.diem_cua(int(_ids[0]))):
		_bang_diem.visible = false
		return
	for i in mini(_ids.size(), 3):
		_bang_diem.add_child(o_diem_scene.instantiate())
	_bang_diem.visible = true
	_ve_bang_diem()


func _process(delta: float) -> void:
	_ve_dong_ho()
	if not _dang_chay or not _bang_diem.visible or _game == null or not is_instance_valid(_game):
		return
	_cho_diem -= delta
	if _cho_diem <= 0.0:
		_cho_diem = NHIP_DIEM
		_ve_bang_diem()


func _ve_dong_ho() -> void:
	var seconds := _game.giay_con_lai() if is_instance_valid(_game) else -1.0
	_dong_ho.visible = _dang_chay and not _huong_dan.visible and not _the_ket_qua.visible and seconds >= 0.0
	if not _dong_ho.visible:
		return
	_dong_ho.text = dinh_dang_gio(seconds)
	_dong_ho.modulate = Color(1, 0.3, 0.2) if seconds <= 10.0 else Color.WHITE


static func dinh_dang_gio(seconds: float) -> String:
	var whole := ceili(maxf(seconds, 0.0))
	return "%02d:%02d" % [whole / 60, whole % 60]


func _ve_bang_diem() -> void:
	var ranking := _xep_theo_diem()
	var xep := HuongDanNhanh.hang_gon(ranking, NetManager.local_id())
	var o := _bang_diem.get_children()
	for i in o.size():
		o[i].visible = i < xep.size()
	for i in mini(xep.size(), o.size()):
		var id := int(xep[i])
		var p := _nguoi(id)
		var mau := NetManager.color_for(p.color_index) if p != null else Color.GRAY
		if _game.has_method("mau_cua"):
			mau = _game.mau_cua(id)
		(o[i] as ODiem).dat(ranking.find(id) + 1, Player.ten_theo_id(get_tree(), id), mau, _game.chu_diem(id),
				id == NetManager.local_id())


## Điểm cao đứng trước (chỉ để hiển thị).
func _xep_theo_diem() -> Array:
	var xep := _ids.duplicate()
	xep.sort_custom(func(a, b) -> bool: return _game.diem_cua(int(a)) > _game.diem_cua(int(b)))
	return xep


func _nguoi(id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == id:
			return p
	return null


func _khi_xong(xep_hang: Array) -> void:
	if not _dang_chay:
		return
	_dong_ho.visible = false
	var dong := PackedStringArray()
	for i in xep_hang.size():
		var id := int(xep_hang[i])
		var diem := _game.chu_diem(id) if _game != null and is_instance_valid(_game) else ""
		dong.append("%d.  %s%s" % [i + 1, Player.ten_theo_id(get_tree(), id),
				("   ·   " + diem) if diem != "" else ""])
	_ket_qua.text = "\n".join(dong)
	# Phủ tối toàn màn để thẻ kết quả không chồng lên UI của trò / dải điểm.
	%Mo.visible = true
	_bang_diem.visible = false
	_an_ui_tro()
	_the_ket_qua.visible = true
	UINav.dap(_the_ket_qua)
	var completed_game: MiniGame = _game
	var seconds: float = XEM_KET_QUA
	if _game is MiniGame3D and not (_game as MiniGame3D).shared_snapshot.is_empty():
		var snapshot: Dictionary = (_game as MiniGame3D).shared_snapshot
		seconds = maxf(float(snapshot["ended"]) + XEM_KET_QUA - Fusion.get_network_time(), 0.01)
	await get_tree().create_timer(seconds).timeout
	if _game == completed_game:
		_don()
		ket_thuc.emit(xep_hang)


## Ẩn lớp UI riêng của trò (CanvasLayer không ăn theo `visible` của node cha).
func _an_ui_tro() -> void:
	if _game == null or not is_instance_valid(_game):
		return
	for n in _game.find_children("*", "CanvasLayer", true, false):
		(n as CanvasLayer).visible = false
	for c in _game.find_children("*", "Control", true, false):
		(c as Control).visible = false


func huy() -> void:
	if _dang_chay:
		_don()


func _don() -> void:
	_dang_chay = false
	_dong_ho.visible = false
	if _game != null and is_instance_valid(_game):
		_game.dung_som()
		_game.queue_free()
	_game = null
	_lop.visible = false
	_nen.visible = true
	_huong_dan.visible = false
	_bang_diem.visible = false
	_ids.clear()
	_ket_qua.text = ""
	_the_ket_qua.visible = false
	%Mo.visible = false
	# Trả chuột về cho game 3D.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func begin_shared_game(snapshot: Dictionary) -> void:
	if _dang_chay:
		_don()
	var scene: PackedScene = _tim(str(snapshot["code"]))
	if scene == null:
		return
	_dang_chay = true
	_ghi_tro_da_choi(str(snapshot["code"]))
	bat_dau.emit()
	_lop.visible = true
	_ket_qua.text = ""
	_game = scene.instantiate() as MiniGame
	_game.shared_snapshot = snapshot.duplicate(true)
	_game.shared_session = $Session
	_khung.add_child(_game)
	_game.xong.connect(_khi_xong, CONNECT_ONE_SHOT)
	_setup_shared_presentation(snapshot)


func _setup_shared_presentation(snapshot: Dictionary) -> void:
	_nen.visible = _game.che_nen
	_tieu.text = _game.ten
	_luat.text = HuongDanNhanh.tom_tat(str(snapshot["code"]))
	_ids.clear()
	for id: Variant in snapshot["ids"]:
		_ids.append(int(id))
	_game.bat_dau(_ids, int(snapshot["seed"]))
	_dung_bang_diem()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
