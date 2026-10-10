extends VBoxContainer

## Chat chữ: Enter mở/gửi, Esc huỷ. Gửi bằng `Fusion.rpc` (sự kiện, người vào sau không thấy
## tin cũ). Cho phép một ít thẻ HTML; bong bóng 3D nhận bản chữ trơn.

## Dòng bắt đầu bằng `/` — `main.gd` thi hành (quyền ở `LenhChat`).
signal lenh(id_nguoi_gui: int, doi_so: PackedStringArray)

const SO_DONG := 8
const DAI_TOI_DA := 120

## Không có tin mới bấy nhiêu giây thì khung chat mờ đi.
const GIU := 8.0

## Danh sách trắng thẻ HTML -> BBCode. Cố tình không có `<img>`, `<a>` (tải ảnh lạ, rải link).
const THE_HTML := {
	"b": "b", "strong": "b",
	"i": "i", "em": "i",
	"u": "u",
	"s": "s", "del": "s", "strike": "s",
	"code": "code",
}

## Thẻ cần đóng cho cân, kẻo định dạng tràn sang dòng sau.
const THE_DONG := ["b", "i", "u", "s", "code", "color"]

var _tin: PackedStringArray = []
var _tween: Tween

## Chỉ khớp thẻ mở đầu bằng chữ cái ("1 < 2 > 0" vẫn giữ nguyên).
var _re_the := RegEx.create_from_string("</?[a-zA-Z][^>]*>")
var _re_mau := RegEx.create_from_string(
		"(?i)<(?:font|span)[^>]*?(?:color\\s*[=:]\\s*[\"']?)(#?[0-9a-z]{3,20})[\"']?[^>]*>")

@onready var log_label: RichTextLabel = %ChatLog
@onready var o_go: LineEdit = %ChatInput


func _ready() -> void:
	Fusion.register_broadcast_receiver(self)
	o_go.text_submitted.connect(_gui)
	NetManager.room_left.connect(func():
		_tin.clear()
		log_label.text = ""
		_tat_o_go())
	modulate.a = 0.0


## Esc bắt ở `_input` (trước ô chữ).
func _input(event: InputEvent) -> void:
	if o_go.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_tat_o_go()


func _unhandled_input(event: InputEvent) -> void:
	if o_go.visible or not is_visible_in_tree():
		return
	# Chuột đang thả = menu Esc đang mở.
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
	if t == "":
		return
	# Lệnh đi đường riêng, không hiện lên chat.
	if LenhChat.la_lenh(t):
		# Fusion không gửi được PackedStringArray — gửi Array.
		Fusion.rpc(_net_lenh, NetManager.local_id(), Array(LenhChat.tach(t)))
		return
	Fusion.rpc(_net_chat, NetManager.local_id(), t.left(DAI_TOI_DA))


## Lệnh tới mọi máy; `main.gd` quyết máy nào thi hành.
@rpc("any_peer", "call_local")
func _net_lenh(id_nguoi_gui: int, doi_so: Array) -> void:
	if doi_so.is_empty():
		return
	lenh.emit(id_nguoi_gui, PackedStringArray(doi_so))


## Báo riêng cho máy này.
func bao(chu: String) -> void:
	_tin.append("[color=#8b98a8]%s[/color]" % _tho(chu))
	if _tin.size() > SO_DONG:
		_tin.remove_at(0)
	log_label.text = "\n".join(_tin)
	_hien()


@rpc("any_peer", "call_local")
func _net_chat(player_id: int, text: String) -> void:
	# Máy nhận tự giới hạn độ dài.
	text = text.strip_edges().left(DAI_TOI_DA)
	if text == "":
		return
	var ten := "#%d" % player_id
	var mau := Color.WHITE
	for n in get_tree().get_nodes_in_group("players"):
		if not n is Player or n.player_id() != player_id:
			continue
		var p := n as Player
		mau = NetManager.color_for(p.color_index)
		if p.player_name != "":
			ten = p.player_name
		# Không hiện bong bóng của chính mình.
		if not p.is_mine:
			var b := _bong_bong(p)
			b.mau = mau
			b.kieu = p.bubble_shape
			b.noi(_tho(text))

	# Tên tô theo màu nhân vật.
	_tin.append("[color=#%s]%s[/color]: %s" % [mau.to_html(false), _tho(ten), _bbcode(text)])
	if _tin.size() > SO_DONG:
		_tin.remove_at(0)
	log_label.text = "\n".join(_tin)
	_hien()


## Chữ người chơi -> BBCode an toàn. Thứ tự bắt buộc: vô hiệu `[` → đổi thẻ trắng → gỡ thẻ lạ.
func _bbcode(text: String) -> String:
	var s := text.replace("[", "[lb]")

	var m := _re_mau.search(s)
	while m != null:
		var mau := _loc_mau(m.get_string(1))
		s = s.substr(0, m.get_start()) + mau + s.substr(m.get_end())
		m = _re_mau.search(s, m.get_start() + mau.length())
	s = s.replace("</font>", "[/color]").replace("</span>", "[/color]")
	s = s.replace("</FONT>", "[/color]").replace("</SPAN>", "[/color]")

	for html in THE_HTML:
		var bb: String = THE_HTML[html]
		s = s.replace("<%s>" % html, "[%s]" % bb).replace("</%s>" % html, "[/%s]" % bb)
		s = s.replace("<%s>" % html.to_upper(), "[%s]" % bb)
		s = s.replace("</%s>" % html.to_upper(), "[/%s]" % bb)
	s = s.replace("<br>", "\n").replace("<br/>", "\n").replace("<br />", "\n")

	return _dong_the(_re_the.sub(s, "", true))


## Chỉ nhận màu hex hoặc tên màu Godot; lạ thì trắng.
func _loc_mau(tho: String) -> String:
	# In lại bằng `to_html` để chuỗi luôn là hex an toàn.
	return "[color=#%s]" % Color.from_string(tho, Color.WHITE).to_html(false)


func _dong_the(s: String) -> String:
	for t in THE_DONG:
		var mo := s.count("[%s]" % t) + s.count("[%s=" % t)
		var dong := s.count("[/%s]" % t)
		for i in maxi(mo - dong, 0):
			s += "[/%s]" % t
	return s


## Chữ trơn cho bong bóng 3D (Label3D không đọc BBCode).
func _tho(text: String) -> String:
	return _re_the.sub(text, "", true).strip_edges()


func _bong_bong(p: Node3D) -> SpeechBubble:
	return p.get_node_or_null("SpeechBubble") as SpeechBubble


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
