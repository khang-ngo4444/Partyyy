class_name Vet
extends Area3D

## MỘT đoạn tường sáng do người chơi để lại sau lưng. Đâm vào là chết ngay.
##
## Hình bức tường và hộp va chạm nằm trong `vet.tscn` và **bằng nhau tuyệt đối**: cả hai là con
## của node này, nên `scale` kéo dài cái nào là kéo dài luôn cái kia. Thấy tường tới đâu thì chết
## tới đó — không có vùng chết vô hình, cũng không có tường "xuyên được".
##
## Tường SỐNG TỚI HẾT VÁN (bản đầu tự tan sau 12 giây — bỏ, vì cả trò là sân chật dần). Script chỉ
## lo **đặt đúng chỗ**; dọn tường là việc của sân, bị xoá cùng sân khi ván kết thúc.

## Chiều dài gốc của mesh trong `.tscn`, theo trục Z. `dat()` kéo `scale.z` theo tỉ lệ này.
const DAI_GOC := 1.0
## Bề dày tường, khớp `.tscn`. Mỗi đoạn được kéo dài thêm chừng này để hai đoạn liền nhau chồng
## mí lên nhau ở chỗ rẽ — không thì góc ngoài chỗ rẽ hở một khe tam giác chui lọt được.
const DAY := 0.3

## Ai để lại vệt này. Chủ vệt được tha những đoạn vừa nhả — xem `AN_TOAN` ở `temporal_trails.gd`.
var nguoi := 0
## Giờ ván lúc vệt được đặt.
var luc := 0.0


## Dựng một đoạn tường nối `tu` tới `den`, sơn bằng `vat_lieu`.
func dat(chu: int, gio_van: float, tu: Vector3, den: Vector3, vat_lieu: Material) -> void:
	nguoi = chu
	luc = gio_van
	var dai := tu.distance_to(den)
	global_position = (tu + den) * 0.5
	if dai > 0.001:
		# `look_at` quay -Z về phía nhìn, nên tường nằm dọc theo hướng đi.
		look_at(Vector3(den.x, global_position.y, den.z), Vector3.UP)
		scale.z = (dai + DAY) / DAI_GOC
	if vat_lieu != null:
		($Mat as MeshInstance3D).material_override = vat_lieu
