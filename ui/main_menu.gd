extends Control

## Nhập tên, chọn màu, chọn phòng. CHỈ phát signal — không gọi thẳng Fusion,
## không biết Photon tồn tại.

signal host_requested
signal join_requested(room_name: String)

@onready var name_edit: LineEdit = %NameEdit
@onready var host_btn: Button = %HostBtn
@onready var status: Label = %Status
@onready var room_list: VBoxContainer = %RoomList
@onready var empty_hint: Label = %EmptyHint


func _ready() -> void:
	name_edit.text = "Player%d" % (randi() % 1000)
	name_edit.text_changed.connect(func(t): NetManager.player_name = t)
	NetManager.player_name = name_edit.text

	host_btn.pressed.connect(func(): host_requested.emit())
	NetManager.connected.connect(func(): _set_status("Đã kết nối. Tạo phòng mới hoặc chọn phòng bên dưới.", false))
	NetManager.connect_failed.connect(func(r): _set_status("Lỗi kết nối: %s" % r, true))
	NetManager.room_list_changed.connect(_rebuild_room_list)

	_set_status("Đang kết nối Photon...", false)
	_set_buttons_enabled(false)


func _set_status(text: String, is_error: bool) -> void:
	status.text = text
	status.modulate = Color(1, 0.45, 0.45) if is_error else Color(1, 1, 1)
	_set_buttons_enabled(not is_error and not text.begins_with("Đang"))


func _set_buttons_enabled(on: bool) -> void:
	host_btn.disabled = not on


func _rebuild_room_list(rooms: Array) -> void:
	for c in room_list.get_children():
		c.queue_free()
	empty_hint.visible = rooms.is_empty()
	for r in rooms:
		var b := Button.new()
		b.text = "%s        %d/%d" % [r["label"], r["players"], r["max"]]
		b.custom_minimum_size.y = 40
		b.disabled = r["players"] >= r["max"]
		var id: String = r["id"]
		b.pressed.connect(func(): join_requested.emit(id))
		room_list.add_child(b)
