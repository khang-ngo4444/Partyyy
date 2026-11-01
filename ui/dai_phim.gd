class_name DaiPhim
extends PanelContainer

## Bảng nhỏ góc màn hình nhắc phím theo tình huống. F1 thu gọn còn đúng một chip.

const CO_CHU := 14
const PHIM_THU_GON := KEY_F1
const DO_DUC := 0.93
const CACH_DAY_THUONG := 14.0
## Minigame có dải ô điểm ở đáy màn hình: đứng trên dải đó.
const CACH_DAY_MINIGAME := 86.0

const PHIM_SANH := [["WASD", "Đi"], ["Space", "Nhảy"], ["E", "Tương tác"], ["M", "Đổi nhân vật"],
	["Enter", "Chat"], ["Esc", "Menu"]]
const PHIM_CAM_DO := [["WASD", "Đi"], ["Giữ E", "Ném"], ["Q", "Đặt xuống"], ["Esc", "Menu"]]
const PHIM_BAN := [["Space", "Tung xúc xắc"], ["1 – 5", "Dùng đồ"], ["Tab", "Túi đồ"], ["C", "Đổi camera"],
	["V", "Theo dõi"], ["Enter", "Chat"], ["Esc", "Menu"]]
const PHIM_CHON_HUONG := [["Z / X", "Đổi lựa chọn"], ["Space", "Chốt"], ["Esc", "Menu"]]
const PHIM_ESC := ["Esc", "Menu"]

var _thu_gon := false
var _dang_hien: Array = []

@onready var _cot: VBoxContainer = %CotPhim


func _ready() -> void:
	modulate.a = DO_DUC
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Rỗng = ẩn bảng. Chỉ dựng lại khi danh sách đổi.
func hien(ds: Array, cach_day := CACH_DAY_THUONG) -> void:
	visible = not ds.is_empty()
	offset_bottom = -cach_day
	offset_top = -cach_day
	if ds == _dang_hien:
		return
	_dang_hien = ds
	_dung_lai()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == PHIM_THU_GON:
		_thu_gon = not _thu_gon
		_dung_lai()
		get_viewport().set_input_as_handled()


func _dung_lai() -> void:
	for c in _cot.get_children():
		_cot.remove_child(c)
		c.queue_free()
	_cot.add_child(UIKit.chip_phim("F1", "Hiện phím" if _thu_gon else "Ẩn", false, CO_CHU))
	if _thu_gon:
		return
	for muc: Array in _dang_hien:
		_cot.add_child(UIKit.chip_phim(muc[0], muc[1], false, CO_CHU))
