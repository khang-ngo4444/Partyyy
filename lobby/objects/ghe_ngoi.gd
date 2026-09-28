class_name GheNgoi
extends CardSeat

## Chỗ ngồi tự do: sofa phòng khách, không dính gì tới bài bạc.
##
## KẾ THỪA `CardSeat` để KHÔNG phải đụng vào `Player`. `Player._ghe` đã có kiểu `CardSeat`, và
## `_theo_ghe()` quét nhóm `"card_seat"` rồi nhìn `toi_dang_ngoi` — thừa lại là được nguyên bộ
## máy ngồi đã chạy tốt: khoá vận tốc, hạ camera, animation "sit", Q để đứng dậy.
##
## Khác `CardSeat` đúng ba điểm, và đó là toàn bộ phần viết thêm:
##
##   1. KHÔNG hỏi `CardDealer`. Ngồi xuống ghế sofa là chuyện riêng của máy này, không cần
##      master xếp chỗ — không có ván bài nào để mà tranh lượt.
##
##   2. Chỗ còn trống hay không thì SUY RA TỪ VỊ TRÍ người chơi, không replicate thêm gì.
##      Transform của mọi người chơi đã được replicate sẵn: ai đang ngồi đây thì họ đứng ngay
##      đây. Không tốn thêm một byte mạng nào, và không cần master phân xử.
##
##   3. Hướng ngồi lấy từ CHÍNH CÁI GHẾ (+Z), không phải hướng về phía bàn. `CardSeat` quay
##      mặt người vào tâm bàn bài; sofa mà làm thế là ngồi úp mặt vào lưng tựa.

## Trong bán kính này coi như đã có người. Đo từ chỗ ngồi tới chân người chơi.
##
## 0.45 m: vừa hơn nửa bề ngang một người (khối va chạm bán kính 0.4), đủ để hai người không
## chồng lên nhau mà vẫn cho ngồi hai đầu một cái sofa cách nhau hơn 1 m.
const BAN_KINH_CHIEM := 0.45

## Chỗ ngồi THẬT, lệch so với vị trí node, trong hệ toạ độ của ghế.
##
## Node phải đặt TRƯỚC sofa chứ không phải trên nệm: thân sofa là một khối va chạm đặc
## 2.16 × 1 × 0.9 m, vùng ngắm nhét vào trong đó thì tia ngắm đâm trúng sofa trước và không
## bao giờ tới được cái ghế. Nên node (và vùng ngắm, và đế sáng dưới sàn) nằm ngay trước mép
## sofa, còn người thì ngồi lùi vào trong theo số này.
@export var lech_ngoi := Vector3(0.0, 0.5, -0.55)


func _ready() -> void:
	super()
	_tag.text = "NGOI"
	# -1 = KHONG THUOC BAN BAI NAO. Bat buoc, va mot dong nay chua duoc moi cho cung luc.
	#
	# `CardDealer.ban_dang_ngoi()` quet CA NHOM "card_seat" roi tra ve `deck` cua cai ghe minh
	# dang ngoi. Ghe sofa cung nam trong nhom do (co y — de `Player._theo_ghe` thay), nen de
	# `deck` mac dinh 0 la ngoi sofa bi tinh thanh dang ngoi BAN XI DACH: HUD bao "Dang ngoi
	# tai ban XI DACH", va phim 1/2 di rut bai that o cai ban do.
	#
	# Moi cho doc `deck` deu da co san chot `if deck < 0`, nen sua o day la sua duoc het.
	deck = -1


## Ghi đè hẳn phần đọc trạng thái bàn bài của `CardSeat`: ở đây không có bàn, không có ván.
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


## Không ai đứng/ngồi trong bán kính chiếm chỗ thì còn trống.
##
## Bỏ qua chính mình: đang ngồi đây mà tự tính mình là "có người" thì nhãn nhảy sang
## "CO NGUOI" ngay dưới mông mình.
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


## Ngồi quay mặt theo +Z của ghế, lùi vào nệm theo `lech_ngoi`.
##
## `Basis.looking_at(huong)` nhận HƯỚNG CẦN QUAY MẶT VỀ (giống `CardSeat` đang quay mặt về
## phía bàn), nên truyền thẳng `+Z` chứ không phải `-Z`.
func diem_ngoi() -> Transform3D:
	return Transform3D(Basis.looking_at(global_basis.z, Vector3.UP),
			global_position + global_basis * lech_ngoi)


## Đứng dậy thì bước ra phía trước ghế, không phải chui qua lưng tựa.
func diem_dung_day() -> Vector3:
	return global_position + global_basis.z * RA_XA
