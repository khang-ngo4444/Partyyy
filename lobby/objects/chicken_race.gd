class_name ChickenRace
extends Node3D

## Đua gà: tủ arcade kiểu Duck Race, máng dốc lên về đích để thấy trọn mọi làn.
## Master gửi một hạt giống, mọi máy tính cùng cuộc đua. Vào phòng giữa cuộc đua thì không thấy gì.

signal finished(winner: int)

const COLORS: Array[Color] = [
	Color("e5484d"), Color("3e63dd"), Color("46a758"), Color("f5d90a"),
	Color("f76b15"), Color("8e4ec6"), Color("00b8d9"), Color("e5e5e5"),
	Color("d6409f"), Color("6b4a2f"),
]

## Gọi gà theo màu cho dễ nhận.
const COLOR_NAMES := [
	"DO", "XANH DUONG", "XANH LA", "VANG",
	"CAM", "TIM", "XANH NGOC", "TRANG", "HONG", "NAU",
]

## Chờ sau khi có kết quả rồi dọn về vạch xuất phát.
const RESET_DELAY := 5.0

@export var lane_width := 0.26
@export var track_length := 2.2

## Độ cao mặt máng ở đầu gần (ngang tầm bàn).
@export var bed_height := 0.95

## Đầu xa cao hơn đầu gần chừng này.
@export var bed_rise := 0.45
@export var duration := 7.0

var _chickens: Array[Node3D] = []

## Nút cược `Bet<làn>` (tủ, máng, nút dựng sẵn trong chicken_race.tscn); số người tin hiện trên nút.
var _bet_buttons: Array[Pressable] = []
var _finish: Array[float] = []
var _phase: Array[float] = []

## làn → mảng id người đã tin con đó.
var _bets: Dictionary = {}
var _t := -1.0
var _winner := -1
var _reset_in := -1.0

## Số làn = số con gà dưới `Chickens`.
@onready var lanes: int = $Chickens.get_child_count()
@onready var board: Label3D = $Result


func _ready() -> void:
	add_to_group("chicken_race")
	_to_mau_ga()
	for i in lanes:
		_bet_buttons.append(get_node("Bet%d" % i) as Pressable)
	_reset_positions()
	_refresh_tags.call_deferred()


func running() -> bool:
	return _t >= 0.0


func ten_ga(i: int) -> String:
	return COLOR_NAMES[i % COLOR_NAMES.size()]


## Bật/tắt niềm tin của một người vào một con (một người tin được nhiều con).
func toggle_bet(lane: int, player_id: int) -> void:
	if running() or lane < 0 or lane >= lanes:
		return
	var ds: Array = _bets.get(lane, [])
	if ds.has(player_id):
		ds.erase(player_id)
	else:
		ds.append(player_id)
	_bets[lane] = ds
	_refresh_tags()


## Gọi ở mọi máy với cùng `seed_value` thì ra cùng cuộc đua.
func start(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_finish.clear()
	_phase.clear()
	var best := INF
	for i in lanes:
		var f := duration * rng.randf_range(1.0, 1.35)
		_finish.append(f)
		_phase.append(rng.randf() * TAU)
		if f < best:
			best = f
			_winner = i
	# Kéo cả nhóm để con thắng về đích đúng giây `duration`.
	for i in lanes:
		_finish[i] *= duration / best
	_reset_positions()
	board.text = "DUA!"
	_t = 0.0


func _process(delta: float) -> void:
	if _reset_in > 0.0:
		_reset_in -= delta
		if _reset_in <= 0.0:
			_reset_in = -1.0
			_bets.clear()
			_reset_positions()
			_refresh_tags()
			board.text = "TRAO NIEM TIN - NHAN TAI LOC"
	if _t < 0.0:
		return
	_t += delta
	var xong := true
	for i in _chickens.size():
		var p: float = clampf(_t / _finish[i], 0.0, 1.0)
		if p < 1.0:
			xong = false
		_dat_ga(i, p, p < 1.0)
	if xong:
		_t = -1.0
		board.text = "GA %s THANG!%s" % [ten_ga(_winner), _ai_dung()]
		finished.emit(_winner)
		# Xem kết quả xong thì dọn về vạch và xoá cược cũ.
		_reset_in = RESET_DELAY


## Đặt con thứ i ở tiến độ p trên làn (độ cao nội suy theo dốc).
func _dat_ga(i: int, p: float, dang_chay: bool) -> void:
	var c := _chickens[i]
	var nhun := absf(sin(_t * 9.0 + _phase[i])) * 0.045 if dang_chay else 0.0
	c.position = Vector3(_lane_x(i), _bed_y(p) + nhun, _bed_z(p))
	c.rotation.z = sin(_t * 9.0 + _phase[i]) * 0.15 if dang_chay else 0.0


func _lane_x(i: int) -> float:
	return (i - (lanes - 1) * 0.5) * lane_width


func _bed_z(p: float) -> float:
	return -track_length * 0.5 + p * track_length


func _bed_y(p: float) -> float:
	return bed_height + p * bed_rise


func _reset_positions() -> void:
	for i in _chickens.size():
		_dat_ga(i, 0.0, false)


## Ai tin đúng con thắng (tên đọc từ Player đã replicate).
func _ai_dung() -> String:
	var ds: Array = _bets.get(_winner, [])
	if ds.is_empty():
		return "   khong ai tin no"
	var ten: PackedStringArray = []
	for p: Player in get_tree().get_nodes_in_group("players"):
		if ds.has(p.player_id()):
			ten.append(Player.ten_theo_id(get_tree(), p.player_id()))
	return "   " + ", ".join(ten) if ten.size() > 0 else ""


## Nút chỉ hiện số người đã tin; màu nút đã là màu làn.
func _refresh_tags() -> void:
	for i in _bet_buttons.size():
		var n: int = (_bets.get(i, []) as Array).size()
		_bet_buttons[i].set_label("" if n == 0 else str(n))


# ─── dựng hình ───


func _width() -> float:
	return lanes * lane_width


## Tô gà theo màu làn (model glb dùng chung nên tô lúc chạy).
func _to_mau_ga() -> void:
	for holder: Node3D in $Chickens.get_children():
		for m: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
			m.material_override = _mat(COLORS[_chickens.size() % COLORS.size()])
		_chickens.append(holder)


func _mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	return mat
