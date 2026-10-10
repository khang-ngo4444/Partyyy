class_name TrangThaiCaNhan
extends PanelContainer

## Bảng góc trên-trái ở bàn party: máu mọi người + thanh trang bị của mình. Chỉ vẽ.

@export var dong_mau_scene: PackedScene = null
@export var o_trang_bi_scene: PackedScene = null

var _tt: Dictionary = {}
var _hien := false
var _chon := -1
var _duoc_dung := false

@onready var _vong: Label = %Vong
@onready var _ds_mau: VBoxContainer = %DsMau
@onready var _trang_bi: HFlowContainer = %TrangBi
@onready var _trong_tui: Label = %TrongTui
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


func _ve() -> void:
	var bang_mau: Dictionary = _tt.get("mau", {}) as Dictionary
	visible = _hien and not bang_mau.is_empty()
	if not visible:
		return
	_vong.text = "VÒNG %d/%d · RƯƠNG BÁU %d VÀNG" % [int(_tt.get("vong", 1)),
			int(_tt.get("so_vong", 1)), int(_tt.get("chest_cost", 100))]
	_ve_mau(bang_mau)
	_ve_trang_bi()


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


func _ve_trang_bi() -> void:
	var tui: Array = (_tt.get("do", {}) as Dictionary).get(
			LuatBan.khoa(NetManager.local_id()), []) as Array
	_du_con(_trang_bi, tui.size(), o_trang_bi_scene)
	for i in tui.size():
		(_trang_bi.get_child(i) as OTrangBi).dat(i + 1, str(tui[i]), i == _chon, _duoc_dung)
	_trong_tui.visible = tui.is_empty()
	_goi_y.text = _goi_y_dung_do(tui)


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
	var goi_y := "Lượt bạn: Space tung xúc xắc"
	if _chon >= 0 and _chon < tui.size():
		var mon := str(tui[_chon])
		var ten := VatPham.ten(mon)
		if VatPham.la_ngam(mon):
			goi_y = "Đang ngắm %s: chuột trái để dùng · bấm %d để cất" % [ten, _chon + 1]
		elif VatPham.la_chon(mon):
			if VatPham.nham(mon) == VatPham.Nham.CHON_MINIGAME:
				goi_y = "%s: chọn trò trong bảng (phím 1–9, Esc huỷ)" % ten
			else:
				goi_y = "%s: A/D đổi mục tiêu · Space/E/chuột trái dùng · Esc huỷ" % ten
		else:
			goi_y = "%s: chuột trái để dùng · bấm %d để cất" % [ten, _chon + 1]
	elif LuatHieuUng.bi_khoa_do(_tt, k):
		goi_y = "Đang dính mắm tôm: khoá đồ · Space tung xúc xắc"
	elif (_tt.get("da_dung", {}) as Dictionary).has(k):
		goi_y = "Đã dùng đồ lượt này · Space tung xúc xắc"
	elif tui.any(func(mon) -> bool: return VatPham.nham(str(mon)) != VatPham.Nham.TU_DONG):
		goi_y = "Lượt bạn: bấm số để dùng đồ, rồi Space tung xúc xắc"
	return goi_y
