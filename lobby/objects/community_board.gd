class_name CommunityBoard
extends Node3D

## Bảng đọc bài chung: MỘT tấm gỗ mỏng dựng đứng ở MÉP BÀN phía nhà cái, quay mặt về dãy ghế.
##
## Thay cho cái trụ đen bốn mặt giữa bàn trước đây — nó to, tối, che mất người ngồi đối diện.
## Bài thật vẫn nằm phẳng trên mặt nỉ (lệch về phía nhà cái); tấm này chỉ dựng chúng đứng lên
## cho dễ đọc.
##
## HOÀN TOÀN CỤC BỘ, KHÔNG DÙNG MẠNG.
##
## Nó chỉ ĐỌC LẠI những lá bài chung đã nằm sẵn trên bàn — mà chúng vốn là object mạng đã
## replicate cả vị trí lẫn `card_index` lẫn `face_down`. Máy nào cũng tự dựng ra đúng cùng
## một bảng. Thêm một object mạng nữa chỉ để hiển thị là tốn băng thông vô ích, và tạo thêm
## một nguồn sự thật thứ hai có thể lệch với bàn.

const DIR := "res://asset/kenney_playing-cards/PNG/Cards (medium)/"

@export var card_w := 0.08
@export var card_h := 0.12
## Khoảng TRỐNG giữa hai lá (không phải khoảng cách tâm).
@export var card_space := 0.02
## Spec ghi rộng 0.4 m, nhưng 5 lá × 0.08 + 4 khe × 0.02 đã là 0.48 m — 0.4 m không chứa nổi.
@export var board_w := 0.52
@export var board_h := 0.25
@export var board_thick := 0.02

## Đọc lại 4 lần/giây. Đây là bảng cho người đọc, không phải vật lý.
const REFRESH := 0.25

var spot: CardSpot = null

var _acc := 0.0
var _dau_van := ""
var _than: Node3D = null


func _ready() -> void:
	add_to_group("community_board")
	_than = Node3D.new()
	add_child(_than)
	_dung_bang()


func _process(delta: float) -> void:
	_acc += delta
	if _acc < REFRESH:
		return
	_acc = 0.0
	var moi := _dau_van_hien_tai()
	if moi != _dau_van:
		_dau_van = moi
		_ve_lai()


## Năm lá bài chung theo ĐÚNG THỨ TỰ CHIA (trái sang phải trên mặt bàn), kèm ngửa hay úp.
##
## Không dùng `CardSpot.cards()` vì hàm đó bỏ qua lá úp — ở đây cần cả năm chỗ, lá chưa lật
## thì vẽ mặt lưng.
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


func _dung_bang() -> void:
	# Gỗ mờ, không đen tuyền: bàn nỉ xanh đậm, bảng tối màu nữa thì bài dán lên nhìn như lơ lửng.
	var go := _mat_tron(Color("8a5a36"))
	var bang := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(board_w, board_h, board_thick)
	bang.mesh = bm
	bang.material_override = go
	bang.position.y = board_h * 0.5 + 0.02
	add_child(bang)
	# Chân đế mỏng: không có thì tấm ván đứng trơ trọi trông như cắm xuyên mặt bàn.
	var de := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(board_w, 0.02, 0.08)
	de.mesh = dm
	de.material_override = go
	de.position.y = 0.01
	add_child(de)


func _ve_lai() -> void:
	for c in _than.get_children():
		c.queue_free()
	var bai := _bai_chung()
	if bai.is_empty():
		return
	var n := bai.size()
	var y := board_h * 0.5 + 0.02
	# Dán CẢ HAI MẶT ván: người đứng xem phía nhà cái cũng đọc được. Mặt sau đảo thứ tự x để
	# nhìn từ phía đó vẫn đọc trái sang phải đúng thứ tự chia.
	for mat_sau in [false, true]:
		for i in n:
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(card_w, card_h)
			q.mesh = qm
			q.material_override = _mat_bai(bai[i]["idx"], bai[i]["up"])
			var dx := (i - (n - 1) * 0.5) * (card_w + card_space)
			# Nhô khỏi mặt ván 2 mm — dán sát thì z-fight với ván.
			var z := board_thick * 0.5 + 0.002
			if mat_sau:
				q.position = Vector3(-dx, y, -z)
				q.rotation.y = PI
			else:
				q.position = Vector3(dx, y, z)
			_than.add_child(q)


func _mat_tron(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.85
	return mat


func _mat_bai(idx: int, up: bool) -> StandardMaterial3D:
	var ten := "card_back" if up else "card_%s" % Card.ten_cua(idx)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(DIR + ten + ".png") as Texture2D
	# Ảnh là pixel art 64×64. Lọc mịn làm nhoè hết chấm — phải để NEAREST.
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
