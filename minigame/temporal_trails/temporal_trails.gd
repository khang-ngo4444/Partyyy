extends MiniGame3D

## TEMPORAL TRAILS — chạy tới đâu để lại tường tới đó. Chạm tường là ra.
##
## Khuôn T3 thứ hai. Đua xe ánh sáng, nhưng tường **tự tan sau 12 giây** — đó là chữ "temporal"
## trong tên trò, và cũng là thứ giữ cho sân không kín đặc sau nửa phút.
##
## ## 0 gói tin
##
## Mỗi máy tự vẽ vệt cho TẤT CẢ người chơi, dựa trên vị trí mà `FusionSharedReplicator` đã gửi
## sẵn. Không ai phải kể cho ai nghe mình vừa đi qua đâu.
##
## Hệ quả phải chấp nhận: hai máy lấy mẫu vị trí ở hai nhịp hơi khác nhau nên bức tường của cùng
## một người có thể lệch nhau vài chục centimet giữa hai màn hình. Không sửa và không cần sửa —
## **người chạm tường tự khai tử, và họ khai theo bức tường trên máy CỦA HỌ**. Nghĩa là thứ họ
## nhìn thấy chính là thứ giết họ. Nếu để master phán thì mới sinh ra cảnh "màn hình tôi còn
## cách tường một mét mà game bảo tôi chết".
##
## ## Vì sao hỏi không gian vật lý thay vì duyệt danh sách vệt
##
## Cuối ván có cỡ 250 đoạn vệt cùng lúc. Gọi `overlaps_body()` lên từng cái là 250 lần mỗi
## khung hình. `intersect_shape()` hỏi đúng MỘT câu cho cả sân và để Godot lo phần chia lưới —
## đó là việc của engine, không phải việc của trò chơi.

## Đi được chừng này mét thì nhả một đoạn vệt.
const BUOC_VET := 1.1
## Chủ vệt được miễn trừ chừng này giây — không thì vừa nhả ra đã tự đâm vào lưng mình.
const AN_TOAN := 1.4
## Lớp va chạm riêng của vệt, khớp `collision_layer` trong `vet.tscn`.
const LOP_VET := 32
## Bán kính quả cầu dò quanh người chơi. Nhân vật rộng 1,3 m; để 0,5 cho rộng tay một chút,
## vì chết oan vì một góc khuất ức chế hơn nhiều so với thoát được trong gang tấc.
const BAN_KINH_DO := 0.5

@export var vet_scene: PackedScene = null
## Vật liệu theo chỉ số màu người chơi, khớp `NetManager.PLAYER_COLORS`.
@export var vat_lieu_nguoi: Array[StandardMaterial3D] = []

## player_id -> chỗ nhả đoạn vệt gần nhất.
var _cho_cuoi: Dictionary = {}
var _do: PhysicsShapeQueryParameters3D = null


func _ready() -> void:
	super()
	ten = "TEMPORAL TRAILS"
	luat = "WASD chạy · vệt sau lưng là tường · chạm tường ai cũng chết"
	giay_van = 60.0


func _dung_san() -> void:
	_cho_cuoi.clear()
	var hinh := SphereShape3D.new()
	hinh.radius = BAN_KINH_DO
	_do = PhysicsShapeQueryParameters3D.new()
	_do.shape = hinh
	_do.collision_mask = LOP_VET
	# Chỉ hỏi Area3D: vệt không có thân rắn, và sàn thì không phải thứ đang tìm.
	_do.collide_with_bodies = false
	_do.collide_with_areas = true


func _luat_moi_nhip() -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		var id := p.player_id()
		if not _song.has(id) or not con_song(id):
			continue
		var cho := p.global_position
		if not _cho_cuoi.has(id):
			_cho_cuoi[id] = cho
			continue
		var tu: Vector3 = _cho_cuoi[id]
		if tu.distance_to(cho) < BUOC_VET:
			continue
		_nha_vet(id, p.color_index, tu, cho)
		_cho_cuoi[id] = cho


## Ghi đè: giữ nguyên luật rơi khỏi sàn của lớp cha, thêm luật chạm tường.
func _toi_thua() -> bool:
	if super():
		return true
	var p := _nguoi(NetManager.local_id())
	if p == null or _do == null:
		return false
	_do.transform = Transform3D(Basis.IDENTITY, p.global_position + Vector3.UP * 0.7)
	for cham in san.get_world_3d().direct_space_state.intersect_shape(_do, 16):
		var v := cham["collider"] as Vet
		if v == null:
			continue
		# Vệt của chính mình chỉ tha trong `AN_TOAN` giây đầu. Quay đầu đâm vào vệt cũ của mình
		# thì vẫn chết — không thì chạy vòng tròn tại chỗ là bất tử.
		if v.nguoi == NetManager.local_id() and gio() - v.luc < AN_TOAN:
			continue
		return true
	return false


func _nha_vet(chu: int, chi_so_mau: int, tu: Vector3, den: Vector3) -> void:
	if san == null or vet_scene == null:
		return
	var v := vet_scene.instantiate() as Vet
	san.add_child(v)
	v.dat(chu, gio(), tu, den, _vat_lieu(chi_so_mau))


func _vat_lieu(chi_so_mau: int) -> StandardMaterial3D:
	if vat_lieu_nguoi.is_empty():
		return null
	return vat_lieu_nguoi[chi_so_mau % vat_lieu_nguoi.size()]
