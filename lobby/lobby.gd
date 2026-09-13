extends Node3D

## Map phòng chờ: sàn, ánh sáng, tường, điểm spawn.
## Không chứa logic mạng, không biết ai đang chơi.
##
## KHÔNG CÓ ĐỒ TRANG TRÍ. Trước đây phòng có 35 món đồ từ các kit Kenney, nhưng không món
## nào bấm vào được — chúng chỉ là mesh có hộp va chạm. Một cái máy game thùng đứng đó mà
## không chơi được thì tệ hơn là không có gì: người chơi đi tới, bấm E, không có gì xảy ra.
##
## Quy tắc từ đây: món nào vào phòng thì món đó phải LÀM ĐƯỢC VIỆC GÌ ĐÓ.
## Hiện có: ô sẵn sàng, bàn cờ vua/tướng, bàn caro, đường đua gà — đều đặt sẵn trong .tscn.

## Bán kính sàn. Đổi số này thì đổi luôn `Pickable.ROOM_RADIUS` và bán kính vòm trong .tscn.
const ROOM_RADIUS := 18.0
## Tường vô hình. Sàn là một cái đĩa — không có cái này thì người chơi đi ra mép rồi rơi mãi.
const WALL_SEGMENTS := 48
const WALL_HEIGHT := 8.0

@onready var spawn_points: Node3D = $SpawnPoints


## Xa hon chung nay met thi chu 3D tu mo di.
const TAM_CHU := 6.0


func _ready() -> void:
	_build_walls()
	_gioi_han_tam_chu()


## Moi bang diem, nhan ghe va chu tren nut deu la Label3D billboard — dung o giua phong thi
## chu cua ca muoi khu vuc de chong len nhau, doc khong ra cai nao.
##
## Dung `visibility_range_end` co san cua GeometryInstance3D (Label3D thua ke), KHONG dung
## `visible`: game con tu bat/tat `visible` cua dong ho dem nguoc, hai ben se danh nhau.
##
## `_ready()` cua lobby chay SAU `_ready()` cua con, nen cho nay thay du chu da dung xong.
func _gioi_han_tam_chu() -> void:
	for chu: Label3D in find_children("*", "Label3D", true, false):
		if chu.visibility_range_end > 0.0:
			continue      # cho nao tu dat tam rieng thi de yen
		chu.visibility_range_end = TAM_CHU
		chu.visibility_range_end_margin = 2.0
		chu.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


## Vị trí spawn theo chỉ số. Chia đều quanh vòng tròn nên nhiều người không chồng nhau.
func spawn_transform(index: int) -> Transform3D:
	var pts := spawn_points.get_children()
	if pts.is_empty():
		return Transform3D.IDENTITY
	return (pts[index % pts.size()] as Node3D).global_transform


## Vành tường vô hình: KHÔNG có mesh. Cái vòm trong suốt đã lo phần nhìn rồi, ở đây chỉ
## cần chặn chân. Một CylinderShape3D thì ĐẶC — nó đẩy người chơi ra ngoài chứ không giữ
## lại; nên phải ghép từ các hộp phẳng theo vòng tròn.
func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "Walls"
	var seg_width := TAU * ROOM_RADIUS / WALL_SEGMENTS
	for i in WALL_SEGMENTS:
		var a := TAU * i / float(WALL_SEGMENTS)
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		# Rộng hơn một chút để hai tấm cạnh nhau chồng mép, không hở khe.
		bs.size = Vector3(seg_width * 1.15, WALL_HEIGHT, 0.5)
		shape.shape = bs
		shape.position = Vector3(sin(a) * ROOM_RADIUS, WALL_HEIGHT * 0.5, cos(a) * ROOM_RADIUS)
		shape.rotation.y = a
		body.add_child(shape)
	add_child(body)
