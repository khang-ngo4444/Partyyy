extends MiniGame3D

## SEARING SPOTLIGHTS — sàn tối đen, đèn quét là nguồn sáng duy nhất. Lọt vào đèn thì mất máu.
##
## Khuôn T2. Khác hai trò kia ở chỗ **có máu**: đây là trò duy nhất không giết ngay trong một
## lần chạm.
##
## ## Tối là tối HẲN
##
## Không thấy nhân vật nào, kể cả của mình. Ai lọt vào vùng đèn thì vừa **bị lộ cho cả phòng
## thấy**, vừa mất máu — và đó cũng là lúc duy nhất họ biết mình đang đứng ở đâu.
##
## Hai thứ BẮT BUỘC, thiếu là trò thành ngẫu nhiên chứ không thành khó:
##
##   1. **Thanh máu luôn hiện** (`ThanhMau` trong `spotlights.tscn`). Không thấy mình ở đâu
##      thì thanh máu là tín hiệu DUY NHẤT báo "đang bị nướng, chạy đi".
##   2. **Mốc định hướng mờ trên sàn** (`VienSan` trong `san_spot.tscn`) — viền sàn phát sáng
##      yếu. Không có gì để bám thì đi trong tối là tung xúc xắc. Đây là NÚM CHỈNH: mốc càng
##      mờ trò càng căng.
##
## ## 0 gói tin
##
## Đường đi của đèn là hàm thuần của `gio()` và hạt giống. Máu trừ cục bộ, hết thì tự khai tử.

const MAU_TOI_DA := 100.0
## Mất bao nhiêu máu mỗi giây khi đứng trong đèn. 100 / 40 = 2,5 giây là chết.
const MAT_MAU_MOI_GIAY := 40.0
## Đèn đi trên quỹ đạo Lissajous quanh tâm sàn, biên độ chừng này.
const TAM_QUET := 7.8

@onready var _thanh: ColorRect = $Lop/ThanhMau/Muc

var _den: Array[Node3D] = []
## Vùng sáng của từng đèn, cùng thứ tự với `_den`.
var _vung: Array[Area3D] = []
var _pha: PackedFloat32Array = PackedFloat32Array()
var _nhip: PackedFloat32Array = PackedFloat32Array()
var mau := MAU_TOI_DA
var _rong_thanh := 0.0


func _ready() -> void:
	super()
	ten = "SEARING SPOTLIGHTS"
	luat = "WASD chạy · tránh vùng sáng · nhớ mình đang đứng đâu"
	giay_van = 75.0
	_rong_thanh = _thanh.size.x


func _dung_san() -> void:
	_den.assign(san.find_children("Den*", "Node3D", false, false))
	_vung.clear()
	for d in _den:
		_vung.append(d.get_node("Vung") as Area3D)
	_pha.resize(_den.size())
	_nhip.resize(_den.size())
	for i in _den.size():
		_pha[i] = _rng.randf() * TAU
		# Nhịp lệch nhau thì hai đèn không bao giờ khoá pha thành một cặp đi song song mãi.
		_nhip[i] = _rng.randf_range(0.28, 0.52)
	mau = MAU_TOI_DA
	$Lop.visible = true
	if _den.is_empty():
		push_error("Spotlights: san khong co node ten Den*")


func dung_som() -> void:
	$Lop.visible = false
	super()


func _luat_moi_nhip() -> void:
	var t := gio()
	for i in _den.size():
		var v := cho_den(_pha[i], _nhip[i], t)
		_den[i].position = Vector3(v.x, _den[i].position.y, v.y)
	_thanh.size.x = _rong_thanh * clampf(mau / MAU_TOI_DA, 0.0, 1.0)


func _toi_thua() -> bool:
	if super():
		return true
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return false
	# Hỏi thẳng `Area3D`: bán kính vùng cháy bằng đúng vệt sáng của nón đèn trong `.tscn`.
	#
	# Bản trước tự tính với `BAN_KINH_DEN = 3.4` trong khi nón đèn (cao 12 m, góc 18°) rọi ra
	# vệt bán kính 3.9 — đứng trong quầng sáng mà không mất máu.
	for v in _vung:
		if v != null and v.overlaps_body(p):
			mau -= MAT_MAU_MOI_GIAY * get_process_delta_time()
			break
	return mau <= 0.0



# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Chỗ của một đèn tại thời điểm `t`. Quỹ đạo Lissajous: hai nhịp lệch nhau nên đường đi không
## khép thành một vòng tròn đoán trước được.
static func cho_den(pha: float, nhip: float, t: float) -> Vector2:
	return Vector2(
			sin(t * nhip + pha) * TAM_QUET,
			sin(t * nhip * 1.37 + pha * 2.0) * TAM_QUET)
