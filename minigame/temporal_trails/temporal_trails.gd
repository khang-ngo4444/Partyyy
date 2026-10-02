extends MiniGame3D

## TEMPORAL TRAILS — đua xe ánh sáng. Tự chạy thẳng, A/D để rẽ, sau lưng mọc tường sáng; đâm
## vào tường (của ai cũng vậy, kể cả của mình) hay vào viền sân là ra NGAY. Còn một người là xong.
##
## Khuôn T3. Không dừng, không lùi, không nhảy, không đòn — chỉ có rẽ. Tường KHÔNG tan: sân chật
## dần theo thời gian, và đó là toàn bộ độ khó. Không ai phải làm khó thêm.
##
## ## 0 gói tin cho tường
##
## Mỗi máy tự vẽ tường cho TẤT CẢ người chơi, dựa trên vị trí mà `FusionSharedReplicator` đã gửi
## sẵn. Không ai phải kể cho ai nghe mình vừa đi qua đâu.
##
## Hệ quả phải chấp nhận: hai máy lấy mẫu vị trí ở hai nhịp hơi khác nhau nên bức tường của cùng
## một người có thể lệch nhau vài chục centimet giữa hai màn hình. Không sửa và không cần sửa —
## **người đâm tường tự khai tử, và họ khai theo bức tường trên máy CỦA HỌ**. Nghĩa là thứ họ
## nhìn thấy chính là thứ giết họ. Nếu để master phán thì mới sinh ra cảnh "màn hình tôi còn
## cách tường một mét mà game bảo tôi chết".
##
## ## Vì sao hỏi không gian vật lý thay vì duyệt danh sách vệt
##
## Tường sống tới hết ván, cuối ván có cả nghìn đoạn. `intersect_shape()` hỏi đúng MỘT câu cho cả
## sân và để Godot lo phần chia lưới — đó là việc của engine, không phải việc của trò chơi.

## Đi được chừng này mét thì nhả một đoạn tường. Ngắn thì chỗ rẽ tròn hơn, đổi lại nhiều node hơn.
##
## ponytail: mỗi đoạn một Area3D + một MeshInstance3D; 4 người × 6 m/s × 60 s ÷ 0,6 m ≈ 2400 đoạn
## lúc dài nhất. Nếu đo thấy tụt khung hình thì gộp hình vào một MultiMesh mỗi người và giữ Area3D
## riêng cho va chạm.
const BUOC_VET := 0.6
## Đoạn tường CỦA CHÍNH MÌNH nhả trong chừng này giây gần nhất không giết mình — đoạn mới nhất
## luôn bắt đầu ngay dưới chân. 0,4 s = 2,4 m; vòng rẽ gắt nhất có bán kính 2,3 m nên không thể
## quay đầu đâm vào phần tường trong quãng đó, và đâm vào phần cũ hơn thì vẫn chết.
const AN_TOAN := 0.4
## Lớp va chạm riêng của tường, khớp `collision_layer` trong `vet.tscn`.
const LOP_VET := 32
## Bán kính quả cầu dò quanh người chơi — đúng bằng bán kính thân (`player.tscn`, 0,4 m), nên
## "thân chạm tường" trên màn hình là "chết" trong luật.
const BAN_KINH_DO := 0.4
## Bán kính VIỀN sân (`Bien` trong `san_vet.tscn`). Thân chạm viền là chết.
const BAN_KINH_BIEN := 11.0
## Tốc độ chạy, m/s — bằng tốc đi bộ thường, không chỉnh nhanh hơn để làm khó.
const TOC := 6.0
## Giây đứng yên đầu ván để mọi người nhìn hướng mình sắp chạy.
const CHUAN_BI := 1.2
## Một lần dịch vị trí xa hơn chừng này trong một khung hình là DỊCH CHUYỂN (vào sân, về chỗ cũ),
## không phải chạy — không vẽ tường cho quãng đó.
const NHAY_XA := 3.0

@export var vet_scene: PackedScene = null

@onready var _pha_chu: Label = $Lop/Pha

## player_id -> chỗ nhả đoạn tường gần nhất.
var _cho_cuoi: Dictionary = {}
var _do: PhysicsShapeQueryParameters3D = null
## color_index -> vật liệu tường của màu đó. Mỗi màu MỘT bản, dùng chung cho mọi đoạn.
var _vat_lieu: Dictionary = {}
var _dang_lai := false


func _ready() -> void:
	super()
	ten = "TEMPORAL TRAILS"
	luat = "Tự chạy thẳng · A/D để rẽ · đâm vào tường sáng hay viền sân là ra · trụ lại cuối cùng"
	# Lưới đỡ: thường thì ván xong khi còn một người, rất lâu trước mốc này.
	giay_van = 90.0


func bat_dau(nguoi_choi: Array, giong: int) -> void:
	super(nguoi_choi, giong)
	var toi := _nguoi(NetManager.local_id())
	if toi == null:
		return
	# Đứng yên trong lúc chuẩn bị, mặt quay theo VÒNG xuất phát (cùng chiều cho mọi người): không
	# ai chĩa thẳng mặt vào ai ngay giây đầu.
	toi.khoa_di_chuyen = true
	var l := toi.global_position - san.global_position
	var tiep := Vector3(-l.z, 0.0, l.x).normalized()
	if tiep.length_squared() > 0.0:
		toi.rotation.y = atan2(-tiep.x, -tiep.z)


func _dung_san() -> void:
	_cho_cuoi.clear()
	_vat_lieu.clear()
	_dang_lai = false
	var hinh := SphereShape3D.new()
	hinh.radius = BAN_KINH_DO
	_do = PhysicsShapeQueryParameters3D.new()
	_do.shape = hinh
	_do.collision_mask = LOP_VET
	# Chỉ hỏi Area3D: tường không có thân rắn, và sàn thì không phải thứ đang tìm.
	_do.collide_with_bodies = false
	_do.collide_with_areas = true
	$Lop.visible = true


func dung_som() -> void:
	var toi := _nguoi(NetManager.local_id())
	if toi != null:
		toi.lai_tu_dong = false
	for p: Player in get_tree().get_nodes_in_group("players"):
		p.model_root.visible = true
	$Lop.visible = false
	super()


func _luat_moi_nhip() -> void:
	if not _dang_lai and gio() >= CHUAN_BI:
		_dang_lai = true
		var toi := _nguoi(NetManager.local_id())
		if toi != null and con_song(NetManager.local_id()):
			toi.khoa_di_chuyen = false
			toi.toc_lai = TOC
			toi.lai_tu_dong = true
	for p: Player in get_tree().get_nodes_in_group("players"):
		var id := p.player_id()
		if not _song.has(id) or not con_song(id):
			continue
		var cho := p.global_position
		if not _dang_lai or not _cho_cuoi.has(id):
			_cho_cuoi[id] = cho
			continue
		var tu: Vector3 = _cho_cuoi[id]
		var d := tu.distance_to(cho)
		if d > NHAY_XA:
			# Dịch chuyển (thường là vị trí replicate của người khác vừa nhảy vào sân): bắt đầu
			# vẽ lại từ chỗ mới, không kéo một bức tường dài từ chỗ cũ tới đây.
			_cho_cuoi[id] = cho
			continue
		if d < BUOC_VET:
			continue
		_nha_vet(id, p.color_index, tu, cho)
		_cho_cuoi[id] = cho
	_pha_chu.text = _chu_trang_thai()


func _chu_trang_thai() -> String:
	if not _dang_lai:
		return "SẴN SÀNG..."
	if not con_song(NetManager.local_id()):
		return "BẠN ĐÃ ĐÂM VÀO TƯỜNG · còn %d người" % so_con_song()
	return "Còn %d người" % so_con_song()


## Ghi đè: giữ nguyên luật rơi khỏi sàn của lớp cha, thêm viền sân và tường.
func _toi_thua() -> bool:
	if super():
		return true
	var p := _nguoi(NetManager.local_id())
	if p == null or _do == null or not _dang_lai:
		return false
	var l := p.global_position - san.global_position
	if Vector2(l.x, l.z).length() > BAN_KINH_BIEN - BAN_KINH_DO:
		return true
	# Tâm quả cầu ngang hông, giữa bề cao tường (0..1 m). Chế độ lái không có nhảy, nên không ai
	# bay qua tường được.
	_do.transform = Transform3D(Basis.IDENTITY, p.global_position + Vector3.UP * 0.5)
	for cham in san.get_world_3d().direct_space_state.intersect_shape(_do, 16):
		var v := cham["collider"] as Vet
		if v == null:
			continue
		if v.nguoi == NetManager.local_id() and gio() - v.luc < AN_TOAN:
			continue
		return true
	return false


## Có người vừa đâm. Trên MỌI máy: nhân vật biến mất (tường của họ vẫn ở lại — đó là chướng ngại
## cho người còn sống). Máy của chính người đó: đứng im, thôi tự chạy.
func _khi_ai_do_chet(id: int) -> void:
	var p := _nguoi(id)
	if p == null:
		return
	p.model_root.visible = false
	if id == NetManager.local_id():
		p.lai_tu_dong = false
		p.khoa_di_chuyen = true


func _nha_vet(chu: int, chi_so_mau: int, tu: Vector3, den: Vector3) -> void:
	if san == null or vet_scene == null:
		return
	var v := vet_scene.instantiate() as Vet
	san.get_node("Vet").add_child(v)
	v.dat(chu, gio(), tu, den, _vat_lieu_mau(chi_so_mau))


## Tường mang MÀU NHÂN VẬT (`NetManager.PLAYER_COLORS`). Nhân bản `mat_vet_loi` một lần mỗi màu.
func _vat_lieu_mau(chi_so_mau: int) -> Material:
	if not _vat_lieu.has(chi_so_mau):
		var goc := load("res://materials/mat_vet_loi.tres") as StandardMaterial3D
		var m := goc.duplicate() as StandardMaterial3D
		var mau := NetManager.color_for(chi_so_mau)
		m.albedo_color = mau
		m.emission = mau
		_vat_lieu[chi_so_mau] = m
	return _vat_lieu[chi_so_mau]
