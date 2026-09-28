class_name Vet
extends Area3D

## MỘT đoạn vệt do người chơi để lại sau lưng.
##
## Hình bức tường và hộp va chạm nằm trong `vet.tscn` và **bằng nhau tuyệt đối**: cả hai là con
## của node này, nên `scale` kéo dài cái nào là kéo dài luôn cái kia. Không có con số chiều dài
## nào chép tay trong code.
##
## Script chỉ lo **đặt đúng chỗ rồi tự tan**.

## Vệt sống bao lâu rồi biến mất, giây.
##
## Đây là núm chỉnh chính của trò: để vĩnh viễn thì sân kín đặc sau nửa phút và ván thành đua
## xem ai chết sau; ngắn quá thì không bao giờ có bức tường nào đủ dài để bẫy được ai.
const SONG := 12.0

## Chiều dài gốc của mesh trong `.tscn`, theo trục Z. `dat()` kéo `scale.z` theo tỉ lệ này.
const DAI_GOC := 1.0

## Ai để lại vệt này. Chủ vệt được tha trong ít giây đầu — xem `AN_TOAN` ở `temporal_trails.gd`.
var nguoi := 0
## Giờ ván lúc vệt được đặt. Dùng để miễn trừ chủ vệt lúc mới đi qua.
var luc := 0.0

var _con := SONG


## Dựng một đoạn tường nối `tu` tới `den`.
func dat(chu: int, gio_van: float, tu: Vector3, den: Vector3, vat_lieu: StandardMaterial3D) -> void:
	nguoi = chu
	luc = gio_van
	var giua := (tu + den) * 0.5
	var dai := tu.distance_to(den)
	global_position = giua
	if dai > 0.001:
		# `look_at` quay -Z về phía nhìn, nên tường nằm dọc theo hướng đi.
		look_at(den, Vector3.UP)
		scale.z = dai / DAI_GOC
	if vat_lieu != null:
		($Mat as MeshInstance3D).material_override = vat_lieu


func _process(delta: float) -> void:
	_con -= delta
	if _con <= 0.0:
		queue_free()
