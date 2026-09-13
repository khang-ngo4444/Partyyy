extends VBoxContainer

## Chat chữ. Enter mở ô gõ, Enter gửi, Esc huỷ.
##
## Gửi qua `Fusion.rpc` như mọi sự kiện khác trong game — KHÔNG dùng Photon Chat: Photon Chat
## chỉ có SDK C#/C++, addon Fusion Godot không kèm nó.
##
## Là SỰ KIỆN, không phải trạng thái: người vào phòng sau không thấy tin cũ.

const SO_DONG := 8
const DAI_TOI_DA := 120
## Không có tin mới bấy nhiêu giây thì khung chat mờ đi, trả lại màn hình.
const GIU := 8.0

@onready var log_label: Label = %ChatLog
@onready var o_go: LineEdit = %ChatInput

var _tin: PackedStringArray = []
var _tween: Tween


func _ready() -> void:
	Fusion.register_broadcast_receiver(self)
	o_go.text_submitted.connect(_gui)
	NetManager.room_left.connect(func():
		_tin.clear()
		log_label.text = ""
		_tat_o_go())
	modulate.a = 0.0


## Esc bắt ở `_input` (trước cả ô chữ). PauseMenu tự nhường khi ô chữ đang giữ focus.
func _input(event: InputEvent) -> void:
	if o_go.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_tat_o_go()


func _unhandled_input(event: InputEvent) -> void:
	if o_go.visible or not is_visible_in_tree():
		return
	# Chuột đang thả = menu Esc đang mở. Enter lúc đó không phải để chat.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode != KEY_ENTER and k.keycode != KEY_KP_ENTER:
		return
	get_viewport().set_input_as_handled()
	o_go.text = ""
	o_go.visible = true
	o_go.grab_focus()
	_hien()


func _gui(text: String) -> void:
	var t := text.strip_edges()
	_tat_o_go()
	if t != "":
		Fusion.rpc(_net_chat, NetManager.local_id(), t.left(DAI_TOI_DA))


## Gửi SỐ người chơi chứ không gửi tên: tên đã replicate sẵn trên nhân vật rồi.
@rpc("any_peer", "call_local")
func _net_chat(player_id: int, text: String) -> void:
	# Máy nhận tự kẹp lại độ dài — không tin con số do máy gửi tự khai.
	text = text.strip_edges().left(DAI_TOI_DA)
	if text == "":
		return
	var ten := "#%d" % player_id
	for n in get_tree().get_nodes_in_group("players"):
		if not n is Player or n.player_id() != player_id:
			continue
		if n.player_name != "":
			ten = n.player_name
		# Góc nhìn thứ nhất: bong bóng của chính mình nằm trong đầu camera. Mình đọc ở khung
		# chat là đủ — giống bảng tên, cũng ẩn với chính mình.
		if not n.is_mine:
			_bong_bong(n).noi(text)
	_tin.append("%s: %s" % [ten, text])
	if _tin.size() > SO_DONG:
		_tin.remove_at(0)
	log_label.text = "\n".join(_tin)
	_hien()


func _bong_bong(p: Node3D) -> SpeechBubble:
	var b := p.get_node_or_null("SpeechBubble") as SpeechBubble
	if b == null:
		b = SpeechBubble.new()
		b.name = "SpeechBubble"
		p.add_child(b)
	return b


func _tat_o_go() -> void:
	o_go.release_focus()
	o_go.visible = false
	_hien()


func _hien() -> void:
	if _tween != null:
		_tween.kill()
	modulate.a = 1.0 if (o_go.visible or not _tin.is_empty()) else 0.0
	if o_go.visible or _tin.is_empty():
		return
	_tween = create_tween()
	_tween.tween_interval(GIU)
	_tween.tween_property(self, "modulate:a", 0.0, 0.6)
