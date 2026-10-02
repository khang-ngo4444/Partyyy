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

@export var loai: BanDuong.Loai = BanDuong.Loai.DAT:
	set(value):
		loai = value
		if is_node_ready():
			_ve()

## Tám vật liệu theo đúng thứ tự enum `BanDuong.Loai`, kéo vào trong `o_ban.tscn`.
## Mọi instance thừa hưởng mảng này, nên từng ô chỉ cần đặt `so` và `loai`.
@export var vat_lieu: Array[StandardMaterial3D] = []

@onready var _mat: MeshInstance3D = $Mat
@onready var _rim: MeshInstance3D = $Rim
@onready var _chu: Label3D = $Chu
var _rim_mat: StandardMaterial3D


func _ready() -> void:
	_rim_mat = _rim.material_override.duplicate() as StandardMaterial3D
	_rim.material_override = _rim_mat
	_ve()


func _ve() -> void:
	if loai >= 0 and loai < vat_lieu.size() and vat_lieu[loai] != null:
		_mat.material_override = vat_lieu[loai]
	var ky := (BanDuong.KY_HIEU[loai] as String
			if loai >= 0 and loai < BanDuong.KY_HIEU.size() else "DAT")
	_chu.text = str(so) if ky == "" else "%d\n%s" % [so, ky]


func hien_trang_thai(loai_moi: int, chu_dat: String, thue_dat: String, co_ruong: bool,
		diem_hoi_sinh: PackedStringArray) -> void:
	loai = loai_moi as BanDuong.Loai
	var dong := PackedStringArray([str(so)])
	if co_ruong:
		dong.append("RUONG ?")
	elif loai == BanDuong.Loai.DAT:
		dong.append("DAT" if chu_dat.is_empty() else "DAT · %s" % chu_dat)
		if not thue_dat.is_empty():
			dong.append("THUE · %s" % thue_dat.to_upper())
	else:
		dong.append(BanDuong.KY_HIEU[loai])
	if not diem_hoi_sinh.is_empty():
		dong.append("HOI SINH · %s" % ", ".join(diem_hoi_sinh))
	_chu.text = "\n".join(dong)


## 0 = bình thường, 1 = điểm đến khác có thể chọn, 2 = lộ trình đang chọn.
func dat_noi_bat(muc: int) -> void:
	if not is_node_ready() or _rim_mat == null:
		return
	match muc:
		1:
			scale = Vector3.ONE * 1.035
			_rim_mat.albedo_color = Color("#d55cff")
			_rim_mat.emission = Color("#7d24d9")
			_rim_mat.emission_energy_multiplier = 1.7
			_chu.modulate = Color("#ffd9ff")
		2:
			scale = Vector3.ONE * 1.085
			_rim_mat.albedo_color = Color("#33fff0")
			_rim_mat.emission = Color("#13cfc3")
			_rim_mat.emission_energy_multiplier = 2.6
			_chu.modulate = Color("#d9fffb")
		_:
			scale = Vector3.ONE
			_rim_mat.albedo_color = Color("#ff9c1f")
			_rim_mat.emission = Color("#8b3906")
			_rim_mat.emission_energy_multiplier = 0.55
			_chu.modulate = Color("#fff7d1")
