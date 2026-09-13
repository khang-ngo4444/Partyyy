class_name Pressable
extends Node3D

## Nút bấm. Khuôn chung cho nút reset, nút lật bàn, máy đổi nhạc, chỗ cấp xu.
##
## Nút KHÔNG tự làm gì cả — nó chỉ phát signal `pressed` ở máy người bấm. Ai nghe signal đó
## thì tự quyết định việc gì xảy ra và có cần bảo các máy khác không.

signal pressed

@export var label := "NÚT"
@export var color := Color("e5484d")
## Tầm bấm, đo từ camera như cơ chế nhặt đồ.
@export var press_range := 3.0
## Nút GẮN MẶT PHẲNG: bỏ cột và thu nhỏ, để đặt lên mặt bàn hay mặt trước một cái tủ.
## Nút có cột chỉ hợp khi nó mọc từ sàn.
@export var compact := false
## Cỡ chữ trên nhãn. Nút nhỏ mà chữ to như nút sàn thì chữ che mất cả cái tủ.
@export var label_size := 64
## Nhân thêm vào cỡ nút phẳng. Nút phải NHỎ HƠN khoảng cách giữa hai nút cạnh nhau, nếu
## không chúng dính thành một mảng liền không phân biệt được nút nào với nút nào.
@export var button_scale := 1.0

@onready var text: Label3D = $Label

## Cỡ của khối nút lúc mới dựng. Hiệu ứng bấm phải quay về đúng cỡ này.
var _co_goc := Vector3.ONE


func _ready() -> void:
	add_to_group("pressable")
	if compact:
		# Cột và khối va chạm của nó chỉ có nghĩa khi nút mọc từ sàn.
		$Post.queue_free()
		$Stand.queue_free()
		($Mesh as MeshInstance3D).position.y = 0.05
		var k := 0.55 * button_scale
		_co_goc = Vector3(k, 0.5 * button_scale, k)
		($Mesh as MeshInstance3D).scale = _co_goc
		text.position.y = 0.1 + 0.3 * button_scale
		# `font_size` to ma `pixel_size` giu nguyen thi chu van cao bang nut san. Phai ha
		# ca hai — day moi la con so quyet dinh chu cao bao nhieu MET.
		text.pixel_size = 0.0022
	text.font_size = label_size
	text.text = label
	text.modulate = color
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	($Mesh as MeshInstance3D).material_override = mat


## Đổi chữ trên nút lúc đang chạy. Đường đua dùng nó để hiện số người đã tin con này.
func set_label(txt: String) -> void:
	label = txt
	if text != null:
		text.text = txt


## Chỗ người chơi phải ngắm vào để bấm được nút này: chính cái khối nút.
##
## Trước đây bên Player cộng cứng 1.0 m vào vị trí nút — con số đó viết cho nút mọc từ sàn
## (đầu nút ở độ cao 1.0 m). Nút phẳng gắn trên mặt tủ thì đầu nút chỉ cao vài xăng-ti-mét,
## nên phải ngắm cao hơn nó cả mét mới trúng: nhìn thẳng vào nút thì KHÔNG bấm được.
func diem_ngam() -> Vector3:
	return ($Mesh as MeshInstance3D).global_position


## Người chơi gọi. Chỉ chạy ở máy người bấm.
func press() -> void:
	pressed.emit()
	_flash()


## Phản hồi tại chỗ cho người bấm. Là SỰ KIỆN nên không đồng bộ — người khác thấy kết quả
## của việc bấm, không cần thấy cái nhấp nháy.
## Nhún theo CỠ GỐC CỦA CHÍNH NÚT, không phải về `Vector3.ONE`.
##
## Nút phẳng đã bị thu nhỏ lúc dựng (`button_scale`). Tween về `Vector3.ONE` là xoá luôn cỡ
## đó — bấm một cái là nút phình về cỡ nút sàn và ở luôn như thế. Tám nút đặt cược cạnh nhau
## thì bấm vài cái là dính thành một mảng.
func _flash() -> void:
	var m := $Mesh as MeshInstance3D
	var tween := create_tween()
	tween.tween_property(m, "scale", _co_goc * 0.85, 0.06)
	tween.tween_property(m, "scale", _co_goc, 0.12)
