class_name Lobby
extends Node3D

## Map phòng chờ "The Palm House": nhà kính tròn, tháp đồng hồ ở giữa, 4 khu trò chơi, tàu lượn.
## Không chứa logic mạng, không biết ai đang chơi.
##
## Số đo lấy từ "The Palm House - Technical Design Document" (sheet A-201).
## Khung nhà (sàn, tường, vòm, tháp) và đồ trang trí đặt sẵn trong .tscn. File này chỉ dựng
## những thứ LẶP LẠI mà đặt tay thì vô nghĩa: tường va chạm, sườn vòm, song kính, mặt đồng hồ,
## số giờ trên sàn — và đổi màu cây/ghế của kit Kenney sang bảng màu của tài liệu.

## Bán kính sàn. Đổi số này thì đổi luôn bán kính sàn/tường/vòm trong .tscn.
const ROOM_RADIUS := 18.0
## Tường vô hình. Sàn là một cái đĩa — không có cái này thì người chơi đi ra mép rồi rơi mãi.
const WALL_SEGMENTS := 48
const WALL_HEIGHT := 14.0
## Vòm: bắt đầu ở đỉnh tường, cao thêm DOME_RISE.
const DOME_RISE := 8.0
const RIBS := 24
const RIB_SEGMENTS := 10
## Tâm mặt đồng hồ (nửa cạnh thân tháp 1.4 m + chút lồi ra).
const DIAL_Y := 9.6
const DIAL_OUT := 1.43
const NUMERALS := ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
const HOUR_RING_R := 4.8

const MAT_BRASS := preload("res://materials/mat_brass.tres")
const MAT_BRASS_DARK := preload("res://materials/mat_brass_dark.tres")
## Kit Kenney đặt tên vật liệu theo loại -> vật liệu của tài liệu. Cây dùng màu theo tầng (tên node).
const MAT_LEAF := {
	"Palm": preload("res://materials/mat_leaf_palm.tres"),
	"Fern": preload("res://materials/mat_leaf_fern.tres"),
	"Ground": preload("res://materials/mat_leaf_deep.tres"),
}
const LEAF_NAMES := ["leafsGreen", "grass", "plant"]
const CANE_NAMES := ["carpet", "wood", "woodDark"]
const MAT_CANE := preload("res://materials/mat_cane.tres")

## Xa hon chung nay met thi chu 3D tu mo di.
const TAM_CHU := 6.0

## Cac mau den cho nut DOI MAU DEN. Muc 0 la MAU GOC — bam ve 0 tra lai nguyen trang moi
## nguon sang, ke ca hai sac am khac nhau da dat san trong .tscn.
const MAU_DEN: Array[Color] = [
	Color("ffc46b"), Color("ffffff"), Color("ff5fa2"),
	Color("4d8cff"), Color("46d97a"), Color("a56bff"),
]

## Pha bao nhieu phan mau moi vao tung nguon. KHONG nhuom 100%: mat troi trang tinh thanh
## mat troi tim dac thi mat het khoi va bong do, ca phong bet lai thanh mot mang phang.
##
## Do lai ngan sach anh sang cua phong tu lobby.tscn — day moi la thu THAT SU chieu sang:
##
##   Sun (DirectionalLight3D)     nang luong 1.3      anh sang chinh, do bong
##   Environment ambient          nang luong 0.45     60% lay tu BAU TROI
##   ProceduralSkyMaterial                            nuoi ca ambient lan nen nhin thay
##   fog_light_color              mat do 0.006        man suong phu khap phong
##   18 den AccentLights          tam 6-9 m           chi la vung sang nho quanh tung khu
##
## Ban dau chi nhuom 18 den AccentLights. Chung la nhung vung ban kinh 6-9 m trong mot can
## phong duong kinh 36 m dang bi mat troi va ambient roi day — doi mau chung xong khong ai
## nhin ra khac gi. Muon thay mau doi thi phai dong vao bon nguon tren.
const PHA_MAT_TROI := 0.55
const PHA_AMBIENT := 0.75
const PHA_BAU_TROI := 0.5
const PHA_SUONG := 0.6

## Cho ngoi tren sofa, trong he toa do cua sofa. Doi model sofa thi chinh hai so nay.
const CHO_NGOI_X := 0.52
const CHO_NGOI_Z := 0.62

@onready var spawn_points: Node3D = $SpawnPoints
@onready var sun: DirectionalLight3D = $Sun

var _hands: Array[Node3D] = []   # [gio, phut] x 4 mat
## Mau goc cua tung ngon den trong AccentLights, chup luc khoi dong. Khong chup thi bam sang
## mau khac roi bam ve "Am" la mat sach su khac nhau giua den bar va den ban — ca phong
## phang li mot mau.
var _mau_den_goc: Dictionary = {}
## Mau anh sang hien tai, goi 0xRRGGBB. -1 = mau goc cua map.
var _mau_sang := -1
var _mau_sang_b := -1
## Mau goc cua bon nguon sang chung.
var _goc_mat_troi := Color.WHITE
var _goc_ambient := Color.WHITE
var _goc_troi_dinh := Color.WHITE
var _goc_troi_chan := Color.WHITE
var _goc_suong := Color.WHITE
var _moi_truong: Environment = null
var _chat_troi: ProceduralSkyMaterial = null


func _ready() -> void:
	_build_walls()
	_gioi_han_tam_chu()
	_build_ribs_and_mullions()
	_nho_mau_den()
	_dung_ghe_sofa()
	$ClockTower/Loa.add_to_group("loa_nhac")
	_build_clocks()
	_build_hour_numerals()
	_retint_decor()
	# Mặt trời trôi rất chậm để bóng sườn vòm quét qua sàn trong lúc chơi. Chỉ là hình, mỗi máy tự chạy.
	var t := create_tween().set_loops()
	t.tween_property(sun, "rotation_degrees:y", 152.0, 900.0).from(128.0)
	t.tween_property(sun, "rotation_degrees:y", 128.0, 900.0)


func _process(_delta: float) -> void:
	var now := Time.get_time_dict_from_system()
	var minute: float = now.minute + now.second / 60.0
	var hour := fmod(now.hour, 12.0) + minute / 60.0
	for i in range(0, _hands.size(), 2):
		# Nhìn từ trước mặt (+Z), quay dương là ngược kim — nên đổi dấu.
		_hands[i].rotation.z = -TAU * hour / 12.0
		_hands[i + 1].rotation.z = -TAU * minute / 60.0


## Chup mau goc cua moi nguon sang truoc khi ai kip doi.
##
## `duplicate(true)` la BAT BUOC. Environment va Sky la sub-resource cua lobby.tscn, tuc la
## DUNG CHUNG: sua thang vao chung thi mau da nhuom con nguyen sau khi roi phong, va lan vao
## phong sau se chup "mau goc" tu cai da bi nhuom. Lam ban sao rieng thi moi lan vao phong
## deu bat dau tu dung so trong .tscn.
## Moi sofa trong `Decor` duoc hai cho ngoi.
##
## Sinh bang CODE chu khong dat tay 14 node vao .tscn: dat tay thi moi lan nguoi dung keo mot
## cai sofa di la phai nho keo theo hai cai ghe. Lam o day thi ghe bam theo sofa — cung cach
## `CardTable` dang sinh ghe cho ban bai.
##
## Node ghe dat TRUOC mep sofa (xem `GheNgoi.lech_ngoi` giai thich vi sao), quay cung huong +Z
## voi sofa. Sofa Kenney rong 2.16 m sau khi nhan ti le 2.2, nen hai cho cach nhau 1.04 m.
func _dung_ghe_sofa() -> void:
	for sofa: Node3D in $Decor.get_children():
		if not sofa.name.begins_with("Sofa"):
			continue
		for x in [-CHO_NGOI_X, CHO_NGOI_X]:
			var g := GheNgoi.new()
			g.name = "%s_Cho%s" % [sofa.name, "Trai" if x < 0.0 else "Phai"]
			# Vung ngam thap va det hon ghe bai: no nam ngay truoc mep sofa, cao qua thi
			# nguoi dung sau sofa cung ngam trung.
			g.hop_ngam = Vector3(0.9, 0.9, 0.5)
			g.hop_ngam_y = 0.55
			sofa.add_child(g)
			g.position = Vector3(x, 0.0, CHO_NGOI_Z)


func _nho_mau_den() -> void:
	for d: Light3D in $AccentLights.find_children("*", "Light3D", true, false):
		_mau_den_goc[d] = d.light_color

	var we := $WorldEnvironment as WorldEnvironment
	_moi_truong = we.environment.duplicate(true)
	we.environment = _moi_truong
	_chat_troi = _moi_truong.sky.sky_material as ProceduralSkyMaterial

	_goc_mat_troi = sun.light_color
	_goc_ambient = _moi_truong.ambient_light_color
	_goc_suong = _moi_truong.fog_light_color
	if _chat_troi != null:
		_goc_troi_dinh = _chat_troi.sky_top_color
		_goc_troi_chan = _chat_troi.sky_horizon_color


## Nhuom ca phong bang MOT mau tuyet doi (0xRRGGBB), hoac -1 de tra moi nguon ve mau goc.
##
## 18 den trang tri an mau DAC (chung la do trang tri, nhin thang vao bong den phai thay mau);
## bon nguon chung thi chi PHA vao theo ti le o tren, de con khoi va bong do.
## `Color.hex` doc theo thu tu RGBA chu KHONG phai ARGB. Goi thanh 0xAARRGGBB thi mau ra
## lech mot kenh va alpha an nham chu so xanh — da do duoc: hong #ff5fa2 ra vang, alpha 0.80.
## Dung la `(rgb << 8) | 0xFF`, tuc 0xRRGGBBFF.
static func _mau_tu_so(rgb: int) -> Color:
	return Color.hex((rgb << 8) | 0xFF)


## Nhuom phong bang MOT hoac HAI mau.
##
## `rgb_b < 0` thi chi mot mau, ca phong mot sac.
##
## Hai mau thi thanh GRADIENT THAT trong khong gian, khong phai tron san ra mot mau thu ba:
##   - 18 den trang tri: mau theo VI TRI tung ngon doc truc X cua phong. Den ben trai an mau A,
##     ben phai an mau B, o giua pha dan — di tu dau nay sang dau kia thay mau troi dan.
##   - Bau troi: dinh mau A, chan troi mau B. ProceduralSkyMaterial von da noi hai mau nay
##     thanh dai chuyen, nen day la gradient san co cua engine, khong ton dong code nao.
##   - Mat troi, ambient, suong: lay diem giua. Chung phu deu ca phong nen khong the gradient;
##     lay mot dau la ca phong nga han ve mau do.
func dat_mau_sang(rgb: int, rgb_b: int = -1) -> void:
	_mau_sang = rgb
	_mau_sang_b = rgb_b
	var goc := rgb < 0
	var mau_a := Color.WHITE if goc else _mau_tu_so(rgb)
	var mau_b := mau_a if rgb_b < 0 else _mau_tu_so(rgb_b)
	var giua := mau_a.lerp(mau_b, 0.5)

	for d: Light3D in _mau_den_goc:
		if not is_instance_valid(d):
			continue
		if goc:
			d.light_color = _mau_den_goc[d]
			continue
		var t := clampf((d.global_position.x + ROOM_RADIUS) / (ROOM_RADIUS * 2.0), 0.0, 1.0)
		d.light_color = mau_a.lerp(mau_b, t)

	sun.light_color = _goc_mat_troi if goc else _goc_mat_troi.lerp(giua, PHA_MAT_TROI)
	if _moi_truong == null:
		return
	_moi_truong.ambient_light_color = (_goc_ambient if goc
			else _goc_ambient.lerp(giua, PHA_AMBIENT))
	_moi_truong.fog_light_color = _goc_suong if goc else _goc_suong.lerp(giua, PHA_SUONG)
	if _chat_troi != null:
		_chat_troi.sky_top_color = (_goc_troi_dinh if goc
				else _goc_troi_dinh.lerp(mau_a, PHA_BAU_TROI))
		_chat_troi.sky_horizon_color = (_goc_troi_chan if goc
				else _goc_troi_chan.lerp(mau_b, PHA_BAU_TROI))


func mau_sang() -> int:
	return _mau_sang


func mau_sang_b() -> int:
	return _mau_sang_b


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


## Vị trí spawn theo chỉ số. Chia đều quanh lối đi vòng quanh tháp nên nhiều người không chồng nhau.
func spawn_transform(index: int) -> Transform3D:
	var pts := spawn_points.get_children()
	if pts.is_empty():
		return Transform3D.IDENTITY
	return (pts[index % pts.size()] as Node3D).global_transform


## Vành tường vô hình: KHÔNG có mesh. Tường kính trong .tscn đã lo phần nhìn rồi, ở đây chỉ
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


## 24 sườn vòm bằng đồng (chúng đổ bóng dài xuống sàn — tài liệu dặn không được bỏ) và 48 song
## kính đứng ở mép mỗi tấm tường. Hai MultiMesh, hai draw call.
func _build_ribs_and_mullions() -> void:
	var rib_xf: Array[Transform3D] = []
	for k in RIBS:
		var dir := Vector3(sin(TAU * k / RIBS), 0.0, cos(TAU * k / RIBS))
		var side := dir.cross(Vector3.UP)
		for s in RIB_SEGMENTS:
			var a := _dome_point(dir, PI * 0.5 * s / RIB_SEGMENTS)
			var b := _dome_point(dir, PI * 0.5 * (s + 1) / RIB_SEGMENTS)
			var up := b - a
			var fwd := side.cross(up.normalized())
			rib_xf.append(Transform3D(Basis(side, up, fwd), (a + b) * 0.5))
	var rib := CylinderMesh.new()
	rib.top_radius = 0.1
	rib.bottom_radius = 0.1
	rib.height = 1.0
	rib.radial_segments = 6
	_multimesh("DomeRibs", rib, rib_xf)

	var mull_xf: Array[Transform3D] = []
	for i in WALL_SEGMENTS:
		var a := TAU * (i + 0.5) / WALL_SEGMENTS
		mull_xf.append(Transform3D(Basis(Vector3.UP, a),
				Vector3(sin(a), 0.0, cos(a)) * (ROOM_RADIUS - 0.08) + Vector3.UP * 8.2))
	var mull := BoxMesh.new()
	mull.size = Vector3(0.12, 11.6, 0.12)
	_multimesh("Mullions", mull, mull_xf)


func _dome_point(dir: Vector3, t: float) -> Vector3:
	return dir * ROOM_RADIUS * cos(t) + Vector3.UP * (WALL_HEIGHT + DOME_RISE * sin(t))


func _multimesh(node_name: String, mesh: Mesh, xfs: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = MAT_BRASS
	add_child(mmi)


## Bốn mặt đồng hồ 2.2 m, kim chạy theo giờ máy.
func _build_clocks() -> void:
	var face := CylinderMesh.new()
	face.top_radius = 1.1
	face.bottom_radius = 1.1
	face.height = 0.06
	var enamel := StandardMaterial3D.new()
	enamel.albedo_color = Color("f4efe2")
	enamel.emission_enabled = true
	enamel.emission = Color("f4efe2")
	enamel.emission_energy_multiplier = 0.35
	for i in 4:
		var a := TAU * i / 4.0
		var dial := Node3D.new()
		dial.name = "Dial%d" % i
		dial.position = Vector3(sin(a) * DIAL_OUT, DIAL_Y, cos(a) * DIAL_OUT)
		dial.rotation.y = a
		$ClockTower.add_child(dial)
		var disc := MeshInstance3D.new()
		disc.mesh = face
		disc.rotation.x = PI * 0.5
		disc.material_override = enamel
		dial.add_child(disc)
		for h in [[0.55, 0.09], [0.9, 0.05]]:   # [dai, rong] kim gio, kim phut
			var pivot := Node3D.new()
			pivot.position.z = 0.05 + h[1]
			dial.add_child(pivot)
			var hand := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(h[1], h[0], 0.03)
			hand.mesh = bm
			hand.position.y = h[0] * 0.5 - 0.08
			hand.material_override = MAT_BRASS_DARK
			pivot.add_child(hand)
			_hands.append(pivot)


## 12 số La Mã bằng đồng khảm trên sàn, mỗi 30°. Đầu chữ quay vào tháp: đọc được khi đứng ngoài nhìn vào.
func _build_hour_numerals() -> void:
	for k in 12:
		var a := TAU * k / 12.0
		var chu := Label3D.new()
		chu.text = NUMERALS[k]
		chu.font_size = 64
		chu.pixel_size = 0.55 / 64.0
		chu.modulate = Color("b68235")
		chu.outline_size = 0
		chu.position = Vector3(sin(a) * HOUR_RING_R, 0.015, -cos(a) * HOUR_RING_R)
		chu.rotation = Vector3(-PI * 0.5, PI - a, 0.0)
		chu.visibility_range_end = 40.0   # khong de _gioi_han_tam_chu an mat
		add_child(chu)


## Kit Kenney có màu riêng; đổi lá sang 3 tông xanh của tài liệu, ghế/sofa sang mây (cane).
## Theo TÊN vật liệu nên thân cây (woodBark) giữ nguyên màu.
func _retint_decor() -> void:
	for item: Node in $Decor.get_children():
		var leaf: Material = null
		for prefix: String in MAT_LEAF:
			if item.name.begins_with(prefix):
				leaf = MAT_LEAF[prefix]
		var cane := item.name.begins_with("Sofa") or item.name.begins_with("Table")
		for mi: MeshInstance3D in item.find_children("*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(s)
				var mname := mat.resource_name if mat != null else ""
				if leaf != null and mname in LEAF_NAMES:
					mi.set_surface_override_material(s, leaf)
				elif cane and mname in CANE_NAMES:
					mi.set_surface_override_material(s, MAT_CANE)
