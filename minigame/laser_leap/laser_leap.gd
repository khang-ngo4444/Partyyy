extends MiniGame3D

## LASER LEAP — tia quét sát mặt sàn, nhảy qua. Càng lúc càng nhanh.
##
## Khuôn T2, dùng lại nguyên khung của Breaking Blocks. Trò này **không giới hạn giờ**: tốc độ
## tăng đều nên kiểu gì cũng tới lúc không ai qua nổi, ván tự kết thúc.
##
## ## 0 gói tin
##
## Góc mỗi tia là hàm thuần của `gio()` và pha lấy từ hạt giống. Va chạm thì mỗi máy chỉ kiểm
## nhân vật CỦA MÌNH rồi tự khai tử.
##
## ## Vì sao tia QUAY quanh tâm chứ không trượt ngang
##
## Tia trượt ngang thì đứng ở mép sàn là cả ván không phải nhảy lần nào. Tia quay quanh tâm
## quét qua MỌI chỗ trên sàn nên không có góc an toàn — và người đứng ngoài rìa còn phải nhảy
## sớm hơn vì đầu tia ở đó đi nhanh hơn.

## Nhảy cao hơn mặt sàn chừng này thì tia lướt qua bên dưới.
const CAO_THOAT := 0.9
## Tốc độ quay lúc đầu và lúc cuối, radian/giây.
const TOC_DAU := 0.55
const TOC_CUOI := 1.9
## Tăng hết tốc sau chừng này giây.
const GIAY_TANG_HET := 60.0

var _tia: Array[Node3D] = []
## Vùng va chạm của từng tia, cùng thứ tự với `_tia`.
var _vung: Array[Area3D] = []
var _pha: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	super()
	ten = "LASER LEAP"
	luat = "WASD chạy · Space nhảy qua tia · càng lúc càng nhanh"
	giay_van = 0.0                      # không giới hạn: tốc độ tăng sẽ tự kết thúc ván


func _dung_san() -> void:
	_tia.assign(san.find_children("Tia*", "Node3D", false, false))
	_vung.clear()
	for t in _tia:
		_vung.append(t.get_node("Vung") as Area3D)
	_pha.resize(_tia.size())
	for i in _tia.size():
		# Rải đều quanh vòng rồi xê dịch chút theo hạt giống — đều tuyệt đối thì đoán được.
		_pha[i] = PI * i / float(maxi(_tia.size(), 1)) + _rng.randf_range(-0.3, 0.3)
	if _tia.is_empty():
		push_error("LaserLeap: san khong co node ten Tia*")


func _luat_moi_nhip() -> void:
	var t := gio()
	for i in _tia.size():
		_tia[i].rotation.y = goc_tia(_pha[i], t)


## Ghi đè chứ không thêm hàm mới: sàn tròn nên chạy quá đà vẫn rơi, phải giữ cả luật của lớp cha.
func _toi_thua() -> bool:
	if super():
		return true
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return false
	if p.global_position.y - san.global_position.y > CAO_THOAT:
		return false                    # đang ở trên không, tia lướt dưới chân
	# Hỏi thẳng `Area3D` chứ KHÔNG tự tính hình học: hộp va chạm và thanh tia nhìn thấy là
	# cùng một kích thước trong `.tscn`, nên chúng không thể lệch nhau.
	#
	# Bản trước tự tính với `BE_DAY = 0.55` trong khi mesh rộng 0.70 — người chơi đứng RÕ RÀNG
	# trong tia mà không chết. Đúng loại lỗi mà một con số chép tay ở hai nơi luôn đẻ ra.
	for v in _vung:
		if v != null and v.overlaps_body(p):
			return true
	return false


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Tốc độ quay tại thời điểm `t`, tăng tuyến tính rồi dừng.
static func toc_do(t: float) -> float:
	return lerpf(TOC_DAU, TOC_CUOI, clampf(t / GIAY_TANG_HET, 0.0, 1.0))


## Góc của một tia tại thời điểm `t`. Công thức nằm ở `MiniGame3D.goc_quay()` — thanh xoay của
## Snowy Spin dùng chung.
static func goc_tia(pha: float, t: float) -> float:
	return goc_quay(pha, t, TOC_DAU, TOC_CUOI, GIAY_TANG_HET)
