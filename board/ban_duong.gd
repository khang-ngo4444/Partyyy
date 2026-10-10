class_name BanDuong
extends Node3D

## Bàn party dạng đồ thị: vòng chính + đường tắt. Các ô (`o_ban.tscn`) đặt sẵn trong scene;
## script chỉ trả lời ô nào nối ô nào và hiển thị trạng thái lên ô.

enum Loai { DAT, MAU, TIEN, TRANG_BI, RUONG, HOI_SINH }


## Chữ trên mặt ô (font mặc định không có emoji).
const KY_HIEU := ["DAT", "+MAU", "+VANG", "TRANG BI", "RUONG", "HOI SINH"]

## Các ô [0, so_o_vong_chinh) nối thành vòng kín; cạnh phụ khai trong `canh_them`.
@export_range(3, 256) var so_o_vong_chinh := 40
@export var canh_them: Array[Vector2i] = []

var _o: Array[OBan] = []
var _ke: Array[PackedInt32Array] = []

## Đồ thị có chiều: `_toi` = đi chiều +1, `_lui` = chiều −1.
var _toi: Array[PackedInt32Array] = []
var _lui: Array[PackedInt32Array] = []

@onready var camera_ban: CameraBan = $CameraBan
@onready var _ruong: VatTrenO = $RuongBau
@onready var _mui_ten: Array[MuiTen] = [$MuiTen1, $MuiTen2, $MuiTen3]
@onready var _quai: VatTrenO = $ChoNgao
@onready var _dau_hieu: DauHieuBan = $DauHieuBan
@onready var _muc_tieu: Node3D = get_node_or_null("VongMucTieu") as Node3D


func _ready() -> void:
	add_to_group("ban_duong")
	_bao_dam_do_thi()


func _bao_dam_do_thi() -> void:
	if not _o.is_empty() and _ke.size() == _o.size():
		return
	_o.assign(find_children("*", "OBan", false, false))
	# Sắp theo `so` (Inspector), không theo thứ tự node trong cây.
	_o.sort_custom(func(a: OBan, b: OBan) -> bool: return a.so < b.so)
	if _o.is_empty():
		push_error("BanDuong: '%s' khong co o nao. Ban do phai chua instance cua o_ban.tscn."
				% name)
		return
	_ke.clear()
	_ke.resize(_o.size())
	_toi.clear()
	_toi.resize(_o.size())
	_lui.clear()
	_lui.resize(_o.size())
	for i in _o.size():
		_ke[i] = PackedInt32Array()
		_toi[i] = PackedInt32Array()
		_lui[i] = PackedInt32Array()
	var vong := mini(so_o_vong_chinh, _o.size())
	for i in vong:
		_them_canh(i, (i + 1) % vong)
	for e in canh_them:
		_them_canh(e.x, e.y)
	for i in _ke.size():
		_ke[i].sort()


func _them_canh(a: int, b: int) -> void:
	if a < 0 or b < 0 or a >= _o.size() or b >= _o.size() or a == b:
		push_warning("BanDuong: canh khong hop le %d-%d" % [a, b])
		return
	if not _ke[a].has(b):
		_ke[a].append(b)
	if not _ke[b].has(a):
		_ke[b].append(a)
	if not _toi[a].has(b):
		_toi[a].append(b)
	if not _lui[b].has(a):
		_lui[b].append(a)


func so_luong() -> int:
	_bao_dam_do_thi()
	return _o.size()


func hien_o(i: int, l: int, chu_dat: String, thue_dat: String, co_ruong: bool,
		diem_hoi_sinh: PackedStringArray, ghi_chu: PackedStringArray) -> void:
	_bao_dam_do_thi()
	if not _o.is_empty():
		_o[_chi_so(i)].hien_trang_thai(l, chu_dat, thue_dat, co_ruong, diem_hoi_sinh, ghi_chu)


## `can`: {"rao:ô" | "bay:ô" | "neo:người": ô} → node rào/bẫy/neo trong `DauHieuBan`.
func hien_dau_hieu(can: Dictionary) -> void:
	var vt := {}
	for khoa in can:
		vt[khoa] = vi_tri(int(can[khoa]))
	_dau_hieu.hien(vt)


## -1 = cất rương.
func dat_ruong(i: int) -> void:
	_dat_vat(_ruong, i)


## -1 = không có chó.
func dat_quai(i: int) -> void:
	_dat_vat(_quai, i)


func _dat_vat(vat: VatTrenO, i: int) -> void:
	if i < 0 or _o.is_empty():
		vat.an()
	else:
		vat.dat_len(vi_tri(i))


## Vòng đánh dấu mục tiêu đang ngắm (scene `vong_muc_tieu.tscn`): đặt dưới chân `vi_tri`,
## `ty_le` nhân bán kính vòng.
func dat_muc_tieu(vi_tri_chan: Vector3, ty_le := 1.0) -> void:
	if _muc_tieu == null:
		return
	_muc_tieu.global_position = vi_tri_chan
	_muc_tieu.scale = Vector3.ONE * ty_le
	_muc_tieu.visible = true


func an_muc_tieu() -> void:
	if _muc_tieu != null:
		_muc_tieu.visible = false


## Node của ô `i` (camera bàn bám theo khi ngắm ô).
func nut_o(i: int) -> Node3D:
	_bao_dam_do_thi()
	return _o[_chi_so(i)] if not _o.is_empty() else null


## Toạ độ mặt ô — chỗ đặt chân.
func vi_tri(i: int) -> Vector3:
	_bao_dam_do_thi()
	return _o[_chi_so(i)].global_position if not _o.is_empty() else global_position


## Các ô kề, đã sắp theo số.
func ke(i: int) -> PackedInt32Array:
	_bao_dam_do_thi()
	return _ke[_chi_so(i)].duplicate()


## Các ô đi tiếp được theo `chieu` (+1/−1); `chieu` = 0 (đầu ván) trả cả hai phía.
func huong_di(o: int, chieu: int) -> PackedInt32Array:
	_bao_dam_do_thi()
	var i := _chi_so(o)
	if chieu > 0:
		return _toi[i]
	if chieu < 0:
		return _lui[i]
	var ca := _toi[i].duplicate()
	for j in _lui[i]:
		if not ca.has(j):
			ca.append(j)
	return ca


func chieu_toi(o: int, toi: int) -> int:
	_bao_dam_do_thi()
	return 1 if _toi[_chi_so(o)].has(toi) else -1


## Đi thẳng `n` bước theo `chieu`, ngã rẽ lấy hướng đầu (Trâu điên, Chó ngao).
func duong_thang(o: int, chieu: int, n: int) -> PackedInt32Array:
	var ra := PackedInt32Array([_chi_so(o)])
	for _i in n:
		var huong := huong_di(int(ra[ra.size() - 1]), chieu if chieu != 0 else 1)
		if huong.is_empty():
			break
		ra.append(int(huong[0]))
	return ra


## Một mũi tên cho mỗi hướng; hướng `chon` sáng lên. `cac_huong` rỗng = cất hết.
func hien_mui_ten(o: int, cac_huong: PackedInt32Array, chon: int) -> void:
	_bao_dam_do_thi()
	for oo in _o:
		oo.dat_noi_bat(0)
	for i in _mui_ten.size():
		if i >= cac_huong.size():
			_mui_ten[i].an()
			continue
		_mui_ten[i].dat(vi_tri(o), vi_tri(int(cac_huong[i])), i == chon)
		_o[_chi_so(int(cac_huong[i]))].dat_noi_bat(2 if i == chon else 1)


## {ô: sát thương} theo khoảng cách: bậc 0 là tâm, bậc 1 là ô kề...
func o_trung_bom(tam: int, bac: Array) -> Dictionary:
	_bao_dam_do_thi()
	var ra := {}
	var hang: Array[Vector2i] = [Vector2i(_chi_so(tam), 0)]
	var da_thay := {_chi_so(tam): true}
	while not hang.is_empty():
		var muc: Vector2i = hang.pop_front()
		if muc.y >= bac.size():
			continue
		ra[muc.x] = int(bac[muc.y])
		for tiep in _ke[muc.x]:
			if not da_thay.has(int(tiep)):
				da_thay[int(tiep)] = true
				hang.append(Vector2i(int(tiep), muc.y + 1))
	return ra


func _chi_so(i: int) -> int:
	return posmod(i, _o.size()) if not _o.is_empty() else 0
