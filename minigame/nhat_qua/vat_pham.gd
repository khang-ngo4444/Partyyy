class_name VatPham
extends Area3D

## MỘT món nằm trên làn: quà nhỏ, quà to, hoặc rác.
##
## Cả ba hình đều là node đặt sẵn trong `vat_pham.tscn`; `dat()` chỉ **hiện đúng một cái** và
## giấu hai cái kia. Script không dựng mesh nào.
##
## Nhặt rồi thì `nhat()` giấu cả món đi — không `queue_free()`, vì mọi máy đều tự tính xem ai
## nhặt gì và cần món vẫn còn đó để tính tiếp cho người ở làn khác.

enum { QUA_NHO, QUA_TO, RAC }

## Điểm của từng loại, cùng thứ tự với enum. Rác trừ điểm và CHO PHÉP âm — không cho âm thì
## nửa sau ván người đang thua chẳng có lý do gì để né rác nữa.
const DIEM := [1, 3, -1]

var loai := QUA_NHO
var da_nhat := false


func dat(kieu: int) -> void:
	loai = kieu
	($QuaNho as Node3D).visible = kieu == QUA_NHO
	($QuaTo as Node3D).visible = kieu == QUA_TO
	($Rac as Node3D).visible = kieu == RAC


func diem() -> int:
	return DIEM[loai]


func nhat() -> void:
	da_nhat = true
	visible = false
	monitorable = false
