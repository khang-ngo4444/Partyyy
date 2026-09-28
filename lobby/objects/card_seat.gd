class_name CardSeat
extends Node3D

## Ghế ở bàn bài. Ngắm ghế bấm E là xin ngồi; Q là xin đứng dậy.
##
## Ghế KHÔNG tự quyết định gì, cũng không bắt va chạm nữa. Player gửi yêu cầu cho CardDealer,
## master xếp chỗ rồi phát trạng thái bàn về mọi máy (`CardDealer.nguoi_o_ghe`). Ghế chỉ ĐỌC
## lại trạng thái đó để hiện tên người ngồi / "NGOI" / "DANG CHOI".
##
## Trước đây đi xuyên vào ghế là ngồi, bước ra là đứng: người chơi vẫn đi lại tự do, và tự
## đứng dậy giữa ván chỉ vì trượt chân. Giờ ghế chỉ đổi chủ khi master đồng ý.

## Ghế: node `Model` trong card_seat.tscn — xoay/co dãn ghế ngay trong editor.
## Đọc lại trạng thái 4 lần/giây. Tên trên ghế cho người đọc, không phải vật lý.
const REFRESH := 0.25
## Đứng dậy thì đặt người ra NGOÀI ghế chừng này, về phía xa bàn — không đặt vào giữa bàn.
const RA_XA := 0.9
## Hộp NGẮM của ghế, trong hệ toạ độ của ghế.
##
## Ghế CÓ CHỦ ĐÍCH không có hình va chạm (đi xuyên ghế không còn là ngồi nữa), nên tia ngắm
## cần một Area3D riêng mới trúng được. Số đo theo ghế Quaternius ở tỉ lệ 0.509 trong
## card_seat.tscn — đổi model ghế thì chỉnh hai số này, không có cách suy ra tự động.
@export var hop_ngam := Vector3(0.55, 0.95, 0.55)
@export var hop_ngam_y := 0.48

## CardTable gán lúc dựng.
var deck := 0
var index := 0
## Id người đang ngồi, 0 nếu trống. Mọi máy đều có — đọc từ trạng thái master phát.
var nguoi := 0
## Người ở MÁY NÀY có đang ngồi ghế này không. HUD, CardTable và Player hỏi biến này.
var toi_dang_ngoi := false

var _mat := StandardMaterial3D.new()
var _glow: MeshInstance3D
var _tag: Label3D = null
var _acc := 0.0


func _ready() -> void:
	add_to_group("card_seat")
	_build()


func _process(delta: float) -> void:
	_acc += delta
	if _acc < REFRESH:
		return
	_acc = 0.0
	var d := get_tree().get_first_node_in_group("card_dealer") as CardDealer
	if d == null:
		return
	nguoi = d.nguoi_o_ghe(deck, index)
	toi_dang_ngoi = nguoi != 0 and nguoi == NetManager.local_id()
	_set_lit(toi_dang_ngoi)
	if nguoi != 0:
		_tag.text = Player.ten_theo_id(get_tree(), nguoi)
		_tag.modulate = Color.WHITE
	elif int(d.pha_ban.get(deck, CardDealer.PHA_CHO)) == CardDealer.PHA_CHOI:
		# KHOÁ: đang có ván, ngồi vào lúc này không có bài.
		_tag.text = "DANG CHOI"
		_tag.modulate = Color("8b8d98")
	else:
		_tag.text = "NGOI"
		_tag.modulate = Color("d9c98a")


## Ghế đang trống và không bị khoá — Player dùng để chọn chữ gợi ý.
func con_trong() -> bool:
	var d := get_tree().get_first_node_in_group("card_dealer") as CardDealer
	return nguoi == 0 and d != null 			and int(d.pha_ban.get(deck, CardDealer.PHA_CHO)) != CardDealer.PHA_CHOI


## Chỗ đặt người khi ngồi: đúng tâm ghế, MẶT QUAY VÀO TÂM BÀN.
func diem_ngoi() -> Transform3D:
	return Transform3D(Basis.looking_at(_huong_vao_ban(), Vector3.UP), global_position)


## Chỗ đặt người khi đứng dậy: ra ngoài ghế, về phía xa bàn.
func diem_dung_day() -> Vector3:
	return global_position - _huong_vao_ban() * RA_XA


func _huong_vao_ban() -> Vector3:
	var ban := get_parent() as Node3D
	var v := (ban.global_position - global_position) if ban != null else Vector3.FORWARD
	v.y = 0.0
	return v.normalized() if v.length() > 0.001 else Vector3.FORWARD


## Chỉ là phản hồi tại chỗ cho người ở máy này: ghế MÌNH đang ngồi thì đế sáng xanh.
func _set_lit(on: bool) -> void:
	_mat.albedo_color = Color("46a758") if on else Color("6b4a2f")
	_mat.emission = _mat.albedo_color
	_mat.emission_energy_multiplier = 1.4 if on else 0.2


func _build() -> void:
	_mat.emission_enabled = true
	_set_lit(false)

	# Đế sáng dưới chân ghế — dấu hiệu "đang ngồi", KHÔNG phải hình cái ghế nữa (ghế thật
	# là node `Model` trong scene). Để mỏng và nhỏ hơn đế ghế để không che mất chân ghế thật.
	_glow = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.34
	cm.bottom_radius = 0.34
	cm.height = 0.02
	_glow.mesh = cm
	_glow.material_override = _mat
	_glow.position.y = 0.01
	add_child(_glow)

	var hinh := BoxShape3D.new()
	hinh.size = hop_ngam
	var cs := CollisionShape3D.new()
	cs.shape = hinh
	cs.position.y = hop_ngam_y
	var vung := Area3D.new()
	vung.name = "VungNgam"
	vung.collision_layer = Player.LOP_NGAM
	vung.collision_mask = 0
	vung.monitoring = false
	vung.add_child(cs)
	add_child(vung)

	_tag = Label3D.new()
	_tag.text = "NGOI"
	_tag.font_size = 28
	_tag.pixel_size = 0.002
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.outline_size = 8
	_tag.modulate = Color("d9c98a")
	_tag.position = Vector3(0.0, 1.1, 0.0)
	add_child(_tag)
