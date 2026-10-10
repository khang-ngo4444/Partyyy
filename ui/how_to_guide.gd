class_name HowToGuide
extends ColorRect

## Màn hướng dẫn trong menu chính.

signal close_requested

## Các trang (`ui/huong_dan/*.tres`).
@export var trang: Array[TrangHuongDan] = []

var _current := 0

@onready var _page_list: ItemList = %HowToPageList
@onready var _page_title: Label = %HowToPageTitle
@onready var _page_body: RichTextLabel = %HowToPageBody
@onready var _counter: Label = %HowToPageCounter
@onready var _previous: Button = %HowToPrevBtn
@onready var _next: Button = %HowToNextBtn
@onready var _close: Button = %HowToCloseBtn


func _ready() -> void:
	for t in trang:
		_page_list.add_item(t.tieu_de)
	_page_list.item_selected.connect(_set_page)
	_previous.pressed.connect(func(): _set_page(_current - 1))
	_next.pressed.connect(func(): _set_page(_current + 1))
	_close.pressed.connect(func(): close_requested.emit())
	_set_page(0)


func open() -> void:
	visible = true
	_set_page(0)
	_page_list.grab_focus()


func close() -> void:
	visible = false


func _set_page(index: int) -> void:
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
