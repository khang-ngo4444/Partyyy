class_name OSan
extends Node3D

## MỘT ô sàn của sân đấu.
##
## Hình dạng và va chạm nằm trong `o_san.tscn`. Script này **không dựng node nào** — nó chỉ
## bật/tắt ô và đổi vật liệu, và đó là toàn bộ việc của nó.
##
## Tắt ô phải tắt **cả va chạm**, không chỉ giấu mặt: giấu mà để nguyên `StaticBody3D` thì
## người chơi đứng trên khoảng không vô hình và không ai hiểu vì sao mình không rơi.

## Màu mặc định của ô. Trò nào cần màu khác thì gọi `son()`.
@export var vat_lieu_thuong: StandardMaterial3D = null

@onready var _mat: MeshInstance3D = $Mat
@onready var _than: StaticBody3D = $Than


func dat(hien: bool) -> void:
	visible = hien
	_than.collision_layer = 1 if hien else 0
	if hien:
		_mat.material_override = vat_lieu_thuong


## Sơn ô. `null` = trả về màu thường.
##
## T3 (Bounding Blocks) dùng để đánh dấu chủ ô, T2 (Breaking Blocks) dùng cho bốn mức nứt.
##
## Tách khỏi `dat()` chứ không thêm tham số: hai trò hỏi hai câu khác hẳn nhau — "ô còn hay tan"
## và "ô màu gì". Nhét chung một hàm thì mỗi bên phải truyền một tham số mình không quan tâm.
func son(vat_lieu: StandardMaterial3D) -> void:
	_mat.material_override = vat_lieu if vat_lieu != null else vat_lieu_thuong
