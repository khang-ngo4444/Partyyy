class_name KhoDo
extends ColorRect

## Popup Kho đồ (Tab) kiểu Minecraft: kho 4×4 + 5 ô dùng nhanh (phím 1–5 ngoài bàn).
## Đổi chỗ: kéo-thả, hoặc bấm ô A rồi bấm ô B. Rê chuột / chọn một ô rồi bấm 1–5 = đổi với ô nhanh đó.
## Chỉ gửi yêu cầu `doi_cho`; master đổi rồi phát trạng thái mới (vẽ lại theo `cap_nhat`).

signal doi_cho(a: int, b: int)

const TEN_HIEM := ["THƯỜNG", "HIẾM", "HUYỀN THOẠI"]
const MAU_HIEM := [Color("6CC04A"), Color("4FC3F7"), Color("8E5CF7")]

## HUD bật khi đang ở bàn party (không minigame).
var duoc_mo := false

var _tui: Array = []
var _dang_cam := -1
var _o: Array[OKhoDo] = []
var _chuot_cu := Input.MOUSE_MODE_VISIBLE
var _danh_muc: DanhMucVatPham = preload("res://board/danh_muc_vat_pham.tres")

@onready var _the: Control = %TheKho
@onready var _luoi_kho: GridContainer = %LuoiKho
@onready var _luoi_nhanh: HBoxContainer = %LuoiNhanh
@onready var _anh: TextureRect = %AnhMon
@onready var _ten: Label = %TenMon
@onready var _hiem: Label = %HiemMon
@onready var _hiem_pill: PanelContainer = %HiemPill
@onready var _cach_dung: Label = %CachDung
@onready var _dong_btn: Button = %DongBtn


func _ready() -> void:
	visible = false
	# PauseMenu nhận Esc trước: hỏi nhóm này để Esc chỉ đóng kho.
	add_to_group("esc_huy")
	for i in VatPham.TUI_TOI_DA:
		var o := OKhoDo.new()
		o.la_o_nhanh = i < VatPham.SO_O_NHANH
		o.pressed.connect(_bam.bind(i))
		o.tha.connect(_doi)
		o.focus_entered.connect(_xem.bind(i))
		o.mouse_entered.connect(_xem.bind(i))
		if o.la_o_nhanh:
			_luoi_nhanh.add_child(o)
			UIKit.gan_phim(o, str(i + 1))
		else:
			_luoi_kho.add_child(o)
		_o.append(o)
	_dong_btn.pressed.connect(dong)
	UIKit.gan_phim(_dong_btn, "Tab")
	# Từ hàng kho cuối xuống thẳng hàng ô nhanh và ngược lại.
	for c in 4:
		var duoi := _o[VatPham.SO_O_NHANH + 12 + c]
		var nhanh := _o[c]
		duoi.focus_neighbor_bottom = duoi.get_path_to(nhanh)
		nhanh.focus_neighbor_top = nhanh.get_path_to(duoi)
	_ve()


## Gói trạng thái bàn mới.
func cap_nhat(tt: Dictionary) -> void:
	_tui = ((tt.get("do", {}) as Dictionary).get(
			LuatBan.khoa(NetManager.local_id()), []) as Array).duplicate()
	if visible:
		_ve()


func mo() -> void:
	if visible or not duoc_mo:
		return
	visible = true
	_dang_cam = -1
	_chuot_cu = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ve()
	UINav.xuat_hien([_the], 0.0, 0.8)
	_o[0].grab_focus()
	_xem(0)


func huy_bang_esc() -> bool:
	if not visible:
		return false
	dong()
	return true


func dong() -> void:
	if not visible:
		return
	visible = false
	_dang_cam = -1
	Input.mouse_mode = _chuot_cu


func _input(event: InputEvent) -> void:
	var phim := event as InputEventKey
	if not visible:
		if phim != null and phim.pressed and not phim.echo and phim.keycode == KEY_TAB \
				and duoc_mo and not (get_viewport().gui_get_focus_owner() is LineEdit) \
				and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			get_viewport().set_input_as_handled()
			mo()
		return
	# Đang mở: nuốt mọi phím để không lọt xuống bàn (Space tung xúc xắc...).
	if event.is_action_pressed("ui_cancel") or (phim != null and phim.pressed
			and not phim.echo and phim.keycode == KEY_TAB):
		get_viewport().set_input_as_handled()
		if _dang_cam >= 0:
			_dang_cam = -1
			_ve()
		else:
			dong()
		return
	if phim != null and phim.pressed and not phim.echo:
		var so: int = phim.keycode - KEY_1
		if so >= 0 and so < VatPham.SO_O_NHANH:
			get_viewport().set_input_as_handled()
			var o := _o_dang_tro()
			if o >= 0 and o != so:
				_doi(o, so)
			return
		# Phím điều hướng / Enter để GUI xử lý; còn lại chặn.
		if not (event.is_action("ui_up") or event.is_action("ui_down")
				or event.is_action("ui_left") or event.is_action("ui_right")
				or event.is_action("ui_accept")):
			get_viewport().set_input_as_handled()


## Ô đang được trỏ: đang cầm, rồi tới ô có focus.
func _o_dang_tro() -> int:
	if _dang_cam >= 0:
		return _dang_cam
	var f := get_viewport().gui_get_focus_owner()
	return (f as OKhoDo).chi_so if f is OKhoDo and _o.has(f) else -1


func _bam(i: int) -> void:
	if _dang_cam < 0:
		if _mon(i) != "":
			_dang_cam = i
			UINav.nay(_o[i], 1.15)
	elif _dang_cam == i:
		_dang_cam = -1
	else:
		_doi(_dang_cam, i)
		return
	_ve()


## Đổi tạm tại máy mình cho mượt, rồi xin master chốt.
func _doi(a: int, b: int) -> void:
	_dang_cam = -1
	if a == b or (_mon(a) == "" and _mon(b) == ""):
		_ve()
		return
	while _tui.size() <= maxi(a, b):
		_tui.append("")
	var tam = _tui[a]
	_tui[a] = _tui[b]
	_tui[b] = tam
	_ve()
	UINav.nay(_o[b], 1.2)
	_o[b].grab_focus()
	doi_cho.emit(a, b)


func _mon(i: int) -> String:
	return str(_tui[i]) if i >= 0 and i < _tui.size() else ""


func _ve() -> void:
	if not is_node_ready():
		return
	for i in _o.size():
		_o[i].dat(i, _mon(i), i == _dang_cam)
	var f := _o_dang_tro()
	_xem(f if f >= 0 else 0)


## Bảng thông tin món đang trỏ.
func _xem(i: int) -> void:
	var mon := _mon(i)
	if mon == "":
		_anh.texture = null
		_ten.text = "Ô trống"
		_hiem_pill.visible = false
		_cach_dung.text = ("Ô dùng nhanh %d — bấm %d ngoài bàn để dùng món đặt ở đây." % [i + 1, i + 1]
				if i < VatPham.SO_O_NHANH else "Ô kho — món ở kho không dùng trực tiếp được.")
		return
	var hinh := _danh_muc.tim(mon)
	_anh.texture = hinh.icon if hinh != null else null
	_ten.text = VatPham.ten(mon)
	var h := clampi(VatPham.hiem(mon), 0, 2)
	_hiem.text = TEN_HIEM[h]
	_hiem_pill.add_theme_stylebox_override("panel", UIKit.hop(MAU_HIEM[h], 999, 3, 3, 4))
	_hiem_pill.visible = true
	var vi_tri := ("Đang ở ô nhanh %d — bấm %d để dùng." % [i + 1, i + 1]
			if i < VatPham.SO_O_NHANH else "Đang trong kho — đưa xuống ô nhanh (phím 1–5) để dùng.")
	_cach_dung.text = "%s\n%s" % [_cach_nham(mon), vi_tri]


static func _cach_nham(mon: String) -> String:
	var tam := VatPham.tam(mon)
	var tam_chu := (" · tầm %d ô" % tam) if tam > 0 else ""
	match VatPham.nham(mon):
		VatPham.Nham.TAI_CHO:
			return "Dùng tại chỗ" + tam_chu
		VatPham.Nham.TIA:
			return "Ngắm rồi bắn thẳng" + tam_chu
		VatPham.Nham.NON:
			return "Ngắm hình nón" + tam_chu
		VatPham.Nham.CHON_NGUOI:
			return "Chọn một người chơi (Z/X)"
		VatPham.Nham.CHON_O:
			return "Chọn ô trên bàn" + tam_chu
		VatPham.Nham.CHON_MINIGAME:
			return "Chọn minigame kế tiếp"
		VatPham.Nham.TU_DONG:
			return "Tự động đỡ đòn, không cần bấm"
	return ""
