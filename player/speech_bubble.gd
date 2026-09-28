class_name SpeechBubble
extends Node3D

## Bong bóng chữ trên đầu nhân vật.
##
## Thuần hiển thị, mỗi máy tự vẽ. Tin chat đã tới qua RPC ở `Chat` rồi — bong bóng không gửi
## thêm byte nào, cũng không replicate gì.
##
## Nền lấy MÀU NHÂN VẬT nên nhìn màu là biết ai nói, khỏi phải đọc tên. Chữ tự chọn đen hay
## trắng theo độ sáng của nền (`_ap_mau`): không bao giờ có chuyện chữ chìm vào bóng, kể cả
## khi người chơi chọn màu vàng chói hay nâu sẫm.
##
## CẢ CỤM quay theo camera bằng cách chép thẳng hướng camera vào `global_basis` mỗi khung
## hình. KHÔNG dùng `billboard` của từng vật liệu: mỗi mesh sẽ tự xoay quanh gốc CỦA NÓ, nên
## đuôi nhọn và mấy vòng tròn của kiểu Đám mây văng ra khỏi thân bóng ngay khi người xem đi
## vòng quanh.

enum Kieu { VUONG, TRON, MAY, GAI }

## Tên kiểu cho màn hình chọn nhân vật đọc ra. Thứ tự khớp enum.
const TEN_KIEU := ["Vuông", "Tròn", "Đám mây", "Gai"]

## Hiện đủ bấy nhiêu giây rồi mới mờ đi.
const GIU := 6.0
const MO := 0.5
## Chân bóng (mũi đuôi) nằm ở độ cao này — ngay trên bảng tên (2.05 m).
const CHAN := 2.2
const PIXEL := 0.0034
const CO_CHU := 56
## Vien chu. Day han so voi truoc (10) — chu 3D khong co nen phang phia sau nhu chu 2D,
## vien mong la net chu bi nuot vao mau nen bong.
const VIEN_CHU := 18
## Be day vien toi vien quanh than bong, met. Bong mau tren mot can phong sang trung va
## nhieu chi tiet thi khong co duong vien nay se nhoe vao nen.
const DAY_VIEN := 0.035
## Mau vien quanh bong. Toi han, khong den tuyet doi — den tuyet doi trong tong am cua
## phong nhin nhu mot lo thung.
const MAU_VIEN := Color(0.06, 0.06, 0.09)
## Quá bề ngang này thì xuống dòng. Tính bằng pixel của Label3D, ra khoảng 1.6 m.
const RONG_TOI_DA := 500.0
## Đệm quanh chữ, mét.
const DEM := Vector2(0.15, 0.10)
## Chiều dài đuôi nhọn chỉ xuống đầu nhân vật.
const DUOI := 0.18
## Dưới độ sáng này thì chữ trắng, trên thì chữ đen.
const NGUONG_SANG := 0.5

## Kiểu dáng bóng. Chat đặt theo `Player.bubble_shape` trước mỗi lần gọi `noi()`.
var kieu := Kieu.VUONG
## Màu nền bóng. Chat đặt theo màu nhân vật của người nói.
var mau := Color("e5e5e5")

var _chu: Label3D
var _nen: Node3D
var _vien: Node3D
var _mat: StandardMaterial3D
var _mat_vien: StandardMaterial3D
var _tween: Tween


func _ready() -> void:
	position.y = CHAN

	_mat = StandardMaterial3D.new()
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Lưới dựng bằng ArrayMesh (đuôi, kiểu Gai) không có pháp tuyến — tắt cull thì thứ tự
	# đỉnh thuận hay nghịch đều hiện, khỏi phải canh.
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Vẽ TRƯỚC chữ. Hai lớp trong suốt trùng chỗ nhau mà không xếp thứ tự thì tranh nhau
	# từng điểm ảnh và nhấp nháy.
	_mat.render_priority = -1

	# Vien to hon, mau toi, ve TRUOC — tach ca cum bong khoi nen phong.
	_mat_vien = _mat.duplicate()
	_mat_vien.render_priority = -2
	_vien = Node3D.new()
	_vien.position.z = -0.006
	add_child(_vien)

	_nen = Node3D.new()
	add_child(_nen)

	_chu = Label3D.new()
	# Billboard TẮT — node cha đã quay cả cụm rồi, bật nữa là xoay hai lần.
	_chu.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_chu.pixel_size = PIXEL
	_chu.font_size = CO_CHU
	_chu.outline_size = VIEN_CHU
	_chu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chu.width = RONG_TOI_DA
	_chu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chu.render_priority = 1
	# Bong bong TU tinh mau vien theo do sang cua nen no (`_ap_mau`). Luat vien chu chung
	# (`main.gd::_sua_chu_3d`) se de mau cua no len — va mau do tinh theo DEN PHONG chu khong
	# theo mau bong, nen chu den tren bong vang se mat sach vien trang. Danh dau de nhuong.
	_chu.add_to_group("chu_rieng")
	add_child(_chu)

	visible = false


## Quay cả cụm về phía camera. Chép nguyên hướng camera chứ không `look_at`: `look_at` giữ
## trục Y thẳng đứng nên bóng bị nghiêng khi người xem ngước lên hay cúi xuống.
func _process(_delta: float) -> void:
	if not visible:
		return
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		global_basis = cam.global_basis


func noi(text: String) -> void:
	_chu.text = text
	visible = false
	if _tween != null:
		_tween.kill()

	# Label3D chỉ dựng lại lưới chữ ở khung hình sau khi `text` đổi, nên `get_aabb()` gọi
	# ngay bây giờ trả về cỡ của tin CŨ. Giấu một khung hình còn hơn hiện ra với cái nền
	# ôm sai cỡ rồi giật một cái.
	await get_tree().process_frame
	if not is_instance_valid(self) or _chu.text != text:
		return           # đã có tin mới hơn chen vào trong lúc chờ

	_dung_nen(_chu.get_aabb().size)
	_ap_mau()
	_dat_alpha(1.0)
	visible = true
	_tween = create_tween()
	_tween.tween_interval(GIU)
	_tween.tween_method(_dat_alpha, 1.0, 0.0, MO)
	_tween.tween_callback(hide)


## Chữ đen trên nền sáng, chữ trắng trên nền tối — và viền luôn là màu ngược lại. Hai lớp
## đó cộng lại thì chữ nổi lên khỏi MỌI màu nền người chơi chọn được.
func _ap_mau() -> void:
	var sang := mau.get_luminance() > NGUONG_SANG
	_chu.modulate = Color(0.05, 0.05, 0.07) if sang else Color.WHITE
	_chu.outline_modulate = Color.WHITE if sang else Color(0.04, 0.04, 0.06)
	_mat.albedo_color = mau
	_mat_vien.albedo_color = MAU_VIEN


## Nen DAC (alpha = a, khong nhan 0.93 nua). Ban truoc de 0.93 nen ca can phong loang thoang
## hien qua sau chu — dung thu lam chu 3D kho doc nhat.
func _dat_alpha(a: float) -> void:
	_mat.albedo_color = Color(mau, a)
	_mat_vien.albedo_color = Color(MAU_VIEN, a)
	_chu.modulate.a = a
	_chu.outline_modulate.a = a


## Dựng lại hình nền ôm lấy hộp chữ `kt` (mét). Gốc toạ độ của cụm nằm ở MŨI ĐUÔI, nên thân
## bóng ngồi ở `DUOI + nửa chiều cao` — đuôi luôn chỉ đúng xuống đầu bất kể tin dài mấy dòng.
func _dung_nen(kt: Vector3) -> void:
	for c in _vien.get_children():
		c.queue_free()
	for c in _nen.get_children():
		c.queue_free()
	# Ve HAI LAN: lop vien to hon mot chut o duoi, lop mau dung co o tren.
	_ve_hinh(kt, DAY_VIEN, _mat_vien, _vien)
	_ve_hinh(kt, 0.0, _mat, _nen)


func _ve_hinh(kt: Vector3, no: float, mat: StandardMaterial3D, cha: Node3D) -> void:
	_mat_dang_ve = mat
	_cha_dang_ve = cha

	var w := kt.x + DEM.x * 2.0 + no * 2.0
	var h := kt.y + DEM.y * 2.0 + no * 2.0
	var y := DUOI + (kt.y + DEM.y * 2.0) * 0.5
	_chu.position = Vector3(0.0, y, 0.012)

	match kieu:
		Kieu.TRON:
			# Elip phải to hơn nửa cạnh hộp chữ, nếu không bốn góc chữ nằm ngoài đường tròn.
			_dia(w * 0.62, h * 0.70, Vector3(0.0, y, 0.0))
			_duoi_nhon(y - h * 0.42)
		Kieu.MAY:
			_quad(Vector2(w * 0.86, h * 0.74), Vector3(0.0, y, 0.0))
			var r := h * 0.36
			var n := maxi(3, int(w / (r * 1.4)))
			for i in n:
				var x := -w * 0.43 + w * 0.86 * i / float(n - 1)
				_dia(r, r, Vector3(x, y + h * 0.35, 0.0))
				_dia(r, r, Vector3(x, y - h * 0.35, 0.0))
			_dia(h * 0.32, h * 0.32, Vector3(-w * 0.44, y, 0.0))
			_dia(h * 0.32, h * 0.32, Vector3(w * 0.44, y, 0.0))
			# Đuôi kiểu nghĩ: hai bong tròn nhỏ dần thay cho mũi nhọn.
			_dia(0.055, 0.055, Vector3(0.03, DUOI * 0.7, 0.0))
			_dia(0.032, 0.032, Vector3(-0.01, DUOI * 0.25, 0.0))
		Kieu.GAI:
			_sao(w * 0.74, h * 0.82, Vector3(0.0, y, 0.0))
			_duoi_nhon(y - h * 0.40)
		_:
			_quad(Vector2(w, h), Vector3(0.0, y, 0.0))
			_duoi_nhon(y - h * 0.5)


## Đĩa tròn/elip. Hình trụ dẹt xoay 90° quanh X: mặt tròn quay về phía người xem, bán kính
## X và Y lấy từ `scale` (scale tính TRƯỚC phép xoay trong transform của node).
func _dia(rx: float, ry: float, pos: Vector3) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.004
	cm.radial_segments = 24
	cm.rings = 0
	var m := _them(cm, pos)
	m.rotation.x = PI * 0.5
	m.scale = Vector3(rx, 1.0, ry)


func _quad(co: Vector2, pos: Vector3) -> void:
	var qm := QuadMesh.new()
	qm.size = co
	_them(qm, pos)


## Ngôi sao nhiều cánh — bóng "hét". 7 cánh, chân cánh thụt vào 62%.
func _sao(rx: float, ry: float, pos: Vector3) -> void:
	var canh := 7
	var diem := PackedVector3Array()
	for i in canh * 2:
		var a := TAU * i / float(canh * 2) + PI * 0.5
		var k := 1.0 if i % 2 == 0 else 0.62
		diem.append(Vector3(cos(a) * rx * k, sin(a) * ry * k, 0.0))
	_da_giac(diem, pos)


## Đuôi nhọn: tam giác từ đáy bóng (`tren`) chụm xuống gốc toạ độ, tức đúng đỉnh đầu.
func _duoi_nhon(tren: float) -> void:
	_da_giac(PackedVector3Array([
		Vector3(-0.10, tren, 0.0),
		Vector3(0.07, tren, 0.0),
		Vector3(0.0, 0.0, 0.0),
	]), Vector3.ZERO)


## Đa giác lồi phẳng, dựng bằng quạt tam giác từ trọng tâm. Không có pháp tuyến và không có
## UV — vật liệu đã UNSHADED và CULL_DISABLED nên không cần cái nào.
func _da_giac(diem: PackedVector3Array, pos: Vector3) -> void:
	var tam := Vector3.ZERO
	for p in diem:
		tam += p
	tam /= diem.size()

	var dinh := PackedVector3Array()
	for i in diem.size():
		dinh.append(tam)
		dinh.append(diem[i])
		dinh.append(diem[(i + 1) % diem.size()])

	var mang := []
	mang.resize(Mesh.ARRAY_MAX)
	mang[Mesh.ARRAY_VERTEX] = dinh
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mang)
	_them(am, pos)


## Lop dang ve — `_ve_hinh` dat truoc khi goi, cac ham dung hinh doc lai. Truyen qua bien
## thay vi them tham so cho ca sau ham dung hinh.
var _mat_dang_ve: StandardMaterial3D = null
var _cha_dang_ve: Node3D = null


func _them(luoi: Mesh, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = luoi
	m.material_override = _mat_dang_ve
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = pos
	_cha_dang_ve.add_child(m)
	return m
