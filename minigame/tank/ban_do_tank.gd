class_name BanDoTank
extends Node2D

## Đấu trường Tank: một LƯỚI Ô, tường đặt sẵn trong scene.
##
## ## Script này KHÔNG dựng ô nào
##
## Mọi viên gạch, mọi khối thép là instance của `o_tuong.tscn` nằm trong `ban_do_tank.tscn`,
## kéo được trong editor. Ở đây chỉ còn câu hỏi mà phần chơi cần trả lời — điểm này có tường
## không, viên đạn vừa trúng ô số mấy, người chơi thứ ba sinh ở đâu. Giống hệt cách
## `ban_duong.gd` phục vụ bàn party.
##
## Làm bản đồ khác = tạo một `.tscn` khác rồi trỏ `TankBattle.ban_do_scene` sang nó.
##
## ## Vì sao bản đồ CỐ ĐỊNH chứ không sinh ngẫu nhiên
##
## Bản đồ cũ rải gạch bằng `rng.randf() < 0.42`: mỗi ván một mớ nhiễu khác nhau, chỗ thì hở
## toang, chỗ thì nhốt người chơi trong hốc. Bản đồ dựng tay đối xứng bốn phía nên không góc
## nào lợi hơn góc nào, và ai chơi vài ván là thuộc đường — thuộc đường mới có chỗ cho kỹ
## năng. Đổi lại thì mất tính bất ngờ; chỗ sinh xoay theo hạt giống bù lại phần đó.
##
## Ngoài biên coi như THÉP — nhờ vậy không cần rải một vòng 80 ô tường quanh rìa chỉ để chặn.
## Viền nhìn thấy là mấy thanh `ColorRect` trong scene, không tham gia va chạm.

const O := 32.0
## Ô trống. Để ngoài enum `OTuong.Loai` vì ô trống KHÔNG phải một loại tường — nó là chỗ
## không có node nào.
const TRONG := -1

@export var rong := 25
@export var cao := 17

## Ô -> node tường, `null` là trống. Một mảng phẳng, tra bằng `y * rong + x`.
var _tuong: Array[OTuong] = []
var _cho: Array[Vector2] = []


func _ready() -> void:
	_tuong.resize(rong * cao)
	for t: OTuong in find_children("*", "OTuong", true, false):
		var i := chi_so_tai(to_local(t.global_position))
		if i >= 0:
			_tuong[i] = t
	for m: Marker2D in find_children("*", "Marker2D", true, false):
		_cho.append(to_local(m.global_position))
	if _cho.is_empty():
		push_error("BanDoTank: '%s' khong co Marker2D nao. Ban do phai co cho sinh." % name)


func kich_thuoc() -> Vector2:
	return Vector2(rong, cao) * O


## Chỗ sinh, theo thứ tự đã xếp sẵn trong scene: hai chỗ liền nhau luôn ở xa nhau, nên phòng
## ba người hay phòng mười người đều không ai sinh sát mặt ai.
func cho_sinh() -> Array[Vector2]:
	return _cho


## Loại tường tại một điểm: `TRONG`, `OTuong.Loai.GACH` hoặc `OTuong.Loai.THEP`.
func loai_tai(p: Vector2) -> int:
	var i := chi_so_tai(p)
	if i < 0:
		return OTuong.Loai.THEP           # ngoài biên: tường cứng, đạn tan, xe không ra được
	return _tuong[i].loai if _tuong[i] != null else TRONG


## Số hiệu ô chứa điểm `p`, hoặc -1 nếu ra ngoài bản đồ. Đạn gửi số này qua mạng chứ không
## gửi toạ độ — một số nguyên là đủ để mọi máy phá đúng viên gạch đó.
func chi_so_tai(p: Vector2) -> int:
	var x := floori(p.x / O)
	var y := floori(p.y / O)
	if x < 0 or y < 0 or x >= rong or y >= cao:
		return -1
	return y * rong + x


## Phá một viên gạch. Thép không vỡ, ô trống không có gì để phá.
func pha(ix: int) -> void:
	if ix < 0 or ix >= _tuong.size():
		return
	var t := _tuong[ix]
	if t != null and t.loai == OTuong.Loai.GACH:
		_tuong[ix] = null
		t.queue_free()
