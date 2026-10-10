class_name QuanTroMiniGame
extends Node

## Quản trò: nạp minigame, đếm ngược, chạy, thu bảng xếp hạng. Master gieo hạt giống cho mọi máy.
## Minigame nằm trên lớp phủ (CanvasLayer) để không gỡ cây scene của Fusion.

signal ket_thuc(xep_hang: Array)

## Minigame vừa phủ lên (mọi máy) — bàn party phải ngưng nhận phím.
signal bat_dau()

## Đếm ngược trước khi bắt đầu (giây).
const DEM_NGUOC := 3.0

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
@onready var _tieu: Label = $Lop/HuongDan/Giua/Tieu
@onready var _luat: Label = $Lop/HuongDan/Giua/Luat
@onready var _dem: Label = $Lop/HuongDan/Giua/Dem
@onready var _ket_qua: Label = $Lop/Bang/KetQua

## Dải điểm dùng chung ở đáy màn hình.
@onready var _bang_diem: HBoxContainer = $Lop/BangDiem


func _ready() -> void:
	Fusion.register_broadcast_receiver(self)
	_lop.visible = false


func dang_chay() -> bool:
	return _dang_chay


func danh_sach() -> PackedStringArray:
	var ra := PackedStringArray()
	for sc in tro_choi:
		if sc != null:
			ra.append(_ma(sc))
	return ra


func co_tro(ma: String) -> bool:
	return _tim(ma) != null


func _tim(ma: String) -> PackedScene:
	for sc in tro_choi:
		if sc != null and _ma(sc) == ma:
			return sc
	return null


static func _ma(sc: PackedScene) -> String:
	return sc.resource_path.get_file().get_basename()


## Ai cũng gọi được; chỉ master phát lệnh và gieo hạt.
func xin_chay(ma: String) -> void:
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
	_luat.text = "• " + _game.luat.replace(" · ", "\n• ")
	_huong_dan.visible = true
	for i in range(int(DEM_NGUOC), 0, -1):
		_dem.text = str(i)
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
		c.queue_free()
	if o_diem_scene == null or _ids.is_empty() or is_nan(_game.diem_cua(int(_ids[0]))):
		_bang_diem.visible = false
		return
	for i in _ids.size():
		_bang_diem.add_child(o_diem_scene.instantiate())
	_bang_diem.visible = true
	_ve_bang_diem()


func _process(delta: float) -> void:
	if not _dang_chay or not _bang_diem.visible or _game == null or not is_instance_valid(_game):
		return
	_cho_diem -= delta
	if _cho_diem <= 0.0:
		_cho_diem = NHIP_DIEM
		_ve_bang_diem()


func _ve_bang_diem() -> void:
	var xep := _xep_theo_diem()
	var o := _bang_diem.get_children()
	for i in mini(xep.size(), o.size()):
		var id := int(xep[i])
		var p := _nguoi(id)
		var mau := NetManager.color_for(p.color_index) if p != null else Color.GRAY
		(o[i] as ODiem).dat(i + 1, Player.ten_theo_id(get_tree(), id), mau, _game.chu_diem(id),
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
	var dong := PackedStringArray(["KẾT QUẢ"])
	for i in xep_hang.size():
		var id := int(xep_hang[i])
		var diem := _game.chu_diem(id) if _game != null and is_instance_valid(_game) else ""
		dong.append("%d.  %s%s" % [i + 1, Player.ten_theo_id(get_tree(), id),
				("   ·   " + diem) if diem != "" else ""])
	_ket_qua.text = "\n".join(dong)
	await get_tree().create_timer(XEM_KET_QUA).timeout
	_don()
	ket_thuc.emit(xep_hang)


func huy() -> void:
	if _dang_chay:
		_don()


func _don() -> void:
	_dang_chay = false
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
	# Trả chuột về cho game 3D.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
