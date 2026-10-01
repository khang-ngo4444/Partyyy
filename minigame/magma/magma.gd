extends MiniGame3D

## MAGMA & MAGES — vùng an toàn co theo chặng, bắn cầu lửa hất nhau vào dung nham.
##
## Khuôn T1, trò duy nhất có **nút đòn**. Dựng trên đúng `MiniGame3D` của T2 — sàn, camera,
## teleport vào/ra, đếm giờ, xếp hạng, đường về đều dùng lại, không viết lại dòng nào.
##
## ## Ai quyết ai bị hất
##
## **Không ai cả.** Người bắn phát một gói `(điểm bắn, hướng)`; mọi máy tự dựng quả cầu và tự cho
## nó bay. Mỗi máy chỉ kiểm quả cầu với nhân vật CỦA CHÍNH MÌNH, trúng thì tự áp lực đẩy lên mình.
##
## Không trọng tài, không tranh chấp, không một gói tin nào để giải quyết bất đồng — vì không bao
## giờ có bất đồng để giải quyết.
##
## ## Ba vùng, và vì sao sàn KHÔNG co nữa
##
## Bản trước cho cả `SanTron` co lại: ngoài sàn là hư không, bước ra là rơi và chết ngay. Hai
## chỗ sai:
##
##   1. **Dung nham không "ăn" sàn gì cả.** Nó là một mặt phẳng trang trí ở `y = -6`, chỉ để rơi
##      xuống. Sàn thì tự biến mất. Không có chặng nào để mà cảnh báo.
##   2. **Chạm nhẹ là chết ngay.** Lùi một bước quá đà = rơi = hết. Không có chỗ cho "bị hất vào
##      nham, cháy một tí, bò ra" — tức không có chỗ cho chính cái combat của trò này.
##
## Giờ sàn giữ nguyên cỡ và **chính nó là dung nham**; hai cái đĩa mỏng chồng lên đánh dấu vùng:
##
## | Vùng | Node | Nghĩa |
## |---|---|---|
## | Trong `VungAnToan` | đĩa nhạt | an toàn, và còn an toàn qua lần co tới |
## | Vành giữa hai đĩa | đĩa đỏ hở ra | **CẢNH BÁO** — còn an toàn, sắp thành nham |
## | Ngoài `VungBao` | mặt sàn cam | **NHAM** — đứng là mất máu |
##
## Vành cảnh báo chỉ hở ra trong `GIAY_BAO` giây trước mỗi lần co, nên lúc bình thường cả vùng an
## toàn trông liền một màu. Nó hở ra là một dấu hiệu rõ ràng, không phải một vạch bò chậm.
##
## ## Vì sao co theo CHẶNG chứ không co đều
##
## Co đều từ 1,0 xuống 0,45 trong 43 giây là 0,147 m/s. Báo trước 4 giây thì vành cảnh báo rộng
## 0,6 m — nhìn từ camera trên cao gần như không thấy, và nó đọc như một vạch trôi chứ không như
## "khoanh này sắp mất". Co theo chặng cho vành rộng 1,38 m, hở ra dứt khoát.
##
## ## Chết vì MÁU, không vì rơi
##
## Vị trí bị kẹp trong lòng sàn nên không ai ra khỏi sân được. Đòn cầu lửa giờ hất người ta vào
## NHAM chứ không hất xuống vực — vẫn đúng ý "hất nhau vào dung nham", nhưng người bị hất có cơ
## hội bò ra.
##
## ponytail: máu + thanh máu CHÉP từ `spotlights.gd` chứ không tách ra chỗ dùng chung. Hai trò
## dùng thì chép rẻ hơn dựng một tầng mới; trò thứ ba cần máu thì lúc đó hãy tách.

## Nút bắn. `interact` (E) — trong sân không có vật nào để nhặt nên phím này rảnh.
const NUT_BAN := "interact"
## Nghỉ giữa hai phát, giây. Không có thì giữ phím là một vòi lửa liền mạch.
const NGHI_BAN := 0.7
## Cầu lửa rời tay ở độ cao này, để nó bay ngang tầm ngực chứ không lết dưới sàn.
const CAO_BAN := 1.0
## Bị trúng thì bị hất mạnh cỡ nào — ngang và dốc lên.
const DAY_NGANG := 11.0
const DAY_LEN := 4.5

## Vùng an toàn co mấy lần, và co xuống còn bấy nhiêu phần bán kính.
const SO_CHANG := 5
const CO_CON := 0.40
## Giữ nguyên sàn chừng này giây đầu — chừa thời gian hiểu luật và tìm chỗ đứng.
const CHO_TRUOC_KHI_CO := 10.0
## Mỗi chặng dài bao lâu.
const GIAY_MOI_CHANG := 11.0
## Vành cảnh báo hở ra trước lần co chừng này giây. Đây là NÚM CHỈNH quan trọng nhất: ngắn quá
## thì không kịp chạy, dài quá thì vùng an toàn thật trông bé hơn thực tế suốt ván.
const GIAY_BAO := 4.0

## Máu và tốc cháy khi đứng trong nham.
##
## 100 / 22 ≈ 4,5 giây là chết — đủ đau để phải bò ra ngay, nhưng bị hất vào nham một cái không
## phải là xong. Spotlights dùng 40/giây vì ở đó vùng sáng nhỏ và tránh được; nham thì chiếm cả
## vành ngoài, không ai đi vòng tránh được.
const MAU_TOI_DA := 100.0
const MAT_MAU_MOI_GIAY := 22.0

@export var cau_lua_scene: PackedScene = null

@onready var _thanh: ColorRect = $Lop/ThanhMau/Muc

var _san_tron: Node3D = null
var _vung_bao: Node3D = null
var _vung_an_toan: Node3D = null
var _cau: Array[CauLua] = []
var _ban_luc := -99.0
var mau := MAU_TOI_DA
var _rong_thanh := 0.0
## Bán kính sàn, ĐỌC từ mesh chứ không chép tay — `ti_le_san()` chỉ trả về tỉ lệ.
var _ban_kinh := 11.5


func _ready() -> void:
	super()
	ten = "MAGMA & MAGES"
	luat = "WASD chạy · E bắn cầu lửa · vành đỏ sắp thành nham · hất nhau vào nham"
	giay_van = 75.0
	_rong_thanh = _thanh.size.x


func _dung_san() -> void:
	_san_tron = san.get_node_or_null("SanTron") as Node3D
	_vung_bao = san.get_node_or_null("VungBao") as Node3D
	_vung_an_toan = san.get_node_or_null("VungAnToan") as Node3D
	_cau.clear()
	_ban_luc = -99.0
	mau = MAU_TOI_DA
	$Lop.visible = true
	if _san_tron == null or _vung_bao == null or _vung_an_toan == null:
		push_error("Magma: san thieu SanTron / VungBao / VungAnToan")
		return
	var m := _san_tron.get_node_or_null("Mat") as MeshInstance3D
	var cyl := m.mesh as CylinderMesh if m != null else null
	if cyl != null:
		_ban_kinh = cyl.top_radius
	_ve_vung(0.0)


func dung_som() -> void:
	$Lop.visible = false
	super()


func _luat_moi_nhip() -> void:
	var t := gio()
	_ve_vung(t)
	_cau = _cau.filter(func(c: CauLua) -> bool: return is_instance_valid(c))
	_thanh.size.x = _rong_thanh * clampf(mau / MAU_TOI_DA, 0.0, 1.0)
	if con_song(NetManager.local_id()):
		_giu_tren_san()
		_an_mau(t)


## Hai đĩa đánh dấu vùng. Sàn giữ nguyên cỡ — chỉ hai cái đĩa này co.
func _ve_vung(t: float) -> void:
	_vung_bao.scale = Vector3(ti_le_san(t), 1.0, ti_le_san(t))
	var b := ti_le_bao(t)
	_vung_an_toan.scale = Vector3(b, 1.0, b)


## Kẹp nhân vật CỦA MÁY NÀY trong lòng sàn. Chỉ `is_mine` — kéo người khác là đánh nhau với
## replicator đang gửi vị trí của họ.
##
## Kẹp ở mép sàn, KHÔNG kẹp ở mép vùng an toàn: bị đẩy vào nham là một phần của trò.
func _giu_tren_san() -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	var l := p.global_position - san.global_position
	var r := Vector2(l.x, l.z)
	var toi_da := _ban_kinh - 0.5
	if r.length() <= toi_da:
		return
	r = r.normalized() * toi_da
	p.global_position = san.global_position + Vector3(r.x, l.y, r.y)


## Cháy nếu đang ở NGOÀI vùng an toàn.
##
## Mốc tính là `ti_le_san(t) * _ban_kinh`, đúng bằng mép đĩa `VungBao` nhìn thấy — một công thức
## cho cả hình và sát thương, nên chúng không thể lệch nhau.
func _an_mau(t: float) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	var l := p.global_position - san.global_position
	if Vector2(l.x, l.z).length() > ti_le_san(t) * _ban_kinh:
		mau -= MAT_MAU_MOI_GIAY * get_process_delta_time()


## Ghi đè: cầu lửa HẤT chứ không giết; chết là do hết máu.
##
## Vẫn gọi `super()` ở cuối: kẹp vị trí chặn được việc đi ra khỏi sàn, nhưng nếu một ngày vật lý
## đẩy ai xuyên qua mặt sàn thì lưới đỡ của lớp cha vẫn phải ở đó.
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
	return mau <= 0.0 or super()


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

## Chặng thứ mấy tại giây `t`. 0 = chưa co lần nào, `SO_CHANG` = đã co hết.
static func chang(t: float) -> int:
	if t < CHO_TRUOC_KHI_CO:
		return 0
	return mini(1 + int((t - CHO_TRUOC_KHI_CO) / GIAY_MOI_CHANG), SO_CHANG)


## Lần co kế tiếp xảy ra ở giây nào. Trả về `INF` nếu đã co hết.
static func luc_co_ke_tiep(t: float) -> float:
	var c := chang(t)
	if c >= SO_CHANG:
		return INF
	return CHO_TRUOC_KHI_CO + float(c) * GIAY_MOI_CHANG


## Tỉ lệ bán kính vùng an toàn tại giây `t`. Bậc thang: đứng yên trong một chặng rồi tụt một bậc.
static func ti_le_san(t: float) -> float:
	return lerpf(1.0, CO_CON, float(chang(t)) / float(SO_CHANG))


## Tỉ lệ của phần CÒN an toàn sau lần co tới.
##
## Ngoài cửa sổ cảnh báo thì bằng đúng `ti_le_san()` — hai đĩa trùng nhau nên không thấy vành
## nào, cả vùng an toàn liền một màu. Trong cửa sổ cảnh báo thì tụt sẵn một bậc, để hở ra cái
## vành sắp thành nham.
static func ti_le_bao(t: float) -> float:
	var ke := luc_co_ke_tiep(t)
	if ke == INF or t < ke - GIAY_BAO:
		return ti_le_san(t)
	return lerpf(1.0, CO_CON, float(chang(t) + 1) / float(SO_CHANG))

