extends MiniGame3D

## SNOWY SPIN — sàn băng trơn, thanh xoay quét ngang. Bám được bao lâu thì bám.
##
## Khuôn T1 thứ hai. Không có nút đòn: đối thủ duy nhất là cái sàn không cho mình dừng lại.
##
## ## 0 gói tin
##
## Góc thanh xoay là hàm thuần của `gio()`. Va chạm thì mỗi máy chỉ kiểm nhân vật CỦA MÌNH rồi
## **tự áp lực đẩy lên mình** — không trọng tài, không gì để tranh chấp.
##
## ## Vì sao thanh xoay ĐẨY chứ không chặn
##
## Guide ghi `AnimatableBody3D`. Một thân vật lý xoay thì `CharacterBody3D` chỉ bị nó gạt khi
## hai bên vừa khéo chạm nhau đúng khung hình — lúc gạt được, lúc lọt qua, và người bị gạt
## không phải là người quyết định. `Area3D` + `Player.day()` cho kết quả giống hệt mắt nhìn,
## luôn ăn, và giữ đúng luật xuyên suốt dự án: nạn nhân tự áp lực lên chính mình.
##
## ## Vì sao một ván liền mạch chứ không phải 3 vòng × 20 giây
##
## Guide ghi 3 vòng, mỗi vòng loại người và cộng điểm riêng. Kết quả cuối cùng vẫn là "trụ lâu
## hơn thì hạng cao hơn" — đúng thứ `MiniGame3D` đã xếp sẵn. Ba vòng chỉ thêm một hệ thống
## điểm thứ hai để nói lại cùng một câu. Bù lại, tốc độ thanh tăng dần nên nửa sau ván vẫn căng
## y như vòng cuối.

## Sàn trơn cỡ nào: giây để tăng tốc từ đứng yên lên tốc độ chạy, và cũng là giây để dừng.
const TRON := 0.85
## Tốc độ quay lúc đầu và lúc cuối, radian/giây.
const TOC_DAU := 0.6
const TOC_CUOI := 2.1
## Tăng hết tốc sau chừng này giây.
const GIAY_TANG_HET := 45.0
## Bị thanh quét trúng thì văng mạnh cỡ nào — theo hướng thanh đang đi, và hất ra phía mép.
const DAY_THEO_THANH := 13.0
const DAY_RA_MEP := 5.0
const DAY_LEN := 3.0

var _truc: Node3D = null
var _vung: Array[Area3D] = []


func _ready() -> void:
	super()
	ten = "SNOWY SPIN"
	luat = "WASD trượt trên băng · né thanh xoay · đừng văng khỏi sàn"
	giay_van = 60.0


func _dung_san() -> void:
	_truc = san.get_node_or_null("Truc") as Node3D
	_vung.clear()
	if _truc == null:
		push_error("SnowySpin: san thieu node Truc")
		return
	for a: Node3D in _truc.find_children("Thanh*", "Node3D", false, false):
		_vung.append(a.get_node("Vung") as Area3D)
	_doi_truot(TRON)


## Sàn phải hết trơn khi về phòng chờ, không thì người chơi trượt băng giữa sảnh.
func dung_som() -> void:
	_doi_truot(0.0)
	super()


func _luat_moi_nhip() -> void:
	if _truc != null:
		_truc.rotation.y = goc_quay(0.0, gio(), TOC_DAU, TOC_CUOI, GIAY_TANG_HET)


## Ghi đè: giữ nguyên luật rơi khỏi sàn của lớp cha, thêm cú quét của thanh.
##
## Thanh KHÔNG giết — nó chỉ hất. Chết là do văng khỏi sàn băng.
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	if p != null and _truc != null:
		for v in _vung:
			if v == null or not v.overlaps_body(p):
				continue
			# Bán kính = từ trục ra chỗ đứng. Thanh đi theo phương vuông góc với nó.
			var ra := p.global_position - _truc.global_position
			ra.y = 0.0
			ra = ra.normalized()
			var theo := Vector3.UP.cross(ra)
			p.day(theo * DAY_THEO_THANH + ra * DAY_RA_MEP + Vector3.UP * DAY_LEN)
			break
	return super()


func _doi_truot(muc: float) -> void:
	var p := _nguoi(NetManager.local_id())
	if p != null:
		p.truot = muc
