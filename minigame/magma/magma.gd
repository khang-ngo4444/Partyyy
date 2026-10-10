extends MiniGame3D

## MAGMA & MAGES — vùng an toàn co theo chặng, bắn cầu lửa hất nhau vào dung nham.
## Ngoài vùng an toàn là nham (mất máu); vành đỏ hở ra `GIAY_BAO` giây trước mỗi lần co.
## Người bắn gửi một gói (điểm, hướng); mỗi máy tự kiểm cầu lửa với nhân vật của mình.

## Nút bắn (cùng action với đòn đánh ở trò khác).
const NUT_BAN := "danh"

## Nghỉ giữa hai phát (giây).
const NGHI_BAN := 0.7

## Cầu lửa bay ngang tầm ngực.
const CAO_BAN := 1.0

## Lực hất (ngang, lên).
const DAY_NGANG := 11.0
const DAY_LEN := 4.5

## Số lần co và tỉ lệ bán kính cuối.
const SO_CHANG := 5
const CO_CON := 0.40

## Giữ nguyên sàn chừng này giây đầu.
const CHO_TRUOC_KHI_CO := 10.0
const GIAY_MOI_CHANG := 11.0

## Vành cảnh báo hở ra trước lần co chừng này giây.
const GIAY_BAO := 4.0

## Máu mất mỗi giây trong nham (máu đầy 100).
const MAT_MAU_MOI_GIAY := 22.0

@export var cau_lua_scene: PackedScene = null

var _san_tron: Node3D = null
var _vung_bao: Node3D = null
var _vung_an_toan: Node3D = null
var _cau: Array[CauLua] = []
var _ban_luc := -99.0

## Đọc từ mesh sàn.
var _ban_kinh := 11.5

@onready var _thanh: ThanhMau = $ThanhMau


func _ready() -> void:
	super()
	ten = "MAGMA & MAGES"
	luat = "WASD chạy · chuột trái bắn cầu lửa · vành đỏ sắp thành nham · hất nhau vào nham"
	giay_van = 75.0


func _dung_san() -> void:
	_san_tron = san.get_node_or_null("SanTron") as Node3D
	_vung_bao = san.get_node_or_null("VungBao") as Node3D
	_vung_an_toan = san.get_node_or_null("VungAnToan") as Node3D
	_cau.clear()
	_ban_luc = -99.0
	_thanh.mo()
	if _san_tron == null or _vung_bao == null or _vung_an_toan == null:
		push_error("Magma: san thieu SanTron / VungBao / VungAnToan")
		return
	var m := _san_tron.get_node_or_null("Mat") as MeshInstance3D
	var cyl := m.mesh as CylinderMesh if m != null else null
	if cyl != null:
		_ban_kinh = cyl.top_radius
	_ve_vung(0.0)


func dung_som() -> void:
	_thanh.dong()
	super()


func _luat_moi_nhip() -> void:
	var t := gio()
	_ve_vung(t)
	# Lambda không kiểu: quả đã free không ép được sang CauLua.
	_cau.assign(_cau.filter(func(c) -> bool: return is_instance_valid(c)))
	if con_song(NetManager.local_id()):
		_an_mau(t)


## Hai đĩa đánh dấu vùng co theo thời gian.
func _ve_vung(t: float) -> void:
	_vung_bao.scale = Vector3(ti_le_san(t), 1.0, ti_le_san(t))
	var b := ti_le_bao(t)
	_vung_an_toan.scale = Vector3(b, 1.0, b)


## Cháy nếu ở ngoài vùng an toàn (cùng công thức với mép đĩa).
func _an_mau(t: float) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	var l := p.global_position - san.global_position
	if Vector2(l.x, l.z).length() > ti_le_san(t) * _ban_kinh:
		_thanh.tru(MAT_MAU_MOI_GIAY, get_process_delta_time())


## Cầu lửa hất chứ không giết; hết máu hoặc rơi khỏi sàn mới thua.
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	if p != null:
		for c in _cau:
			if c.nguoi_ban == NetManager.local_id() or not c.overlaps_body(p):
				continue
			var huong := p.global_position - c.global_position
			huong.y = 0.0
			p.day(huong.normalized() * DAY_NGANG + Vector3.UP * DAY_LEN)
			c.queue_free()
			break
	return _thanh.het() or super()


## Đọc chuột ở `_input` vì GUI có thể nuốt click.
func _input(event: InputEvent) -> void:
	if not _chay or not event.is_action_pressed(NUT_BAN):
		return
	if gio() - _ban_luc < NGHI_BAN:
		return
	var p := _nguoi(NetManager.local_id())
	if p == null or not con_song(NetManager.local_id()):
		return
	get_viewport().set_input_as_handled()
	_ban_luc = gio()
	# Bắn theo hướng thân.
	var huong := -p.global_transform.basis.z
	huong.y = 0.0
	Fusion.rpc(_net_ban, NetManager.local_id(),
			p.global_position + Vector3.UP * CAO_BAN, huong.normalized())


## Một gói cho cả đời quả cầu; mọi máy tự cho nó bay.
@rpc("any_peer", "call_local")
func _net_ban(id: int, tu: Vector3, huong: Vector3) -> void:
	if san == null or cau_lua_scene == null:
		return
	var c := cau_lua_scene.instantiate() as CauLua
	san.add_child(c)
	# Bù nửa RTT cho cầu của người khác (tối đa 0,15 s).
	var tre := 0.0 if id == NetManager.local_id() else minf(NetManager.rtt_ms() / 2000.0, 0.15)
	c.ban(tu, huong, id, tre)
	_cau.append(c)


# ─── luật: hàm thuần ───


## 0 = chưa co, `SO_CHANG` = co hết.
static func chang(t: float) -> int:
	if t < CHO_TRUOC_KHI_CO:
		return 0
	return mini(1 + int((t - CHO_TRUOC_KHI_CO) / GIAY_MOI_CHANG), SO_CHANG)


## `INF` = đã co hết.
static func luc_co_ke_tiep(t: float) -> float:
	var c := chang(t)
	if c >= SO_CHANG:
		return INF
	return CHO_TRUOC_KHI_CO + float(c) * GIAY_MOI_CHANG


## Tỉ lệ bán kính vùng an toàn (bậc thang).
static func ti_le_san(t: float) -> float:
	return lerpf(1.0, CO_CON, float(chang(t)) / float(SO_CHANG))


## Tỉ lệ phần còn an toàn sau lần co tới (tụt sẵn một bậc trong cửa sổ cảnh báo).
static func ti_le_bao(t: float) -> float:
	var ke := luc_co_ke_tiep(t)
	if ke == INF or t < ke - GIAY_BAO:
		return ti_le_san(t)
	return lerpf(1.0, CO_CON, float(chang(t) + 1) / float(SO_CHANG))
