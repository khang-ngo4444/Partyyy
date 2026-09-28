class_name XeTang
extends Node2D

## MỘT chiếc xe tăng. Thân, nòng, viền nằm trong `xe_tang.tscn` — script chỉ giữ trạng thái
## và tự lái theo hướng đang có.
##
## Xe tự đi lấy: `TankBattle` chỉ nói "quay hướng này từ chỗ này", còn chuyện trượt vào tường
## hay không là việc của xe. Nhờ vậy phần mạng ở `TankBattle` không dính một dòng va chạm nào.

const TOC_DO := 110.0            ## pixel/giây
const CO := 26.0                 ## cạnh thân xe
## Nghỉ giữa hai phát, giây. Không có thì giữ phím là một dòng đạn liền.
const NGHI_BAN := 0.45

## Hướng nòng đang chĩa. Khác `_di` ở chỗ thả phím thì xe đứng lại nhưng nòng vẫn giữ hướng cũ.
var huong := Vector2i(0, -1)
var song := true

var _di := Vector2i.ZERO
var _ban_luc := -99.0

@onready var _than: ColorRect = $Than
@onready var _vien: ColorRect = $Vien


## Màu lấy từ màu nhân vật của chính người chơi đó, không có bảng màu riêng.
func khoi_tao(mau: Color, cua_toi: bool) -> void:
	_than.color = mau
	# Xe của mình: viền trắng, đủ để nhận ra giữa mười chấm màu.
	_vien.visible = cua_toi


## Đặt lại hướng VÀ vị trí. Toạ độ đi kèm để nắn sai lệch tích luỹ giữa các máy — máy nhận
## đặt xe về đúng chỗ người bấm phím đang thấy rồi chạy tiếp, không để trôi dần.
func lai(h: Vector2i, vi: Vector2) -> void:
	position = vi
	_di = h
	if h != Vector2i.ZERO:
		huong = h
	# Xoay cả node: nòng đặt sẵn chĩa về +x trong scene nên không phải dời nó bằng code.
	# Xoay cả lúc `h` rỗng: thả phím thì xe đứng lại nhưng nòng phải giữ nguyên hướng cũ.
	rotation = Vector2(huong).angle()


func chay(delta: float, ban_do: BanDoTank) -> void:
	if not song or _di == Vector2i.ZERO:
		return
	var moi := position + Vector2(_di) * TOC_DO * delta
	# Kiểm bốn góc thân xe: đi lọt nửa người vào tường thì nhìn rất sai.
	var r := CO * 0.5 - 1.0
	for g: Vector2 in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		if ban_do.loai_tai(moi + g) != BanDoTank.TRONG:
			return
	position = moi


func san_sang_ban(gio: float) -> bool:
	return song and gio - _ban_luc >= NGHI_BAN


func ghi_ban(gio: float) -> void:
	_ban_luc = gio


func chet() -> void:
	song = false
	_di = Vector2i.ZERO
	hide()
