class_name QuanTroMiniGame
extends Node

## Quản trò: nạp minigame, đếm ngược, chạy, thu bảng xếp hạng, trả lại phòng chờ.
##
## Đây là ĐƯỜNG NỐI mà phần bàn cờ sẽ dùng sau này. Bàn cờ chỉ cần gọi `chay()` rồi nghe
## `ket_thuc(xep_hang)` — không biết minigame nào đang chạy, không biết luật của nó.
##
## ## Vì sao master gieo hạt giống
##
## Minigame chạy trên MỌI máy cùng lúc, không có server riêng. Bản đồ tường gạch của Tank sinh
## ngẫu nhiên — mỗi máy gọi `randi()` riêng thì mỗi người thấy một bản đồ khác nhau và cả ván
## thành vô nghĩa. Master gieo một hạt, phát qua RPC, mọi máy dựng ra y hệt.
##
## ## Vì sao dùng CanvasLayer chứ không đổi scene
##
## Fusion đang giữ cây scene (`Fusion.set_scene_parent`), và người chơi là object mạng sống
## trong đó. Gỡ cả cây ra để nạp minigame là gỡ luôn họ. Nên minigame nằm trên một lớp phủ
## RIÊNG, che kín màn hình — phòng chờ vẫn nguyên vẹn bên dưới, xong ván là hiện lại.

signal ket_thuc(xep_hang: Array)
## Man hinh minigame vua phu len. Phat tren MOI may, ngay truoc dem nguoc.
##
## Phan ban party phai biet de ngung nhan phim: minigame la mot LOP PHU, khong phai mot
## scene khac — `PhaBanCo` van song nguyen ven ben duoi va van an `_unhandled_input`.
## Khong co tin hieu nay thi bam Space giua van Tank la vua ban vua tung xuc xac.
signal bat_dau()

## Đếm ngược trước khi bắt đầu, giây.
const DEM_NGUOC := 3.0
## Hiện bảng kết quả bao lâu rồi tự về phòng chờ.
const XEM_KET_QUA := 5.0
## Sắp lại dải điểm chừng này giây một lần. Mỗi khung hình là thừa, và thứ hạng nhảy liên tục
## mỗi khung hình thì không ai đọc kịp.
const NHIP_DIEM := 0.25

const DANH_SACH := {
	"tank": "res://minigame/tank/tank_battle.tscn",
	"breaking_blocks": "res://minigame/breaking_blocks/breaking_blocks.tscn",
	"laser_leap": "res://minigame/laser_leap/laser_leap.tscn",
	"spotlights": "res://minigame/spotlights/spotlights.tscn",
	"magma": "res://minigame/magma/magma.tscn",
	"explosive": "res://minigame/explosive/explosive.tscn",
	"crown": "res://minigame/crown/crown.tscn",
	"temporal_trails": "res://minigame/temporal_trails/temporal_trails.tscn",
	"word_wars": "res://minigame/word_wars/word_wars.tscn",
	"sidestep": "res://minigame/sidestep/sidestep.tscn",
	"slippery": "res://minigame/slippery/slippery.tscn",
}


@onready var _lop: CanvasLayer = $Lop
@onready var _nen: ColorRect = $Lop/Nen
@onready var _khung: Control = $Lop/Khung
@onready var _huong_dan: Control = $Lop/HuongDan
@onready var _tieu: Label = $Lop/HuongDan/Giua/Tieu
@onready var _luat: Label = $Lop/HuongDan/Giua/Luat
@onready var _dem: Label = $Lop/HuongDan/Giua/Dem
@onready var _ket_qua: Label = $Lop/Bang/KetQua
## Dải điểm ở đáy màn hình — DÙNG CHUNG cho mọi minigame. Minigame chỉ trả lời `diem_cua()` /
## `chu_diem()`; vẽ, sắp hạng, tô màu là việc ở đây.
@onready var _bang_diem: HBoxContainer = $Lop/BangDiem

@export var o_diem_scene: PackedScene = null

var _game: MiniGame = null
var _dang_chay := false
var _ids: Array = []
var _cho_diem := 0.0


func _ready() -> void:
	Fusion.register_broadcast_receiver(self)
	_lop.visible = false


func dang_chay() -> bool:
	return _dang_chay


## Ai cũng gọi được; master mới thật sự phát lệnh. Gieo hạt ở ĐÂY chứ không ở trong minigame.
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
	if _dang_chay or not DANH_SACH.has(ma):
		return
	_dang_chay = true
	bat_dau.emit()
	_lop.visible = true
	_ket_qua.text = ""
	# Chuột thả ra: minigame 2D không xoay camera, và người chơi cần thấy con trỏ nếu bấm UI.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var scene := load(DANH_SACH[ma]) as PackedScene
	_game = scene.instantiate() as MiniGame
	_khung.add_child(_game)
	_game.xong.connect(_khi_xong, CONNECT_ONE_SHOT)
	# Tro 3D dung san that trong the gioi; nen duc se che mat dung cai no vua dung.
	_nen.visible = _game.che_nen

	# Màn hướng dẫn RIÊNG, đục kín: không còn chữ chạy đè lên cảnh bàn cờ.
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


## Mỗi người một ô. Trò không có điểm (`diem_cua` trả NAN, như Tank) thì không hiện dải.
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


## Thứ tự hiện trong dải: điểm cao đứng trước. Chỉ để HIỂN THỊ — hạng chốt vẫn là bảng `xong()`.
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
	# Trả chuột về cho game 3D. Không trả thì người chơi ra khỏi minigame mà không xoay được.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
