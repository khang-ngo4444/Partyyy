class_name BanDuong
extends Node3D

## Bàn party dạng ĐỒ THỊ: vòng chính và các đường tắt có ngã rẽ.
##
## ## Script này KHÔNG dựng ô nào
##
## Các ô là instance của `o_ban.tscn` đặt sẵn trong `ban_party.tscn`; `canh_them` mô tả các
## đường rẽ ngoài vòng chính. Ở đây trả lời ô nào nối ô nào, các lộ trình đủ N bước và vị trí.
##
## Khác hẳn `ChessBoard`. `ChessBoard` là một LƯỚI PHẲNG: nó biết toạ độ ô (col, row) nhưng
## không biết ô nào nối ô nào. Thiết kế chìa khoá/cốc cần đúng cái nó không có — "tung xúc xắc
## đi 5 bước", "bom lan sang ô bên cạnh" đều hỏi *ô kế tiếp là ô nào*.

enum Loai { DAT, MAU, TIEN, TRANG_BI, RUONG, HOI_SINH }

const TEN_LOAI := ["Đất", "Máu", "Tiền", "Trang bị", "Rương", "Hồi sinh"]
## Ký hiệu ngắn trên mặt ô. Chữ THƯỜNG chứ không emoji: font mặc định của Godot không có
## emoji, nó hiện ra ô vuông rỗng hoặc mất hẳn.
const KY_HIEU := ["DAT", "+MAU", "+VANG", "TRANG BI", "RUONG", "HOI SINH"]

## Các ô [0, so_o_vong_chinh) tự nối thành vòng kín. Các cạnh còn lại khai báo trong scene.
@export_range(3, 256) var so_o_vong_chinh := 40
@export var canh_them: Array[Vector2i] = []

var _o: Array[OBan] = []
var _ke: Array[PackedInt32Array] = []


func _ready() -> void:
	add_to_group("ban_duong")
	_bao_dam_do_thi()


func _bao_dam_do_thi() -> void:
	if not _o.is_empty() and _ke.size() == _o.size():
		return
	_o.assign(find_children("*", "OBan", false, false))
	# Sắp theo `so` trong Inspector chứ không theo thứ tự trong cây: kéo node lung tung hay
	# đổi tên node cũng không làm lệch vòng đi.
	_o.sort_custom(func(a: OBan, b: OBan) -> bool: return a.so < b.so)
	if _o.is_empty():
		push_error("BanDuong: '%s' khong co o nao. Ban do phai chua instance cua o_ban.tscn."
				% name)
		return
	_ke.clear()
	_ke.resize(_o.size())
	for i in _o.size():
		_ke[i] = PackedInt32Array()
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


func so_luong() -> int:
	_bao_dam_do_thi()
	return _o.size()


func loai(i: int) -> int:
	_bao_dam_do_thi()
	return _o[_chi_so(i)].loai if not _o.is_empty() else Loai.DAT


## Đổi loại nền của một ô lúc đang chơi.
##
## `OBan.loai` có setter tự đổi vật liệu và nhãn, nên ở đây chỉ gán một giá trị — không dựng
## lại node nào. Bản đồ trong `.tscn` không bị sửa: đóng bàn là mọi thứ về như cũ.
func dat_loai(i: int, l: int) -> void:
	_bao_dam_do_thi()
	if not _o.is_empty():
		_o[_chi_so(i)].loai = l as BanDuong.Loai


## Cập nhật cả loại ô lẫn lớp thông tin động (chủ đất, rương, checkpoint).
func hien_o(i: int, l: int, chu_dat: String, co_ruong: bool,
		diem_hoi_sinh: PackedStringArray) -> void:
	_bao_dam_do_thi()
	if not _o.is_empty():
		_o[_chi_so(i)].hien_trang_thai(l, chu_dat, co_ruong, diem_hoi_sinh)


## Toạ độ thế giới của mặt ô — chỗ đặt chân người chơi.
func vi_tri(i: int) -> Vector3:
	_bao_dam_do_thi()
	return _o[_chi_so(i)].global_position if not _o.is_empty() else global_position


## Tương thích với code cũ: lấy hàng xóm có số nhỏ nhất. Gameplay mới dùng `cac_duong()`.
func tien(i: int, buoc: int) -> int:
	_bao_dam_do_thi()
	var o := _chi_so(i)
	for _b in buoc:
		if _ke[o].is_empty():
			break
		o = int(_ke[o][0])
	return o


## Mọi ô nối trực tiếp với `i`, luôn được sắp theo số để mọi máy sinh cùng thứ tự lựa chọn.
func ke(i: int) -> PackedInt32Array:
	_bao_dam_do_thi()
	return _ke[_chi_so(i)].duplicate()


## Danh sách cạnh duy nhất, dùng cả để dựng cầu 3D lẫn kiểm thử graph.
func cac_canh() -> Array[Vector2i]:
	_bao_dam_do_thi()
	var ra: Array[Vector2i] = []
	for a in _ke.size():
		for b in _ke[a]:
			if a < int(b):
				ra.append(Vector2i(a, int(b)))
	return ra


## Sinh mọi lộ trình đơn có đúng `buoc` cạnh. Không quay đầu ngay và không đi lặp một ô trong
## cùng lượt; xúc xắc tối đa 6 nên số lộ trình vẫn rất nhỏ trên graph bàn này.
func cac_duong(tu: int, buoc: int) -> Array[PackedInt32Array]:
	_bao_dam_do_thi()
	var ra: Array[PackedInt32Array] = []
	var duong := PackedInt32Array([_chi_so(tu)])
	_tim_duong(duong, maxi(buoc, 0), ra)
	return ra


func _tim_duong(duong: PackedInt32Array, con_lai: int,
		ra: Array[PackedInt32Array]) -> void:
	if con_lai <= 0:
		ra.append(duong.duplicate())
		return
	var hien_tai := int(duong[duong.size() - 1])
	for tiep in _ke[hien_tai]:
		if duong.has(int(tiep)):
			continue
		var moi := duong.duplicate()
		moi.append(int(tiep))
		_tim_duong(moi, con_lai - 1, ra)


func duong_hop_le(tu: int, duong: PackedInt32Array, buoc: int) -> bool:
	_bao_dam_do_thi()
	if duong.size() != buoc + 1 or duong.is_empty() or int(duong[0]) != _chi_so(tu):
		return false
	for i in range(1, duong.size()):
		if not _ke[int(duong[i - 1])].has(int(duong[i])):
			return false
		if duong.slice(0, i).has(int(duong[i])):
			return false
	return true


func la_nga_re(i: int) -> bool:
	_bao_dam_do_thi()
	return _ke[_chi_so(i)].size() > 2


## Tô các điểm đến khả dĩ và toàn bộ lộ trình đang chọn trên chính các ô 3D.
func noi_bat_duong(cac_duong: Array[PackedInt32Array], dang_chon: int) -> void:
	xoa_noi_bat()
	for d in cac_duong:
		if not d.is_empty():
			_o[int(d[d.size() - 1])].dat_noi_bat(1)
	if dang_chon >= 0 and dang_chon < cac_duong.size():
		for o in cac_duong[dang_chon]:
			_o[int(o)].dat_noi_bat(2)


func xoa_noi_bat() -> void:
	_bao_dam_do_thi()
	for o in _o:
		o.dat_noi_bat(0)


## Ô gần một điểm trong thế giới nhất. Dùng để biết người chơi đang đứng ở ô nào.
func o_gan_nhat(diem: Vector3) -> int:
	_bao_dam_do_thi()
	var tot := 0
	var xa := INF
	for i in _o.size():
		var d := _o[i].global_position.distance_squared_to(diem)
		if d < xa:
			xa = d
			tot = i
	return tot


## Ô CÙNG LOẠI gần nhất theo số cạnh graph. Người chết hồi sinh ở nghĩa địa gần nhất.
##
## Trả về -1 khi cả bàn không có ô loại đó — bản đồ thiếu nghĩa địa thì phải biết ngay, chứ
## không phải im lặng trả về ô 0 rồi hồi sinh người chơi ở một chỗ vô nghĩa.
func gan_nhat_loai(tu: int, l: int) -> int:
	_bao_dam_do_thi()
	var hang := PackedInt32Array([_chi_so(tu)])
	var da_thay := {_chi_so(tu): true}
	while not hang.is_empty():
		var j := int(hang[0])
		hang.remove_at(0)
		if _o[j].loai == l:
			return j
		for tiep in _ke[j]:
			if not da_thay.has(int(tiep)):
				da_thay[int(tiep)] = true
				hang.append(int(tiep))
	return -1


## Sát thương lan theo khoảng cách graph; bậc 0 là tâm, bậc 1 là mọi ô kề, v.v.
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


## Mọi ô thuộc một loại. Dùng để đếm rương, rải vật phẩm, v.v.
func cac_o_loai(l: int) -> PackedInt32Array:
	_bao_dam_do_thi()
	var ra := PackedInt32Array()
	for i in _o.size():
		if _o[i].loai == l:
			ra.append(i)
	return ra


func _chi_so(i: int) -> int:
	return posmod(i, _o.size()) if not _o.is_empty() else 0
