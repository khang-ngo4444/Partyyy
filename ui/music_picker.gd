extends Control

## Máy nhạc — mở từ tháp đồng hồ giữa phòng chờ.
##
## Trỏ vào một thư mục trên máy MÌNH, thấy danh sách bài quét được, bấm là thêm vào hàng đợi
## CHUNG. Hàng đợi và bài đang phát là của cả phòng; thư mục thì mỗi người một cái riêng.
##
## Nhớ lại thư mục đã chọn giữa các phiên bằng `user://` — không ai muốn đi trỏ lại cái thư
## mục nhạc của mình mỗi lần mở game.

const NHO_THU_MUC := "user://thu_muc_nhac.txt"
const CHUA_LE := 28.0
const RONG_TOI_DA := 720.0

@onready var _khung: PanelContainer = %Panel
@onready var _duong: Label = %FolderLabel
@onready var _ds_bai: VBoxContainer = %TrackList
@onready var _ds_doi: VBoxContainer = %QueueList
@onready var _trang_thai: Label = %StatusLabel

var _hop: FileDialog = null
var _thu_muc := ""


func _ready() -> void:
	visible = false
	%CloseButton.pressed.connect(dong)
	%PickButton.pressed.connect(_mo_hop_thu_muc)
	%ClearButton.pressed.connect(func():
		var m := _may()
		if m != null:
			m.don_hang_doi())
	%PlayButton.pressed.connect(func():
		var m := _may()
		if m != null:
			m.bat_dau_hoac_tiep())
	%SkipButton.pressed.connect(func():
		var m := _may()
		if m != null:
			m.bo_qua())
	get_viewport().size_changed.connect(func():
		if visible and is_inside_tree():
			_vua_man_hinh())

	var t := FileAccess.open(NHO_THU_MUC, FileAccess.READ)
	if t != null:
		_thu_muc = t.get_as_text().strip_edges()
		t.close()


func _may() -> MusicBox:
	return get_tree().get_first_node_in_group("music_box") as MusicBox


func mo() -> void:
	visible = true
	_vua_man_hinh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var m := _may()
	if m != null and not m.hang_doi_doi.is_connected(_ve_hang_doi):
		m.hang_doi_doi.connect(_ve_hang_doi)
		m.dang_chuyen_ma.connect(func(ten: String):
			_trang_thai.text = "Đang chuyển mã %s… (ffmpeg)" % ten)
		m.bao_loi.connect(func(ly_do: String):
			_trang_thai.text = "⚠ %s" % ly_do)
	_ve_bai()
	_ve_hang_doi()


func dong() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		dong()


func _vua_man_hinh() -> void:
	var man := get_viewport_rect().size
	var rong := minf(RONG_TOI_DA, man.x - CHUA_LE * 2.0)
	var cao := man.y - CHUA_LE * 2.0
	_khung.offset_left = -rong * 0.5
	_khung.offset_right = rong * 0.5
	_khung.offset_top = -cao * 0.5
	_khung.offset_bottom = cao * 0.5


## `FileDialog` ở chế độ chọn THƯ MỤC, dựng bằng code vì nó phải là cửa sổ con của màn hình
## này chứ không nằm trong cây lobby.
func _mo_hop_thu_muc() -> void:
	if _hop == null:
		_hop = FileDialog.new()
		_hop.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		_hop.access = FileDialog.ACCESS_FILESYSTEM
		_hop.use_native_dialog = true
		_hop.title = "Chọn thư mục nhạc"
		_hop.dir_selected.connect(func(d: String):
			_thu_muc = d
			var t := FileAccess.open(NHO_THU_MUC, FileAccess.WRITE)
			if t != null:
				t.store_string(d)
				t.close()
			_ve_bai())
		add_child(_hop)
	if _thu_muc != "":
		_hop.current_dir = _thu_muc
	_hop.popup_centered_ratio(0.7)


func _ve_bai() -> void:
	for c in _ds_bai.get_children():
		c.queue_free()
	_duong.text = _thu_muc if _thu_muc != "" else "— chưa chọn thư mục —"
	if _thu_muc == "":
		return

	var ds := MusicBox.quet_thu_muc(_thu_muc)
	if ds.is_empty():
		# Nói thẳng thay vì để danh sách rỗng không lời nào — người chơi tưởng game hỏng.
		var l := Label.new()
		l.text = "Không thấy file nhạc nào ở đây."
		l.modulate = Color(1, 1, 1, 0.6)
		_ds_bai.add_child(l)
		return

	var m0 := _may()
	var co_ff: bool = m0 != null and m0.co_ffmpeg()
	for bai in ds:
		var b := Button.new()
		var can: bool = bool(bai.get("can_chuyen", false))
		# Nói rõ bài nào phải qua ffmpeg, và vô hiệu hoá nếu máy chưa có ffmpeg — thay vì
		# để người chơi bấm rồi nhận một dòng lỗi.
		# Chỉ kêu "cần ffmpeg" khi máy THIẾU ffmpeg. Bản trước dán câu đó vào MỌI file
		# phải chuyển mã, kể cả khi ffmpeg đang có sẵn — nhìn như cả thư mục bị chặn.
		b.text = String(bai["ten"]) if (not can or co_ff) else ("%s  ·  cần ffmpeg" % bai["ten"])
		b.disabled = can and not co_ff
		if can:
			b.modulate = Color(1, 1, 1, 0.75)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 34
		var duong := String(bai["duong"])
		var ten := String(bai["ten"])
		b.pressed.connect(func():
			var m := _may()
			if m != null:
				_trang_thai.text = "Đã thêm: %s" % ten
				m.them_bai(duong, ten))
		_ds_bai.add_child(b)


func _ve_hang_doi() -> void:
	var mp := _may()
	if mp != null:
		%PlayButton.text = ("PHÁT" if mp.dang_phat == "" or mp.dang_tam_dung()
				else "TẠM DỪNG")
	for c in _ds_doi.get_children():
		c.queue_free()
	var m := _may()
	if m == null:
		return
	if m.hang_doi.is_empty():
		var l := Label.new()
		l.text = "Hàng đợi trống."
		l.modulate = Color(1, 1, 1, 0.5)
		_ds_doi.add_child(l)
		return
	for i in m.hang_doi.size():
		var muc: Dictionary = m.hang_doi[i]
		var l := Label.new()
		var dang := String(muc["key"]) == m.dang_phat
		l.text = "%s %s" % ["▶" if dang else "  %d." % (i + 1), muc["ten"]]
		l.modulate = Color("f5d90a") if dang else Color(1, 1, 1, 0.85)
		_ds_doi.add_child(l)
