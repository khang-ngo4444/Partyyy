extends Control

## Máy nhạc: chọn thư mục trên máy mình, thêm bài vào hàng đợi chung của phòng.

const NHO_THU_MUC := "user://thu_muc_nhac.txt"
const CHUA_LE := 28.0
const RONG_TOI_DA := 720.0

@export var nut_dong_scene: PackedScene = null
@export var dong_chu_scene: PackedScene = null

var _thu_muc := ""

@onready var _khung: PanelContainer = %Panel
@onready var _duong: Label = %FolderLabel
@onready var _ds_bai: VBoxContainer = %TrackList
@onready var _ds_doi: VBoxContainer = %QueueList
@onready var _trang_thai: Label = %StatusLabel
@onready var _hop: FileDialog = $HopThuMuc


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


func _mo_hop_thu_muc() -> void:
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
		var l := dong_chu_scene.instantiate() as Label
		l.text = "Không thấy file nhạc nào ở đây."
		l.modulate = Color(1, 1, 1, 0.6)
		_ds_bai.add_child(l)
		return

	var m0 := _may()
	var co_ff: bool = m0 != null and m0.co_ffmpeg()
	for bai in ds:
		var b := nut_dong_scene.instantiate() as Button
		var can: bool = bool(bai.get("can_chuyen", false))
		# Bài cần chuyển mã mà máy thiếu ffmpeg thì ghi chú và khoá nút.
		b.text = String(bai["ten"]) if (not can or co_ff) else ("%s  ·  cần ffmpeg" % bai["ten"])
		b.disabled = can and not co_ff
		if can:
			b.modulate = Color(1, 1, 1, 0.75)
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
		var l := dong_chu_scene.instantiate() as Label
		l.text = "Hàng đợi trống."
		l.modulate = Color(1, 1, 1, 0.5)
		_ds_doi.add_child(l)
		return
	for i in m.hang_doi.size():
		var muc: Dictionary = m.hang_doi[i]
		var l := dong_chu_scene.instantiate() as Label
		var dang := String(muc["key"]) == m.dang_phat
		l.text = "%s %s" % ["▶" if dang else "  %d." % (i + 1), muc["ten"]]
		l.modulate = Color("f5d90a") if dang else Color(1, 1, 1, 0.85)
		_ds_doi.add_child(l)


## Nhớ thư mục rồi vẽ lại danh sách.
func _chon_thu_muc(d: String) -> void:
	_thu_muc = d
	var t := FileAccess.open(NHO_THU_MUC, FileAccess.WRITE)
	if t != null:
		t.store_string(d)
		t.close()
	_ve_bai()
