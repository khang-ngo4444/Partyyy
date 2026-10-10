class_name CommunityBoard
extends Node3D

## Bảng dựng đứng ở mép bàn phía nhà cái, hiện lại 5 lá bài chung cho dễ đọc.
## Hoàn toàn cục bộ: đọc lại các lá đã replicate, không dùng mạng.

## Đọc lại 4 lần/giây.
const REFRESH := 0.25

## Ảnh bài, gán trong community_board.tscn.
@export var bo_bai: CardDeck
@export var card_w := 0.08

## Khe trống giữa hai lá.
@export var card_space := 0.02

@export var board_h := 0.25
@export var board_thick := 0.02

## Ô bài chung để đọc (bàn poker đặt trong scene).
@export var spot: CardSpot = null
var _acc := 0.0
var _dau_van := ""


func _ready() -> void:
	add_to_group("community_board")


func _process(delta: float) -> void:
	_acc += delta
	if _acc < REFRESH:
		return
	_acc = 0.0
	var moi := _dau_van_hien_tai()
	if moi != _dau_van:
		_dau_van = moi
		_ve_lai()


## Năm lá chung theo thứ tự chia, kèm ngửa/úp (lá chưa lật vẽ mặt lưng).
func _bai_chung() -> Array:
	if spot == null:
		return []
	var ds: Array = []
	for c in get_tree().get_nodes_in_group("card"):
		var card := c as Card
		if card == null:
			continue
		var d: Vector3 = spot.to_local(card.global_position)
		if absf(d.x) <= spot.size.x * 0.5 and absf(d.z) <= spot.size.y * 0.5:
			ds.append({"x": d.x, "idx": card.card_index, "up": card.face_down})
	ds.sort_custom(func(a, b): return a["x"] < b["x"])
	return ds


func _dau_van_hien_tai() -> String:
	var s := ""
	for x in _bai_chung():
		s += "%d%s," % [x["idx"], "u" if x["up"] else "n"]
	return s


## Mặt bài `Bai/Truoc*` và `Bai/Sau*` dựng sẵn trong scene; ở đây chỉ xếp và gán ảnh.
func _ve_lai() -> void:
	var bai := _bai_chung()
	var n := mini(bai.size(), 5)
	var y := board_h * 0.5 + 0.02
	var z := board_thick * 0.5 + 0.002
	for i in 5:
		var truoc := get_node("Bai/Truoc%d" % i) as MeshInstance3D
		var sau := get_node("Bai/Sau%d" % i) as MeshInstance3D
		truoc.visible = i < n
		sau.visible = i < n
		if i >= n:
			continue
		var anh: Texture2D = bo_bai.lung if bai[i]["up"] else bo_bai.anh(bai[i]["idx"])
		var dx := (i - (n - 1) * 0.5) * (card_w + card_space)
		# Mặt sau đảo thứ tự x để nhìn từ phía nhà cái vẫn đọc trái sang phải.
		truoc.position = Vector3(dx, y, z)
		sau.position = Vector3(-dx, y, -z)
		(truoc.material_override as StandardMaterial3D).albedo_texture = anh
		(sau.material_override as StandardMaterial3D).albedo_texture = anh
