class_name ChickenRace
extends Node3D

## Đường đua gà — một CÁI TỦ ARCADE, không phải đường đua vẽ trên sàn.
##
## Dáng lấy theo máy Duck Race: thân tủ, lòng máng dốc chia làn màu, vòm biển hiệu phía trên,
## nút đặt cược nhỏ gắn ngay mặt trước dưới mỗi làn, nút ĐUA to bên hông.
##
## Máng DỐC LÊN về phía đích: nhìn từ chỗ đứng thì thấy trọn cả tám làn thay vì bị làn gần
## che mất làn xa. Máy thùng ngoài đời dốc đúng vì lý do đó.
##
## KHÔNG đồng bộ vị trí từng con gà. Master gửi MỘT con số (hạt giống ngẫu nhiên), mọi máy
## chạy cùng phép tính trên con số đó nên ra cùng một cuộc đua. Một RPC cho cả cuộc đua.
## Đổi lại: ai vào phòng GIỮA cuộc đua thì không thấy gì — chấp nhận được với một đồ chơi.

signal finished(winner: int)

const COLORS: Array[Color] = [
	Color("e5484d"), Color("3e63dd"), Color("46a758"), Color("f5d90a"),
	Color("f76b15"), Color("8e4ec6"), Color("00b8d9"), Color("e5e5e5"),
	Color("d6409f"), Color("6b4a2f"),
]
## Gọi gà theo MÀU chứ không theo số — bảng báo "GA DO THANG" thì ngẩng lên là thấy ngay con
## nào, còn số thứ tự thì phải đếm làn.
const COLOR_NAMES := [
	"DO", "XANH DUONG", "XANH LA", "VANG",
	"CAM", "TIM", "XANH NGOC", "TRANG", "HONG", "NAU",
]
## Đợi bao lâu sau khi có kết quả rồi mới dọn về vạch xuất phát.
const RESET_DELAY := 5.0

## Số làn = số con gà dưới node `Chickens` trong scene — thêm/bớt gà trong editor là đổi số làn.
@onready var lanes: int = $Chickens.get_child_count()
@export var lane_width := 0.26
@export var track_length := 2.2
## Chiều cao mặt máng ở đầu gần. Ngang tầm bàn để đứng cạnh là nhìn xuống thấy hết.
@export var bed_height := 0.95
## Đầu xa cao hơn đầu gần chừng này — đủ để không làn nào che làn nào.
@export var bed_rise := 0.45
@export var duration := 7.0

@onready var board: Label3D = $Result

var _chickens: Array[Node3D] = []
## Nút đặt cược của từng làn. Số người tin hiện NGAY TRÊN NÚT, không treo thêm nhãn nổi:
## tám nhãn "XANH DUONG" cạnh nhau 26 cm thì đè lên nhau kín mít.
var _bet_buttons: Array[Pressable] = []
var _finish: Array[float] = []
var _phase: Array[float] = []
## làn -> mảng id người chơi đã đặt niềm tin vào con đó.
var _bets: Dictionary = {}
var _t := -1.0
var _winner := -1
var _reset_in := -1.0


func _ready() -> void:
	add_to_group("chicken_race")
	_build_cabinet()
	_build_chickens()
	_build_buttons()
	_reset_positions()
	_refresh_tags.call_deferred()
	board.text = "TRAO NIEM TIN - NHAN TAI LOC"


func running() -> bool:
	return _t >= 0.0


func ten_ga(i: int) -> String:
	return COLOR_NAMES[i % COLOR_NAMES.size()]


## Bật/tắt niềm tin của một người vào một con. Một người đặt được NHIỀU con, và nhiều người
## đặt chung một con — nên đây là danh sách chứ không phải một giá trị.
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


## Gọi ở MỌI máy với cùng `seed_value` thì ra cùng một cuộc đua.
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
	# Kéo cả nhóm lại để con thắng về đúng giây `duration` — cuộc đua luôn dài như nhau.
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
		# Xem kết quả xong thì dọn về vạch và xoá hết niềm tin của ván cũ — không dọn thì ván
		# sau người ta tưởng cược cũ vẫn còn hiệu lực.
		_reset_in = RESET_DELAY


## Đặt con thứ i ở tiến độ p trên làn của nó. Máng dốc nên độ cao cũng phải nội suy theo.
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


## Ai đặt niềm tin đúng con thắng. Tên lấy từ Player trong phòng — `player_name` đã replicate
## nên máy nào cũng đọc ra cùng danh sách.
func _ai_dung() -> String:
	var ds: Array = _bets.get(_winner, [])
	if ds.is_empty():
		return "   khong ai tin no"
	var ten: PackedStringArray = []
	for p: Player in get_tree().get_nodes_in_group("players"):
		if ds.has(p.player_id()):
			ten.append(Player.ten_theo_id(get_tree(), p.player_id()))
	return "   " + ", ".join(ten) if ten.size() > 0 else ""


## Nút chỉ hiện SỐ NGƯỜI ĐÃ TIN, không hiện tên màu.
##
## Bản thân cái nút đã mang đúng màu của làn ngay phía trên nó — viết thêm chữ "XANH DUONG"
## là thừa, mà tám cái tên dài cạnh nhau 26 cm thì đè lên nhau không đọc nổi chữ nào.
## Bảng lớn phía trên vẫn xướng tên màu khi có kết quả, nên không mất thông tin.
func _refresh_tags() -> void:
	for i in _bet_buttons.size():
		var n: int = (_bets.get(i, []) as Array).size()
		_bet_buttons[i].set_label("" if n == 0 else str(n))


# ---------------------------------------------------------------- dựng hình

func _width() -> float:
	return lanes * lane_width


func _build_cabinet() -> void:
	var w := _width()
	var than_cao := bed_height
	var sau := track_length + 0.5

	# Va chạm thân tủ: node StaticSurface_Table trong chicken_race.tscn.

	_khoi(Vector3(0.0, than_cao * 0.5, 0.0), Vector3(w + 0.5, than_cao, sau), Color("6b2d3a"))

	# Lòng máng: từng làn một tấm nghiêng riêng, tô màu của con gà chạy trên đó.
	var doc := atan2(bed_rise, track_length)
	var dai := sqrt(track_length * track_length + bed_rise * bed_rise)
	for i in lanes:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(lane_width * 0.92, 0.05, dai)
		m.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLORS[i % COLORS.size()].darkened(0.45)
		m.material_override = mat
		m.position = Vector3(_lane_x(i), _bed_y(0.5) - 0.03, _bed_z(0.5))
		m.rotation.x = -doc
		add_child(m)

	# Vạch xuất phát và vạch đích.
	for p in [0.0, 1.0]:
		var v := MeshInstance3D.new()
		var vm := BoxMesh.new()
		vm.size = Vector3(w, 0.02, 0.06)
		v.mesh = vm
		v.material_override = _mat(Color("f2efe6"))
		v.position = Vector3(0.0, _bed_y(p) + 0.03, _bed_z(p))
		add_child(v)

	# Vòm biển hiệu phía sau, ngay trên vạch đích — giống cái mái của máy Duck Race.
	_khoi(Vector3(0.0, _bed_y(1.0) + 0.75, _bed_z(1.0)), Vector3(w + 0.5, 0.5, 0.16),
			Color("6b2d3a"))
	var bien := Label3D.new()
	bien.text = "DUA GA"
	bien.font_size = 64
	bien.pixel_size = 0.0035
	bien.modulate = Color("f5d90a")
	bien.outline_size = 12
	bien.position = Vector3(0.0, _bed_y(1.0) + 0.75, _bed_z(1.0) - 0.1)
	bien.rotation.y = PI
	add_child(bien)

	# Ô caro dưới biển hiệu, đúng kiểu vạch đích.
	for i in 16:
		var o := MeshInstance3D.new()
		var om := BoxMesh.new()
		om.size = Vector3(w / 16.0, 0.14, 0.04)
		o.mesh = om
		o.material_override = _mat(Color.WHITE if i % 2 == 0 else Color("1a1a1e"))
		o.position = Vector3(-w * 0.5 + (i + 0.5) * w / 16.0, _bed_y(1.0) + 0.42,
				_bed_z(1.0) - 0.06)
		add_child(o)


## Gà là node con của `Chickens` trong chicken_race.tscn, thứ tự node là thứ tự làn. Script chỉ
## tô màu theo làn.
func _build_chickens() -> void:
	for holder: Node3D in $Chickens.get_children():
		for m: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
			m.material_override = _mat(COLORS[_chickens.size() % COLORS.size()])
		_chickens.append(holder)




## Nút đặt cược gắn thẳng vào MẶT TRƯỚC tủ, ngay dưới làn của nó — nhìn là biết nút nào ăn
## với con nào. Nút ĐUA to hơn, đặt bên hông, tách hẳn ra để không bấm nhầm.
func _build_buttons() -> void:
	var packed := load("res://lobby/objects/pressable.tscn") as PackedScene
	var z := _bed_z(0.0) - 0.3
	for i in lanes:
		var b: Pressable = packed.instantiate()
		b.name = "Bet%d" % i
		b.label = ""
		b.color = COLORS[i % COLORS.size()]
		b.compact = true
		# Nút rộng 0.31 m mà làn chỉ cách nhau 0.26 m thì tám nút dính thành một mảng.
		# 0.42 cho ra đường kính 0.13 m — rời hẳn nhau, vẫn thừa sức bấm.
		b.button_scale = 0.42
		b.label_size = 40
		b.press_range = 2.2
		b.position = Vector3(_lane_x(i), bed_height - 0.22, z)
		add_child(b)
		_bet_buttons.append(b)

	# Một dòng nhắc duy nhất cho cả hàng nút, thay cho tám cái nhãn.
	var nhac := Label3D.new()
	nhac.text = "BAM MAU DE TIN"
	nhac.font_size = 34
	nhac.pixel_size = 0.0022
	nhac.modulate = Color("f5d90a")
	nhac.outline_size = 8
	nhac.position = Vector3(0.0, bed_height - 0.44, z - 0.02)
	nhac.rotation.y = PI
	add_child(nhac)

	var play: Pressable = packed.instantiate()
	play.name = "RaceButton"
	play.label = "DUA!"
	play.color = Color("46a758")
	play.compact = true
	play.button_scale = 0.6
	play.label_size = 36
	play.press_range = 2.6
	# Mot cuoc dua keo 7 giay va phat RPC cho moi may. `_net_chicken_race` da tu choi khi dua
	# dang chay, nhung chan ngay tu nut thi khong co cai RPC nao phai gui di ca.
	play.cooldown = 1.5
	play.position = Vector3(_width() * 0.5 + 0.45, bed_height - 0.05, z + 0.1)
	add_child(play)


func _khoi(pos: Vector3, size: Vector3, mau: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = _mat(mau)
	m.position = pos
	add_child(m)


func _mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	return mat
