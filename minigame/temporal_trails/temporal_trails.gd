extends MiniGame3D

## TEMPORAL TRAILS — tự chạy, A/D để rẽ, sau lưng mọc tường sáng; đâm tường hoặc viền là ra.
## Mỗi máy tự vẽ tường từ vị trí replicate; người đâm tự khai tử theo tường trên máy mình.

## Nhả một đoạn tường mỗi chừng này mét.
## ponytail: mỗi đoạn một Area3D + Mesh; tụt khung thì gộp hình vào MultiMesh.
const BUOC_VET := 0.6

## Tường của chính mình nhả trong chừng này giây gần nhất không giết mình.
const AN_TOAN := 0.4

## Khớp `collision_layer` trong `vet.tscn`.
const LOP_VET := 32

## Bằng bán kính thân người chơi.
const BAN_KINH_DO := 0.4

## Khớp `Bien` trong `san_vet.tscn`.
const BAN_KINH_BIEN := 11.0
const TOC := 6.0

## Đứng yên đầu ván để nhìn hướng sắp chạy.
const CHUAN_BI := 1.2

## Dịch xa hơn chừng này trong một khung là dịch chuyển, không vẽ tường.
const NHAY_XA := 3.0

@export var vet_scene: PackedScene = null

## Vật liệu gốc của tường (nhân bản theo màu nhân vật).
@export var mat_vet: StandardMaterial3D = null

## player_id -> chỗ nhả đoạn tường gần nhất.
var _cho_cuoi: Dictionary = {}
var _do: PhysicsShapeQueryParameters3D = null

## color_index -> vật liệu tường.
var _vat_lieu: Dictionary = {}
var _dang_lai := false

@onready var _pha_chu: Label = $Lop/Pha


func _ready() -> void:
	super()
	ten = "TEMPORAL TRAILS"
	luat = "Tự chạy thẳng · A/D để rẽ · đâm vào tường sáng hay viền sân là ra · trụ lại cuối cùng"
	# Lưới đỡ; ván thường xong khi còn một người.
	giay_van = 90.0


func bat_dau(nguoi_choi: Array, giong: int) -> void:
	super(nguoi_choi, giong)
	var toi := _nguoi(NetManager.local_id())
	if toi == null:
		return
	# Đứng yên lúc chuẩn bị, mặt quay theo vòng xuất phát.
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
	# Chỉ hỏi Area3D (tường).
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
			# Dịch chuyển: vẽ lại từ chỗ mới.
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


## Giữ luật rơi của lớp cha, thêm viền sân và tường.
func _toi_thua() -> bool:
	if super():
		return true
	var p := _nguoi(NetManager.local_id())
	if p == null or _do == null or not _dang_lai:
		return false
	var l := p.global_position - san.global_position
	if Vector2(l.x, l.z).length() > BAN_KINH_BIEN - BAN_KINH_DO:
		return true
	# Quả cầu dò ngang hông.
	_do.transform = Transform3D(Basis.IDENTITY, p.global_position + Vector3.UP * 0.5)
	for cham in san.get_world_3d().direct_space_state.intersect_shape(_do, 16):
		var v := cham["collider"] as Vet
		if v == null:
			continue
		if v.nguoi == NetManager.local_id() and gio() - v.luc < AN_TOAN:
			continue
		return true
	return false


## Có người đâm: nhân vật biến mất (tường ở lại); máy của họ thôi tự chạy.
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


## Mỗi màu nhân vật một vật liệu.
func _vat_lieu_mau(chi_so_mau: int) -> Material:
	if not _vat_lieu.has(chi_so_mau):
		var m := mat_vet.duplicate() as StandardMaterial3D
		var mau := NetManager.color_for(chi_so_mau)
		m.albedo_color = mau
		m.emission = mau
		_vat_lieu[chi_so_mau] = m
	return _vat_lieu[chi_so_mau]
