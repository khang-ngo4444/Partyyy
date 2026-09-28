extends VBoxContainer

## Chat chữ. Enter mở ô gõ, Enter gửi, Esc huỷ.
##
## Gửi qua `Fusion.rpc` như mọi sự kiện khác trong game — KHÔNG dùng Photon Chat: Photon Chat
## chỉ có SDK C#/C++, addon Fusion Godot không kèm nó.
##
## Là SỰ KIỆN, không phải trạng thái: người vào phòng sau không thấy tin cũ.
##
## Người chơi gõ được một ít thẻ HTML (`<b>`, `<i>`, `<font color=...>`...) và khung chat dựng
## lại thành chữ có định dạng — xem `_bbcode`. Bong bóng trên đầu thì KHÔNG: Label3D không đọc
## BBCode, nên nó nhận bản chữ trơn đã gỡ hết thẻ (`_tho`).

## Người chơi gõ một dòng bắt đầu bằng `/`. `main.gd` nghe và thi hành — chat KHÔNG tự chạy
## lệnh, nó chỉ là ô nhập chữ. Luật phân quyền nằm ở `LenhChat`.
signal lenh(id_nguoi_gui: int, doi_so: PackedStringArray)

const SO_DONG := 8
const DAI_TOI_DA := 120
## Không có tin mới bấy nhiêu giây thì khung chat mờ đi, trả lại màn hình.
const GIU := 8.0

## Thẻ HTML -> thẻ BBCode. ĐÂY LÀ DANH SÁCH TRẮNG: thứ gì không có ở đây bị gỡ bỏ.
##
## Cố tình KHÔNG có `<img>` và `<a>`. BBCode `[img]` nhận đường dẫn tuỳ ý, nên một người chơi
## gõ `<img src="http://...">` là bắt được MÁY CỦA NGƯỜI KHÁC đi tải về — lộ địa chỉ IP cho
## bên thứ ba, và tải một ảnh khổng lồ là đủ làm đơ máy họ. `[url]` thì biến chat thành chỗ
## rải link bấm được. Chat là chữ người lạ gửi tới; nó chỉ được phép làm chữ đậm chữ nghiêng.
const THE_HTML := {
	"b": "b", "strong": "b",
	"i": "i", "em": "i",
	"u": "u",
	"s": "s", "del": "s", "strike": "s",
	"code": "code",
}

## Thẻ BBCode cần đóng lại cho cân. Thiếu một cái `[/b]` là in đậm tràn sang MỌI dòng chat
## sau đó, kể cả tin của người khác.
const THE_DONG := ["b", "i", "u", "s", "code", "color"]

@onready var log_label: RichTextLabel = %ChatLog
@onready var o_go: LineEdit = %ChatInput

var _tin: PackedStringArray = []
var _tween: Tween
## Gỡ thẻ. Chỉ khớp thứ MỞ ĐẦU bằng chữ cái, nên "1 < 2 > 0" gõ trong chat không bị ăn mất.
var _re_the := RegEx.create_from_string("</?[a-zA-Z][^>]*>")
var _re_mau := RegEx.create_from_string(
		"(?i)<(?:font|span)[^>]*?(?:color\\s*[=:]\\s*[\"']?)(#?[0-9a-z]{3,20})[\"']?[^>]*>")


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
	if t == "":
		return
	# Dòng lệnh KHÔNG đi qua đường chat: nó không phải câu nói, và hiện `/mg tank` lên khung
	# chat của cả phòng chỉ làm rối. Lệnh đi đường riêng của nó.
	if LenhChat.la_lenh(t):
		Fusion.rpc(_net_lenh, NetManager.local_id(), LenhChat.tach(t))
		return
	Fusion.rpc(_net_chat, NetManager.local_id(), t.left(DAI_TOI_DA))


## Lệnh tới MỌI máy — tầng 2 của lớp xác thực. Máy nào được thi hành thì `main.gd` quyết bằng
## `LenhChat.duoc_thi_hanh()`; ở đây chỉ chuyển tiếp, không phán gì.
@rpc("any_peer", "call_local")
func _net_lenh(id_nguoi_gui: int, doi_so: PackedStringArray) -> void:
	if doi_so.is_empty():
		return
	lenh.emit(id_nguoi_gui, doi_so)


## Báo riêng cho máy này, không gửi ai. Dùng cho câu trả lời của lệnh.
func bao(chu: String) -> void:
	_tin.append("[color=#8b98a8]%s[/color]" % _tho(chu))
	if _tin.size() > SO_DONG:
		_tin.remove_at(0)
	log_label.text = "
".join(_tin)
	_hien()


## Gửi SỐ người chơi chứ không gửi tên: tên đã replicate sẵn trên nhân vật rồi.
@rpc("any_peer", "call_local")
func _net_chat(player_id: int, text: String) -> void:
	# Máy nhận tự kẹp lại độ dài — không tin con số do máy gửi tự khai.
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
		# Góc nhìn thứ nhất: bong bóng của chính mình nằm trong đầu camera. Mình đọc ở khung
		# chat là đủ — giống bảng tên, cũng ẩn với chính mình.
		if not p.is_mine:
			var b := _bong_bong(p)
			b.mau = mau
			b.kieu = p.bubble_shape
			b.noi(_tho(text))

	# Tên tô theo màu nhân vật: khung chat và bong bóng cùng một bảng màu, liếc là biết ai nói.
	# Thẻ `[color]` này do CHÍNH TA dựng từ một Color, không phải chữ người chơi gõ.
	_tin.append("[color=#%s]%s[/color]: %s" % [mau.to_html(false), _tho(ten), _bbcode(text)])
	if _tin.size() > SO_DONG:
		_tin.remove_at(0)
	log_label.text = "\n".join(_tin)
	_hien()


## Chữ người chơi gõ -> BBCode an toàn.
##
## THỨ TỰ BA BƯỚC LÀ BẮT BUỘC:
##   1. Vô hiệu hoá mọi `[` người chơi gõ. Sau bước này, dấu `[` duy nhất còn lại trong chuỗi
##      là dấu do HÀM NÀY đặt vào — người chơi không cách nào gõ thẳng BBCode được nữa.
##   2. Đổi các thẻ HTML trong danh sách trắng thành BBCode.
##   3. Gỡ sạch thẻ còn lại, giữ phần chữ bên trong.
##
## Đảo bước 1 xuống sau là hỏng hết: lúc đó `[` của chính ta cũng bị vô hiệu hoá, mà `[` của
## người chơi thì đã lọt qua thành BBCode thật.
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


## Màu chỉ được là hex hoặc một tên màu Godot hiểu. Tên lạ -> trắng.
##
## Không nhận thẳng chuỗi người chơi gõ vào `[color=...]`: chuỗi đó có thể chứa `]` và đóng
## thẻ sớm, phần đuôi tràn ra thành BBCode thật.
func _loc_mau(tho: String) -> String:
	# `from_string` nhan ca "#rrggbb" lan ten mau ("red", "skyblue"), sai thi tra ve mac dinh.
	# Di qua no roi in lai bang `to_html` nghia la chuoi cuoi cung LUON la 6 chu so hex —
	# khong con ky tu nao cua nguoi choi song sot vao trong the.
	return "[color=#%s]" % Color.from_string(tho, Color.WHITE).to_html(false)


## Đóng nốt những thẻ người chơi mở mà quên đóng.
func _dong_the(s: String) -> String:
	for t in THE_DONG:
		var mo := s.count("[%s]" % t) + s.count("[%s=" % t)
		var dong := s.count("[/%s]" % t)
		for i in maxi(mo - dong, 0):
			s += "[/%s]" % t
	return s


## Bản chữ TRƠN cho bong bóng 3D: gỡ hết thẻ, không đổi gì thành BBCode. Label3D không đọc
## BBCode nên để nguyên thẻ vào đó là hiện ra đúng cái chuỗi `<b>xin chao</b>`.
func _tho(text: String) -> String:
	return _re_the.sub(text, "", true).strip_edges()


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
