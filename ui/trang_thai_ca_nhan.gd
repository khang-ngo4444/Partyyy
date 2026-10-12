class_name TrangThaiCaNhan
extends Control

## HUD bàn party, gọn hai mảnh để chừa chỗ nhìn bàn:
## - Góc trên-trái: vòng/rương + mọi người theo thứ tự lượt (▶ = đang tới lượt) + sự kiện mới nhất.
## - Đáy giữa: túi đồ của mình + gợi ý việc cần làm (kể cả chọn hướng / chọn mục tiêu). Chỉ vẽ.

@export var dong_mau_scene: PackedScene = null
@export var o_trang_bi_scene: PackedScene = null

var _tt: Dictionary = {}
var _hien := false
var _chon := -1
var _duoc_dung := false
## Đang chọn hướng / mục tiêu: nội dung ưu tiên hiện ở thanh đáy.
var _huong := ""
var _su_kien_cu := ""
var _re_cach := RegEx.create_from_string(r"\s{2,}")

@onready var _the_tren: Control = %TheTren
@onready var _vong: Label = %Vong
@onready var _ds_mau: VBoxContainer = %DsMau
@onready var _su_kien: Label = %SuKien
@onready var _thanh_duoi: Control = %ThanhDuoi
@onready var _trang_bi: HBoxContainer = %TrangBi
@onready var _trong_tui: Label = %TrongTui
@onready var _ngan: Control = %Ngan
@onready var _goi_y_the: PanelContainer = %GoiYThe
@onready var _goi_y: Label = %GoiY


func _ready() -> void:
	visible = false


func cap_nhat(tt: Dictionary) -> void:
	_tt = tt
	_ve()


func dat_giao_dien(hien: bool, chon: int, duoc_dung: bool) -> void:
	_hien = hien
	_chon = chon
	_duoc_dung = duoc_dung
	_ve()


## `noi_dung` rỗng = hết chọn hướng/mục tiêu.
func dat_chon_huong(noi_dung: String, tieu_de: String) -> void:
	var gon := _re_cach.sub(noi_dung.strip_edges(), " · ", true)
	if gon != "" and tieu_de != "":
		gon = "%s · %s" % [tieu_de, gon]
	_huong = gon
	_ve()


func _ve() -> void:
	var bang_mau: Dictionary = _tt.get("mau", {}) as Dictionary
	visible = _hien and not bang_mau.is_empty()
	if not visible:
		return
	_vong.text = "VÒNG %d/%d  ·  RƯƠNG %d" % [int(_tt.get("vong", 1)),
			int(_tt.get("so_vong", 1)), int(_tt.get("chest_cost", 100))]
	_ve_mau(bang_mau)
	_ve_su_kien()
	_ve_thanh_duoi()


func _ve_mau(bang_mau: Dictionary) -> void:
	var thu_tu: Array = _tt.get("thu_tu", []) as Array
	var toi_da := maxi(int(_tt.get("max_health", 10)), 1)
	var tien: Dictionary = _tt.get("tien", {}) as Dictionary
	var coc: Dictionary = _tt.get("coc", {}) as Dictionary
	var luot := int(_tt.get("luot", -1))
	_du_con(_ds_mau, thu_tu.size(), dong_mau_scene)
	for i in thu_tu.size():
		var id := int(thu_tu[i])
		var k := LuatBan.khoa(id)
		var p := _nguoi(id)
		var mau := NetManager.color_for(p.color_index) if p != null else Color.GRAY
		(_ds_mau.get_child(i) as DongMau).dat(Player.ten_theo_id(get_tree(), id), mau,
				clampi(int(bang_mau.get(k, 0)), 0, toi_da), toi_da, int(tien.get(k, 0)),
				int(coc.get(k, 0)), id == NetManager.local_id(), i == luot)


func _ve_su_kien() -> void:
	# `het_vong` là cờ nội bộ, không hiện.
	var su := str(_tt.get("su_kien", ""))
	if su == "het_vong":
		su = ""
	_su_kien.text = su
	_su_kien.visible = su != ""
	if su != _su_kien_cu and su != "":
		UINav.nay(_su_kien, 1.06)
	_su_kien_cu = su


func _ve_thanh_duoi() -> void:
	var tui: Array = (_tt.get("do", {}) as Dictionary).get(
			LuatBan.khoa(NetManager.local_id()), []) as Array
	# Luôn đủ 5 ô dùng nhanh (ô trống vẽ mờ) như hotbar.
	_du_con(_trang_bi, VatPham.SO_O_NHANH, o_trang_bi_scene)
	for i in VatPham.SO_O_NHANH:
		var mon := str(tui[i]) if i < tui.size() else ""
		(_trang_bi.get_child(i) as OTrangBi).dat(i + 1, mon, i == _chon, _duoc_dung)
	var trong_kho := 0
	for i in range(VatPham.SO_O_NHANH, tui.size()):
		if str(tui[i]) != "":
			trong_kho += 1
	_trong_tui.text = "Tab\nKho (%d)" % trong_kho

	var dang_chon_huong := _huong != ""
	var goi_y := _huong if dang_chon_huong else _goi_y_dung_do(tui)
	if goi_y != _goi_y.text and goi_y != "":
		UINav.nay(_goi_y_the, 1.06)
	_goi_y.text = goi_y
	_goi_y_the.visible = goi_y != ""
	_goi_y_the.theme_type_variation = &"PillCam" if dang_chon_huong else &"PillVang"
	_ngan.visible = _goi_y_the.visible
	# Không có đồ và không có việc gì: ẩn hẳn thanh đáy cho thoáng.
	_thanh_duoi.visible = true


## Giữ đúng `n` node con dựng từ `scene`.
func _du_con(hop: Container, n: int, scene: PackedScene) -> void:
	while hop.get_child_count() > n:
		var c := hop.get_child(hop.get_child_count() - 1)
		hop.remove_child(c)
		c.queue_free()
	while hop.get_child_count() < n and scene != null:
		hop.add_child(scene.instantiate())


func _nguoi(id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == id:
			return p
	return null


func _goi_y_dung_do(tui: Array) -> String:
	if not _duoc_dung:
		return ""
	var k := LuatBan.khoa(NetManager.local_id())
	var goi_y := "Space tung xúc xắc"
	if _chon >= 0 and _chon < tui.size() and str(tui[_chon]) != "":
		var mon := str(tui[_chon])
		var ten := VatPham.ten(mon)
		if VatPham.la_ngam(mon):
			goi_y = "Ngắm %s · chuột trái dùng · %d cất" % [ten, _chon + 1]
		elif VatPham.la_chon(mon):
			if VatPham.nham(mon) == VatPham.Nham.CHON_MINIGAME:
				goi_y = "%s · chọn trò trong bảng (1–9, Esc huỷ)" % ten
			else:
				goi_y = "%s · Z/X đổi mục tiêu · Space dùng · Esc huỷ" % ten
		else:
			goi_y = "%s · chuột trái dùng · %d cất" % [ten, _chon + 1]
	elif LuatHieuUng.bi_khoa_do(_tt, k):
		goi_y = "Dính mắm tôm: khoá đồ · Space tung xúc xắc"
	elif (_tt.get("da_dung", {}) as Dictionary).has(k):
		goi_y = "Đã dùng đồ · Space tung xúc xắc"
	elif tui.slice(0, VatPham.SO_O_NHANH).any(func(mon) -> bool:
			return str(mon) != "" and VatPham.nham(str(mon)) != VatPham.Nham.TU_DONG):
		goi_y = "Bấm số dùng đồ · Space tung xúc xắc"
	return goi_y
