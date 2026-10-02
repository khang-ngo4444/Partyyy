class_name VetSang
extends Node3D

## MỘT vệt sáng vẽ trên sàn — dải lõi phát sáng mạnh và một quầng mờ rộng hơn quanh nó.
##
## Hai `MeshInstance3D` và vật liệu nằm trong `vet_sang.tscn`. Script chỉ dựng HÌNH dải: hình đó
## là đường cong sinh lúc chạy từ hạt giống (`DuongVet.tao`), không thể vẽ sẵn trong editor — đúng
## lý do hợp lệ duy nhất để dựng lưới bằng code (ASSET-CAN-THEM.md).

## Bề ngang dải lõi và quầng, mét. Lõi hẹp hơn hẳn đường hợp lệ (2,5 m): thứ người chơi cần nhớ là
## HÌNH đường đi, không phải mép của một con đường.
const RONG_LOI := 0.42
const RONG_QUANG := 1.5
## Độ đục của quầng khi sáng hẳn.
const DUC_QUANG := 0.22

@onready var _loi: MeshInstance3D = $Loi
@onready var _quang: MeshInstance3D = $Quang
var _mat_loi: StandardMaterial3D = null
var _mat_quang: StandardMaterial3D = null


## Dựng dải theo các điểm `ds` (xz cục bộ trong sân) với màu `mau`.
func dung(ds: PackedVector2Array, mau: Color) -> void:
	_loi.mesh = _dai(ds, RONG_LOI)
	_quang.mesh = _dai(ds, RONG_QUANG)
	# Màu là của từng người, nên mỗi vệt một bản vật liệu. Bản gốc trong `.tscn` giữ mọi thông số
	# khác (phát sáng, trong suốt, hai mặt).
	_mat_loi = (_loi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	_mat_loi.albedo_color = mau
	_mat_loi.emission = mau
	_loi.material_override = _mat_loi
	_mat_quang = (_quang.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	_mat_quang.albedo_color = Color(mau, DUC_QUANG)
	_quang.material_override = _mat_quang


## 1 = sáng hẳn, 0 = biến mất HẲN (ẩn node, không để lại viền mờ nào).
func do_sang(a: float) -> void:
	visible = a > 0.001
	if _mat_loi == null:
		return
	_mat_loi.albedo_color.a = a
	_mat_quang.albedo_color.a = DUC_QUANG * a


## Một dải phẳng nằm trên mặt sàn, chạy dọc các điểm. Pháp tuyến ngang lấy từ tiếp tuyến tại mỗi
## điểm, nên dải uốn theo đúng đường cong — không có khúc gãy.
static func _dai(ds: PackedVector2Array, rong: float) -> ArrayMesh:
	var dinh := PackedVector3Array()
	var phap := PackedVector3Array()
	var n := ds.size()
	for j in n:
		var t := ds[mini(j + 1, n - 1)] - ds[maxi(j - 1, 0)]
		var ngang := t.normalized().orthogonal() * (rong * 0.5)
		dinh.append(Vector3(ds[j].x + ngang.x, 0.0, ds[j].y + ngang.y))
		dinh.append(Vector3(ds[j].x - ngang.x, 0.0, ds[j].y - ngang.y))
		phap.append(Vector3.UP)
		phap.append(Vector3.UP)
	var mang := []
	mang.resize(Mesh.ARRAY_MAX)
	mang[Mesh.ARRAY_VERTEX] = dinh
	mang[Mesh.ARRAY_NORMAL] = phap
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, mang)
	return m
