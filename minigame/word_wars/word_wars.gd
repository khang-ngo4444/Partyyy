extends MiniGame3D

## WORD WARS — chữ cái rơi như mưa, đấm đúng thứ tự để ghép thành từ.
##
## Khuôn T3 thứ ba, và là trò T3 duy nhất tốn gói tin — đúng một gói mỗi lần ai đó ghép xong
## một từ. Cả ván cỡ hai chục gói.
##
## ## Cả phòng ghép CHUNG một từ
##
## Từ hiện tại chỉ phụ thuộc `(hạt giống, gio())`, nên mọi máy luôn hiện cùng một từ, và cứ
## `GIAY_MOI_TU` giây thì đổi. Nhờ thế:
##
##   - Không cần ai phát "từ mới là gì" — mọi máy tự biết.
##   - Mưa chữ có thể ưu tiên rải đúng chữ mà từ hiện tại cần, mà vẫn tất định.
##   - Nhiều người ghép xong cùng một từ đều được điểm: không có gì để tranh, nên không cần
##     trọng tài.
##
## ## Khối chữ KHÔNG bị tiêu thụ
##
## Đấm một khối là mình nhận chữ đó, khối vẫn nằm nguyên cho người khác đấm. Cho biến mất thì
## lập tức sinh ra câu hỏi "ai đấm trước" — một câu hỏi phải có trọng tài trả lời, chỉ để đổi
## lấy đúng một chút kịch tính. Không đáng.
##
## ## Đấm sai thì sao
##
## Không sao cả. Chỉ chữ ĐÚNG KẾ TIẾP mới được nhận. Phạt (xoá tiến độ) nghe có vẻ căng hơn,
## nhưng giữa một cơn mưa chữ thì nó chỉ dạy người chơi đứng yên không dám đấm.

## Nút đấm. Cùng phím với cầu lửa của Magma — trong sân không có gì để nhặt nên phím này rảnh.
const NUT_DAM := "interact"
## Nghỉ giữa hai cú đấm, giây.
const NGHI_DAM := 0.25
## Cả phòng đổi sang từ mới sau chừng này giây.
const GIAY_MOI_TU := 9.0
## Mưa chữ: chừng này giây một khối.
const NHIP_ROI := 0.45
## Khối rơi trong bán kính này. Sàn tròn bán kính 11,5 m.
const BAN_KINH_ROI := 10.0
## Bao nhiêu phần khối rơi là chữ mà từ hiện tại đang cần. Phần còn lại là chữ nhiễu — không có
## nhiễu thì sân chỉ toàn ba chữ và ghép từ thành chuyện nhặt đồ, không phải chuyện tìm.
const TI_LE_CHU_CAN := 0.55

const TU := ["NHA", "CUA", "BAN", "MEO", "CHO", "HOA", "CAY", "SAO", "MUA", "GIO",
		"NUI", "TRE", "COM", "PHO", "BIEN", "SONG", "BANH", "CHAM", "XANH", "TRANG"]
const CHU_NHIEU := "ABCDEGHIKLMNOPQRSTUVXY"

@export var khoi_scene: PackedScene = null

var _bang: Label3D = null
var _khoi: Array[KhoiChu] = []
## Lịch mưa chữ sinh từ hạt giống: `[{"luc": giây, "chu": "A", "cho": Vector3}]`.
var _lich: Array = []
var _ke_tiep := 0
## Đã ghép đúng mấy chữ đầu của từ hiện tại.
var _tien := 0
## Chỉ số từ mà `_tien` đang nói về — đổi từ thì tiến độ về 0.
var _tu_dang := -1
var _dam_luc := -99.0
## player_id -> số từ đã ghép xong. Mọi máy cùng cộng từ RPC; bảng của master là bảng chốt.
var _diem: Dictionary = {}


func _ready() -> void:
	super()
	ten = "WORD WARS"
	luat = "WASD chạy · E đấm khối chữ · ghép đúng thứ tự thành từ trên bảng"
	giay_van = 60.0


func _dung_san() -> void:
	_bang = san.get_node_or_null("Bang") as Label3D
	_khoi.clear()
	_lich = lich_mua(hat_giong)
	_ke_tiep = 0
	_tien = 0
	_tu_dang = -1
	_dam_luc = -99.0
	_diem.clear()
	for id in _song:
		_diem[int(id)] = 0
	if _bang == null:
		push_error("WordWars: san thieu node Bang")


func _luat_moi_nhip() -> void:
	var t := gio()
	var i_tu := chi_so_tu(t)
	if i_tu != _tu_dang:
		_tu_dang = i_tu
		_tien = 0
	while _ke_tiep < _lich.size() and t >= float(_lich[_ke_tiep]["luc"]):
		_roi(_lich[_ke_tiep])
		_ke_tiep += 1
	_khoi = _khoi.filter(func(k: KhoiChu) -> bool: return is_instance_valid(k))
	if _bang != null:
		var tu := tu_luc(t)
		_bang.text = "%s\n%s   ·   %d từ" % [
				" ".join(tu.split()), _da_ghep(tu), int(_diem.get(NetManager.local_id(), 0))]


func _unhandled_input(event: InputEvent) -> void:
	if not _chay or not event.is_action_pressed(NUT_DAM):
		return
	if gio() - _dam_luc < NGHI_DAM:
		return
	var p := _nguoi(NetManager.local_id())
	if p == null or not con_song(NetManager.local_id()):
		return
	get_viewport().set_input_as_handled()
	_dam_luc = gio()
	_dam(p)


## Đấm: nhận chữ nếu đúng chữ kế tiếp của từ đang hiện.
##
## Hỏi thẳng `Area3D` của từng khối — tầm đấm CHÍNH LÀ cái khối nhìn thấy, không phải một con
## số bán kính chép tay trong code.
func _dam(p: Player) -> void:
	var tu := tu_luc(gio())
	if _tien >= tu.length():
		return
	var can := tu[_tien]
	for k in _khoi:
		if k.chu != can or not k.vung.overlaps_body(p):
			continue
		_tien += 1
		if _tien >= tu.length():
			_tien = 0
			Fusion.rpc(_net_xong_tu, NetManager.local_id())
		return


## Một gói cho một từ ghép xong. Không ai phải duyệt: nhiều người cùng ghép xong một từ đều
## được tính, nên không có gì để tranh.
@rpc("any_peer", "call_local")
func _net_xong_tu(id: int) -> void:
	if _diem.has(id):
		_diem[id] = int(_diem[id]) + 1


func _roi(muc: Dictionary) -> void:
	if san == null or khoi_scene == null:
		return
	var k := khoi_scene.instantiate() as KhoiChu
	san.add_child(k)
	k.dat(String(muc["chu"]), san.global_position + (muc["cho"] as Vector3))
	_khoi.append(k)


func _da_ghep(tu: String) -> String:
	return tu.substr(0, _tien).rpad(tu.length(), "_")


# ───────────────────────── xếp hạng theo số từ ─────────────────────────

func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _diem:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool: return int(_diem[a]) > int(_diem[b]))
	Fusion.rpc(_net_xep_hang, xep)


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Từ thứ mấy đang hiện tại thời điểm `t`.
static func chi_so_tu(t: float) -> int:
	return int(t / GIAY_MOI_TU)


## Từ đang hiện tại thời điểm `t`. Chỉ phụ thuộc `t` nên mọi máy luôn hiện cùng một từ.
static func tu_luc(t: float) -> String:
	return TU[chi_so_tu(t) % TU.size()]


## Toàn bộ cơn mưa chữ của một ván, suy ra từ hạt giống.
static func lich_mua(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	var t := 1.0
	while t < 90.0:
		var tu := tu_luc(t)
		var chu: String
		if rng.randf() < TI_LE_CHU_CAN:
			chu = tu[rng.randi() % tu.length()]
		else:
			chu = CHU_NHIEU[rng.randi() % CHU_NHIEU.length()]
		var a := rng.randf() * TAU
		# `sqrt` để khối rải đều trên mặt sàn chứ không dồn về tâm.
		var r := sqrt(rng.randf()) * BAN_KINH_ROI
		ds.append({"luc": t, "chu": chu, "cho": Vector3(cos(a) * r, 0.0, sin(a) * r)})
		t += NHIP_ROI
	return ds
