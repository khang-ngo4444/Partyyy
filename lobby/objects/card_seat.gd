class_name CardSeat
extends Node3D

## Ghế bàn bài: ngắm bấm E xin ngồi, Q xin đứng.
## Master xếp chỗ (`CardDealer.nguoi_o_ghe`), ghế chỉ đọc lại.

## Đọc lại trạng thái 4 lần/giây.
const REFRESH := 0.25
## Đứng dậy thì đặt người ra ngoài ghế chừng này, về phía xa bàn.
const RA_XA := 0.9

## Bàn và số ghế (đặt trong scene bàn); -1 = không thuộc bàn nào.
@export var deck := 0
@export var index := 0
## Id người đang ngồi, 0 = trống (đọc từ trạng thái master).
var nguoi := 0
## Người ở máy này có đang ngồi ghế này không.
var toi_dang_ngoi := false

## Ghế gắn trên vật đang chạy (tàu): người ngồi phải bám theo `diem_ngoi()` mỗi khung.
var di_dong := false
var _acc := 0.0

## Ghế không có va chạm; tia ngắm trúng `VungNgam` (Area3D) trong scene.
@onready var _tag: Label3D = $Tag
## Đế sáng; ghế không có `Glow` (ghế lái tàu) thì null.
@onready var _mat: StandardMaterial3D = _vat_lieu_de()


func _ready() -> void:
	add_to_group("card_seat")
	_set_lit(false)


func _vat_lieu_de() -> StandardMaterial3D:
	var de := get_node_or_null("Glow") as MeshInstance3D
	return de.material_override as StandardMaterial3D if de != null else null


## Người chơi bấm E vào ghế trống: xin ngồi. Ghế bài phải hỏi nhà cái.
func xin_ngoi() -> void:
	var d := get_tree().get_first_node_in_group("card_dealer") as CardDealer
	if d != null:
		d.request_sit(deck, index)


## Người đang ngồi bấm Q.
func xin_dung_day() -> void:
	var d := get_tree().get_first_node_in_group("card_dealer") as CardDealer
	if d != null:
		d.request_stand_up(deck, index)


## Vật được phủ viền khi ngắm vào ghế (mặc định chính ghế).
func vat_vien() -> Node3D:
	return self


## Dòng nhắc trên HUD khi mình ngồi ghế không thuộc bàn bài (`deck < 0`).
func loi_nhac() -> String:
	return ""


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
		# Đang có ván, ngồi lúc này không có bài.
		_tag.text = "DANG CHOI"
		_tag.modulate = Color("8b8d98")
	else:
		_tag.text = "NGOI"
		_tag.modulate = Color("d9c98a")


## Ghế trống và không bị khoá.
func con_trong() -> bool:
	var d := get_tree().get_first_node_in_group("card_dealer") as CardDealer
	return nguoi == 0 and d != null \
			and int(d.pha_ban.get(deck, CardDealer.PHA_CHO)) != CardDealer.PHA_CHOI


## Chỗ ngồi: tâm ghế, mặt quay vào tâm bàn.
func diem_ngoi() -> Transform3D:
	return Transform3D(Basis.looking_at(_huong_vao_ban(), Vector3.UP), global_position)


## Chỗ đứng dậy: ngoài ghế, về phía xa bàn.
func diem_dung_day() -> Vector3:
	return global_position - _huong_vao_ban() * RA_XA


func _huong_vao_ban() -> Vector3:
	var ban := get_parent() as Node3D
	var v := (ban.global_position - global_position) if ban != null else Vector3.FORWARD
	v.y = 0.0
	return v.normalized() if v.length() > 0.001 else Vector3.FORWARD


## Ghế mình đang ngồi thì đế sáng xanh (chỉ máy này).
func _set_lit(on: bool) -> void:
	if _mat == null:
		return
	_mat.albedo_color = Color("46a758") if on else Color("6b4a2f")
	_mat.emission = _mat.albedo_color
	_mat.emission_energy_multiplier = 1.4 if on else 0.2
