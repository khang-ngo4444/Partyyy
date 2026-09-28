class_name BanDuong
extends Node3D

## Bàn party: một VÒNG KÍN các ô, quân đi theo lượt.
##
## ## Script này KHÔNG dựng ô nào
##
## 24 ô là instance của `o_ban.tscn` đặt sẵn trong `ban_party.tscn`. Đổi hình bàn, đổi loại ô,
## thêm hay bớt ô: **mở scene lên kéo trong editor**, không đụng tới file này. Ở đây chỉ còn
## câu hỏi mà phần chơi cần trả lời — ô số mấy loại gì, đứng ở đâu, đi 5 bước thì tới ô nào.
##
## Khác hẳn `ChessBoard`. `ChessBoard` là một LƯỚI PHẲNG: nó biết toạ độ ô (col, row) nhưng
## không biết ô nào nối ô nào. Thiết kế chìa khoá/cốc cần đúng cái nó không có — "tung xúc xắc
## đi 5 bước", "bom lan sang ô bên cạnh" đều hỏi *ô kế tiếp là ô nào*.

enum Loai { TRONG, CHIA, SAT_THUONG, BI_AN, RUONG, NGHIA_DIA, CUA_HANG, NGUY_HIEM }

const TEN_LOAI := ["Trống", "Chìa khoá", "Sát thương", "Bí ẩn", "Rương", "Nghĩa địa",
		"Cửa hàng", "Nguy hiểm"]
## Ký hiệu ngắn trên mặt ô. Chữ THƯỜNG chứ không emoji: font mặc định của Godot không có
## emoji, nó hiện ra ô vuông rỗng hoặc mất hẳn.
const KY_HIEU := ["", "CHIA", "-MAU", "?", "RUONG", "HOI SINH", "SHOP", "NGUY"]

var _o: Array[OBan] = []


func _ready() -> void:
	add_to_group("ban_duong")
	_o.assign(find_children("*", "OBan", false, false))
	# Sắp theo `so` trong Inspector chứ không theo thứ tự trong cây: kéo node lung tung hay
	# đổi tên node cũng không làm lệch vòng đi.
	_o.sort_custom(func(a: OBan, b: OBan) -> bool: return a.so < b.so)
	if _o.is_empty():
		push_error("BanDuong: '%s' khong co o nao. Ban do phai chua instance cua o_ban.tscn."
				% name)


func so_luong() -> int:
	return _o.size()


func loai(i: int) -> int:
	return _o[_chi_so(i)].loai if not _o.is_empty() else Loai.TRONG


## Đổi loại một ô LÚC ĐANG CHƠI. Rương di chuyển sau mỗi lần mở, xem `PhaBanCo._ap_ruong()`.
##
## `OBan.loai` có setter tự đổi vật liệu và nhãn, nên ở đây chỉ gán một giá trị — không dựng
## lại node nào. Bản đồ trong `.tscn` không bị sửa: đóng bàn là mọi thứ về như cũ.
func dat_loai(i: int, l: int) -> void:
	if not _o.is_empty():
		_o[_chi_so(i)].loai = l as BanDuong.Loai


## Toạ độ thế giới của mặt ô — chỗ đặt chân người chơi.
func vi_tri(i: int) -> Vector3:
	return _o[_chi_so(i)].global_position if not _o.is_empty() else global_position


## Đi `buoc` bước từ ô `i`. Vòng kín nên luôn hợp lệ, không bao giờ rơi ra ngoài bàn.
func tien(i: int, buoc: int) -> int:
	return _chi_so(i + buoc)


## Ô gần một điểm trong thế giới nhất. Dùng để biết người chơi đang đứng ở ô nào.
func o_gan_nhat(diem: Vector3) -> int:
	var tot := 0
	var xa := INF
	for i in _o.size():
		var d := _o[i].global_position.distance_squared_to(diem)
		if d < xa:
			xa = d
			tot = i
	return tot


## Ô CÙNG LOẠI gần nhất tính theo số bước, đi cả hai chiều. Người chết hồi sinh ở nghĩa địa
## gần nhất thì hỏi hàm này.
##
## Trả về -1 khi cả bàn không có ô loại đó — bản đồ thiếu nghĩa địa thì phải biết ngay, chứ
## không phải im lặng trả về ô 0 rồi hồi sinh người chơi ở một chỗ vô nghĩa.
func gan_nhat_loai(tu: int, l: int) -> int:
	for b in range(_o.size()):
		for chieu in [1, -1]:
			var j := _chi_so(tu + b * chieu)
			if _o[j].loai == l:
				return j
	return -1


## Mọi ô thuộc một loại. Dùng để đếm rương, rải vật phẩm, v.v.
func cac_o_loai(l: int) -> PackedInt32Array:
	var ra := PackedInt32Array()
	for i in _o.size():
		if _o[i].loai == l:
			ra.append(i)
	return ra


func _chi_so(i: int) -> int:
	return posmod(i, _o.size()) if not _o.is_empty() else 0
