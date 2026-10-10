class_name MiniGame
extends Node

## Hợp đồng chung của minigame: nhận danh sách người chơi (`bat_dau`), phát bảng xếp hạng (`xong`).
## Minigame chạy trên mọi máy và tự giữ đồng bộ; `xong` phải ra cùng một bảng ở mọi máy.

## Mảng player_id, giỏi nhất đứng đầu.
signal xong(xep_hang: Array)

## Nền đục che phòng chờ (trò 2D cần, trò 3D thì tắt).
@export var che_nen := true
@export var ten := "Minigame"
## Luật một dòng, hiện lúc đếm ngược.
@export var luat := ""


## Lớp con ghi đè. Mọi phép ngẫu nhiên phải dùng `hat_giong` (master gieo).
func bat_dau(_nguoi_choi: Array, _hat_giong: int) -> void:
	push_error("MiniGame: lop con phai cai bat_dau()")


## Dừng giữa chừng; lớp con dọn dẹp nếu cần.
func dung_som() -> void:
	pass


# ─── ô điểm chung (QuanTroMiniGame vẽ ở đáy màn hình) ───

## Điểm để sắp ô điểm; `NAN` = trò không có ô điểm.
func diem_cua(_id: int) -> float:
	return NAN


func chu_diem(id: int) -> String:
	return "%.0f" % diem_cua(id)
