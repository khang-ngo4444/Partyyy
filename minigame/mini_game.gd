class_name MiniGame
extends Node

## HỢP ĐỒNG chung cho mọi minigame. Lớp con cài `bat_dau()` rồi phát `xong()` — hết.
##
## Người gọi (`QuanTroMiniGame`) không biết gì về luật của minigame, và minigame không biết gì
## về bàn cờ hay chìa khoá. Hai bên chỉ trao đổi đúng hai thứ: DANH SÁCH NGƯỜI CHƠI đi vào, và
## BẢNG XẾP HẠNG đi ra.
##
## Nhờ vậy thêm một minigame mới = thêm một scene, không sửa dòng nào ở phần bàn cờ. Và bàn cờ
## đổi cách thưởng chìa khoá cũng không đụng tới minigame nào.
##
## ## Ai mô phỏng
##
## Minigame KHÔNG có server riêng. Nó chạy trên mọi máy cùng lúc, và tự chọn cách giữ đồng bộ:
##
##   - Đua gà: master gieo MỘT hạt giống rồi mọi máy tính ra cùng kết quả.
##   - Tank: mỗi người tự lái xe của mình, chỉ phát SỰ KIỆN (đổi hướng, bắn, trúng) qua RPC.
##
## Cách nào cũng được, miễn là `xong()` phát ra CÙNG một bảng xếp hạng trên mọi máy — vì bảng
## đó quyết định ai được bao nhiêu chìa khoá.

## Bảng xếp hạng: mảng player_id, giỏi nhất đứng đầu. Phát trên MỌI máy với cùng nội dung.
signal xong(xep_hang: Array)

## Che kín màn hình bằng nền đục lúc chơi.
##
## Trò 2D vẽ NGAY TRONG lớp phủ nên cần nền che phòng chờ phía sau (Tank). Trò 3D thì ngược
## lại: nó dựng sân thật trong thế giới, nền đục che mất đúng cái nó vừa dựng — đã thấy tận
## mắt, màn hình đen thui chỉ còn mỗi dòng chữ.
@export var che_nen := true

## Tên hiện trên màn hình chờ.
@export var ten := "Minigame"
## Câu luật một dòng, hiện lúc đếm ngược.
@export var luat := ""


## Bắt đầu với danh sách player_id tham gia. Lớp con ghi đè.
##
## `hat_giong` do master gieo và phát cho mọi máy — dùng nó cho MỌI phép ngẫu nhiên trong
## minigame. Dùng `randi()` trần là mỗi máy ra một bản đồ khác nhau.
func bat_dau(_nguoi_choi: Array, _hat_giong: int) -> void:
	push_error("MiniGame: lop con phai cai bat_dau()")


## Dừng giữa chừng (có người thoát phòng, master huỷ ván). Lớp con dọn dẹp nếu cần.
func dung_som() -> void:
	pass
