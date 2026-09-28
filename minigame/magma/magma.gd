extends MiniGame3D

## MAGMA & MAGES — bắn cầu lửa hất nhau khỏi sàn đang co dần vào dung nham.
##
## Khuôn T1, trò đầu tiên có **nút đòn**. Dựng trên đúng `MiniGame3D` của T2 — sàn, camera,
## teleport vào/ra, đếm giờ, xếp hạng, đường về đều dùng lại, không viết lại dòng nào.
##
## ## Ai quyết ai bị hất
##
## **Không ai cả.** Người bắn phát một gói `(điểm bắn, hướng)`; mọi máy tự dựng quả cầu và tự
## cho nó bay. Mỗi máy chỉ kiểm quả cầu với nhân vật CỦA CHÍNH MÌNH, trúng thì **tự áp lực đẩy
## lên mình**, rơi khỏi sàn thì **tự khai tử**.
##
## Không trọng tài, không tranh chấp, không một gói tin nào để giải quyết bất đồng — vì không
## bao giờ có bất đồng để giải quyết.
##
## ## Sàn co dần
##
## Đây là thứ bảo đảm ván kết thúc. Người chơi giỏi có thể né hết cầu lửa, nhưng không ai né
## được cái sàn biến mất dưới chân. Co theo hàm của `gio()` nên mọi máy thấy sàn một cỡ.

## Nút bắn. `interact` (E) — trong sân không có vật nào để nhặt nên phím này rảnh.
const NUT_BAN := "interact"
## Nghỉ giữa hai phát, giây. Không có thì giữ phím là một vòi lửa liền mạch.
const NGHI_BAN := 0.7
## Cầu lửa rời tay ở độ cao này, để nó bay ngang tầm ngực chứ không lết dưới sàn.
const CAO_BAN := 1.0
## Bị trúng thì bị hất mạnh cỡ nào — ngang và dốc lên.
const DAY_NGANG := 11.0
const DAY_LEN := 4.5

## Sàn co từ tỉ lệ 1.0 xuống còn bấy nhiêu.
const CO_CON := 0.45
## Bắt đầu co sau chừng này giây — chừa thời gian cho người chơi hiểu luật trước đã.
const CHO_TRUOC_KHI_CO := 12.0
## Co hết cỡ sau chừng này giây.
const CO_HET_LUC := 55.0

@export var cau_lua_scene: PackedScene = null

var _san_tron: Node3D = null
var _cau: Array[CauLua] = []
var _ban_luc := -99.0


func _ready() -> void:
	super()
	ten = "MAGMA & MAGES"
	luat = "WASD chạy · E bắn cầu lửa · hất nhau xuống dung nham"
	giay_van = 75.0


func _dung_san() -> void:
	_san_tron = san.get_node_or_null("SanTron") as Node3D
	_cau.clear()
	_ban_luc = -99.0
	if _san_tron == null:
		push_error("Magma: san thieu node SanTron")


func _luat_moi_nhip() -> void:
	if _san_tron != null:
		var k := ti_le_san(gio())
		_san_tron.scale = Vector3.ONE * k
	_cau = _cau.filter(func(c: CauLua) -> bool: return is_instance_valid(c))


## Ghi đè: ngoài rơi khỏi sàn (lớp cha lo), còn phải kiểm cầu lửa.
##
## Trúng đạn KHÔNG giết — nó chỉ hất. Chết là do rơi khỏi sàn. Nên hàm này áp lực đẩy rồi vẫn
## trả về kết quả của lớp cha.
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	if p != null:
		for c in _cau:
			if c.nguoi_ban == NetManager.local_id() or not c.overlaps_body(p):
				continue
			# Hướng hất = từ quả cầu ra ngoài, tính theo mặt phẳng ngang.
			var huong := p.global_position - c.global_position
			huong.y = 0.0
			p.day(huong.normalized() * DAY_NGANG + Vector3.UP * DAY_LEN)
			c.queue_free()
			break
	return super()


func _unhandled_input(event: InputEvent) -> void:
	if not _chay or not event.is_action_pressed(NUT_BAN):
		return
	if gio() - _ban_luc < NGHI_BAN:
		return
	var p := _nguoi(NetManager.local_id())
	if p == null or not con_song(NetManager.local_id()):
		return
	get_viewport().set_input_as_handled()
	_ban_luc = gio()
	# Bắn theo hướng thân đang quay — ở chế độ sân, thân tự quay theo hướng chạy.
	var huong := -p.global_transform.basis.z
	huong.y = 0.0
	Fusion.rpc(_net_ban, NetManager.local_id(),
			p.global_position + Vector3.UP * CAO_BAN, huong.normalized())


## Một gói cho cả đời quả cầu. Mọi máy tự dựng và tự cho nó bay — không gửi vị trí lần nào nữa.
@rpc("any_peer", "call_local")
func _net_ban(id: int, tu: Vector3, huong: Vector3) -> void:
	if san == null or cau_lua_scene == null:
		return
	var c := cau_lua_scene.instantiate() as CauLua
	san.add_child(c)
	c.ban(tu, huong, id)
	_cau.append(c)


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Tỉ lệ sàn tại thời điểm `t`: giữ nguyên một lúc rồi co đều xuống `CO_CON`.
static func ti_le_san(t: float) -> float:
	if t <= CHO_TRUOC_KHI_CO:
		return 1.0
	var k := clampf((t - CHO_TRUOC_KHI_CO) / (CO_HET_LUC - CHO_TRUOC_KHI_CO), 0.0, 1.0)
	return lerpf(1.0, CO_CON, k)
