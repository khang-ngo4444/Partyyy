class_name GheNgoi
extends CardSeat

## Chỗ ngồi tự do (sofa). Kế thừa `CardSeat` để dùng lại cơ chế ngồi của Player.
## Khác `CardSeat`: không hỏi `CardDealer`, chỗ trống suy ra từ vị trí người chơi,
## quay mặt theo +Z của ghế.

## Trong bán kính này (tới chân người chơi) coi như có người.
const BAN_KINH_CHIEM := 0.45

## Chỗ ngồi thật, lệch so với node (hệ toạ độ ghế).
## Node đặt trước sofa để tia ngắm không trúng thân sofa.
@export var lech_ngoi := Vector3(0.0, 0.5, -0.55)


## Ghi đè phần đọc trạng thái bàn bài của `CardSeat`.
func _process(delta: float) -> void:
	_acc += delta
	if _acc < REFRESH:
		return
	_acc = 0.0
	_set_lit(toi_dang_ngoi)
	if toi_dang_ngoi:
		_tag.text = "Q — DUNG DAY"
		_tag.modulate = Color("d9c98a")
	elif con_trong():
		_tag.text = "NGOI"
		_tag.modulate = Color("d9c98a")
	else:
		_tag.text = "CO NGUOI"
		_tag.modulate = Color("8b8d98")


## Còn trống khi không ai khác trong bán kính chiếm chỗ.
func con_trong() -> bool:
	var cho := diem_ngoi().origin
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_mine:
			continue
		if p.global_position.distance_to(cho) < BAN_KINH_CHIEM:
			return false
	return true


func ngoi_xuong() -> void:
	if con_trong():
		toi_dang_ngoi = true


func dung_day() -> void:
	toi_dang_ngoi = false


## Sofa ngồi/đứng thẳng, không xin ai.
func xin_ngoi() -> void:
	ngoi_xuong()


func xin_dung_day() -> void:
	dung_day()


func loi_nhac() -> String:
	return "Đang ngồi — [Q] đứng dậy  ·  [ESC] menu"


## Ngồi quay mặt theo +Z của ghế, lùi vào nệm theo `lech_ngoi`.
func diem_ngoi() -> Transform3D:
	return Transform3D(Basis.looking_at(global_basis.z, Vector3.UP),
			global_position + global_basis * lech_ngoi)


## Đứng dậy thì bước ra trước ghế.
func diem_dung_day() -> Vector3:
	return global_position + global_basis.z * RA_XA
