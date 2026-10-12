class_name HowToGuide
extends ColorRect

## Màn hướng dẫn dùng chung (menu chính + Esc trong game).
## Mở: get_tree().get_first_node_in_group("bang_huong_dan").open()
## Phím: ↑/↓ chọn mục, ←/→ hoặc A/D lật trang, Esc/Enter đóng.

signal close_requested

## Các trang (`ui/huong_dan/*.tres`).
@export var trang: Array[TrangHuongDan] = []

## Icon theo số thứ tự trang (1-based): luật, ô, vật phẩm, minigame.
const ICON_NHOM := {1: "trophy", 2: "mouse", 3: "menuGrid", 4: "home", 5: "plus",
		6: "star", 7: "shoppingBasket", 8: "unlocked", 9: "gamepad"}

var _current := 0

@onready var _panel: Control = %HowToPanel
@onready var _page_list: ItemList = %HowToPageList
@onready var _page_title: Label = %HowToPageTitle
@onready var _page_body: RichTextLabel = %HowToPageBody
@onready var _counter: Label = %HowToPageCounter
@onready var _previous: Button = %HowToPrevBtn
@onready var _next: Button = %HowToNextBtn
@onready var _close: Button = %HowToCloseBtn


func _ready() -> void:
	add_to_group("bang_huong_dan")
	visible = false
	for i in trang.size():
		var t := trang[i]
		_page_list.add_item(t.tieu_de, UIKit.icon(ICON_NHOM.get(i + 1, "target")))
		_page_list.set_item_icon_modulate(i, UIKit.MUC)
	_page_list.item_selected.connect(_set_page)
	_previous.pressed.connect(func(): _set_page(_current - 1))
	_next.pressed.connect(func(): _set_page(_current + 1))
	_close.pressed.connect(close)
	UIKit.gan_phim(_previous, "A")
	UIKit.gan_phim(_next, "D")
	UIKit.gan_phim(_close, "Esc")
	_set_page(0)


func open() -> void:
	visible = true
	_set_page(0)
	UINav.xuat_hien([_panel], 0.0, 0.8)
	_page_list.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	close_requested.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey and event.pressed):
		return
	var k: int = event.keycode
	if k == KEY_A or (k == KEY_LEFT and not _close.has_focus()):
		_set_page(_current - 1)
		get_viewport().set_input_as_handled()
	elif k == KEY_D or (k == KEY_RIGHT and not _close.has_focus()):
		_set_page(_current + 1)
		get_viewport().set_input_as_handled()


func _set_page(index: int) -> void:
	var cu := _current
	_current = clampi(index, 0, trang.size() - 1)
	var t := trang[_current]
	_page_list.select(_current)
	_page_list.ensure_current_is_visible()
	_page_title.text = t.tieu_de
	_page_body.text = t.noi_dung
	_page_body.scroll_to_line(0)
	_counter.text = "%d / %d" % [_current + 1, trang.size()]
	_previous.disabled = _current == 0
	_next.disabled = _current == trang.size() - 1
	if cu != _current and visible:
		UINav.nay(_page_title, 1.08)
