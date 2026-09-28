class_name OBan
extends Node3D

## MỘT ô trên bàn party.
##
## Hình dạng, va chạm và nhãn nằm trong `o_ban.tscn`. Script này **không dựng node nào** —
## nó chỉ đổi vật liệu và chữ theo loại ô, và đó là toàn bộ việc của nó.
##
## Loại ô và số thứ tự đặt trong Inspector của từng instance trong `ban_party.tscn`. Làm bản
## đồ mới = mở scene lên kéo và sửa, không đụng tới một dòng code nào.

## Số thứ tự trên vòng, 0 trở đi. `BanDuong` sắp các ô theo số này chứ không theo tên node —
## đổi tên node hay kéo lung tung trong cây cũng không làm sai thứ tự đi.
@export var so := 0:
	set(value):
		so = value
		if is_node_ready():
			_ve()

@export var loai: BanDuong.Loai = BanDuong.Loai.TRONG:
	set(value):
		loai = value
		if is_node_ready():
			_ve()

## Tám vật liệu theo đúng thứ tự enum `BanDuong.Loai`, kéo vào trong `o_ban.tscn`.
## Mọi instance thừa hưởng mảng này, nên từng ô chỉ cần đặt `so` và `loai`.
@export var vat_lieu: Array[StandardMaterial3D] = []

@onready var _mat: MeshInstance3D = $Mat
@onready var _chu: Label3D = $Chu


func _ready() -> void:
	_ve()


func _ve() -> void:
	if loai >= 0 and loai < vat_lieu.size() and vat_lieu[loai] != null:
		_mat.material_override = vat_lieu[loai]
	var ky: String = BanDuong.KY_HIEU[loai]
	_chu.text = str(so) if ky == "" else "%d\n%s" % [so, ky]
