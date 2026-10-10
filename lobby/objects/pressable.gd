class_name Pressable
extends Node3D

## Nút bấm: chỉ phát `pressed` ở máy người bấm; bên nghe tự quyết làm gì và có đồng bộ không.

signal pressed

## Độ sáng khối nút khi sẵn sàng / đang chờ `cooldown`.
const SANG_SAN_SANG := 0.6
const SANG_DANG_CHO := 0.05

@export var label := "NÚT"
@export var color := Color("e5484d")
## false = giữ vật liệu sẵn có của `Mesh` (cọc Hà Nội), không tô theo `color`.
@export var to_mau := true

## Tầm bấm, đo từ camera như cơ chế nhặt đồ.
@export var press_range := 3.0

## Thời gian chờ giữa hai lần bấm, giây. 0 = không chờ (đa số điểm chạm).
## Chỉ bật cho nút làm việc nặng (spawn bộ cờ, lật bàn) để tránh bấm chồng.
@export var cooldown := 0.0

## Nút gắn mặt phẳng: bỏ cột, thu nhỏ.
@export var compact := false

## Cỡ chữ nhãn.
@export var label_size := 64

## Hệ số cỡ nút phẳng; phải nhỏ hơn khoảng cách giữa hai nút.
@export var button_scale := 1.0

## Cỡ khối nút lúc dựng; hiệu ứng bấm quay về cỡ này.
var _co_goc := Vector3.ONE

## Lúc bấm gần nhất (giây máy); âm để bấm được ngay.
var _bam_luc := -1000.0

## Vật liệu khối nút (local_to_scene), để làm mờ lúc chờ; null khi `to_mau = false`.
var _mat: StandardMaterial3D = null

@onready var text: Label3D = $Label
@onready var _hinh_ngam: CollisionShape3D = $VungNgam/Hinh


func _ready() -> void:
	add_to_group("pressable")
	if compact:
		# Cột chỉ dùng khi nút mọc từ sàn.
		$Post.queue_free()
		$Stand.queue_free()
		($Mesh as MeshInstance3D).position.y = 0.05
		var k := 0.55 * button_scale
		_co_goc = Vector3(k, 0.5 * button_scale, k)
		($Mesh as MeshInstance3D).scale = _co_goc
		text.position.y = 0.1 + 0.3 * button_scale
		# Phải hạ cả `pixel_size` mới đổi được chiều cao chữ.
		text.pixel_size = 0.0022
	text.font_size = label_size
	# Viền theo cỡ chữ thật (`label_size` chưa có lúc `_sua_chu_3d` chạy).
	text.outline_size = maxi(text.outline_size, roundi(label_size * 0.2))
	text.text = label
	text.modulate = color
	if to_mau:
		_mat = ($Mesh as MeshInstance3D).material_override as StandardMaterial3D
		_mat.albedo_color = color
		_mat.emission = color
	_do_vung_ngam()


## Vùng ngắm ôm các lưới của nút (bỏ `Post`); đo lúc chạy vì `compact` co nút lại.
func _do_vung_ngam() -> void:
	var bao := AABB()
	var co := false
	var ve_goc := global_transform.affine_inverse()
	for m: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null or m.name == &"Post":
			continue
		var a := (ve_goc * m.global_transform) * m.mesh.get_aabb()
		bao = a if not co else bao.merge(a)
		co = true
	(_hinh_ngam.shape as BoxShape3D).size = bao.size
	_hinh_ngam.position = bao.get_center()


## Đổi chữ trên nút lúc chạy.
func set_label(txt: String) -> void:
	label = txt
	if text != null:
		text.text = txt


## Điểm ngắm để bấm: chính khối nút.
func diem_ngam() -> Vector3:
	return ($Mesh as MeshInstance3D).global_position


## Người chơi gọi ở máy họ; đang chờ thì im lặng.
func press() -> void:
	if not san_sang():
		return
	_bam_luc = _gio()
	pressed.emit()
	_flash()


## Đã hết thời gian chờ chưa.
func san_sang() -> bool:
	return _gio() - _bam_luc >= cooldown


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


## Phản hồi tại chỗ: nhún rồi tối đi hết `cooldown` (không đồng bộ).
## Nhún theo cỡ gốc của nút, không về `Vector3.ONE`.
func _flash() -> void:
	var m := $Mesh as MeshInstance3D
	var tween := create_tween()
	tween.tween_property(m, "scale", _co_goc * 0.85, 0.06)
	tween.tween_property(m, "scale", _co_goc, 0.12)
	if _mat == null:
		return
	_mat.emission_energy_multiplier = SANG_DANG_CHO
	tween.tween_interval(maxf(cooldown - 0.18, 0.0))
	tween.tween_property(_mat, "emission_energy_multiplier", SANG_SAN_SANG, 0.15)
