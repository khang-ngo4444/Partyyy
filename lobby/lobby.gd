class_name Lobby
extends Node3D

## Map phòng chờ "The Palm House": nhà kính tròn, tháp đồng hồ giữa, 4 khu trò chơi.
## Mọi thứ đặt sẵn trong .tscn (khung_nha, dong_ho, canopy_line); script lo ánh sáng,
## chất lượng đồ hoạ và đổi màu kit Kenney. Không có logic mạng.

## Bán kính sàn. Đổi số này thì đổi luôn bán kính sàn/tường/vòm trong .tscn.
const ROOM_RADIUS := 18.0

## Tên vật liệu kit Kenney được thay (lá; ghế/sofa).
const LEAF_NAMES := ["leafsGreen", "grass", "plant"]
const CANE_NAMES := ["carpet", "wood", "woodDark"]

## Xa hơn chừng này mét thì chữ 3D tự mờ.
const TAM_CHU := 6.0
const LIGHT_FADE_BEGIN := 22.0
const LIGHT_FADE_LENGTH := 6.0
const LIGHT_SHADOW_CUTOFF := 14.0
const GRAPHICS_PERFORMANCE := 1
const GRAPHICS_QUALITY := 3

## Màu đèn cho nút đổi màu; mục 0 = màu gốc.
const MAU_DEN: Array[Color] = [
	Color("ffc46b"), Color("ffffff"), Color("ff5fa2"),
	Color("4d8cff"), Color("46d97a"), Color("a56bff"),
]

## Tỉ lệ pha màu mới vào từng nguồn sáng chung; không nhuộm 100% để giữ khối và bóng.
const PHA_MAT_TROI := 0.55
const PHA_AMBIENT := 0.75
const PHA_BAU_TROI := 0.5
const PHA_SUONG := 0.6

## Vật liệu thay cho kit Kenney: lá theo tầng (tiền tố tên node trong `Decor`), mây cho ghế.
@export var mat_la_palm: Material
@export var mat_la_fern: Material
@export var mat_la_ground: Material
@export var mat_may: Material

## Màu gốc từng đèn AccentLights, chụp lúc khởi động để trả về được.
var _mau_den_goc: Dictionary = {}

## Màu ánh sáng hiện tại (0xRRGGBB); -1 = màu gốc.
var _mau_sang := -1
var _mau_sang_b := -1

## Màu gốc của bốn nguồn sáng chung.
var _goc_mat_troi := Color.WHITE
var _goc_ambient := Color.WHITE
var _goc_troi_dinh := Color.WHITE
var _goc_troi_chan := Color.WHITE
var _goc_suong := Color.WHITE
var _moi_truong: Environment = null
var _chat_troi: ProceduralSkyMaterial = null
var _den_do_bong: Array[Light3D] = []

@onready var spawn_points: Node3D = $SpawnPoints
@onready var sun: DirectionalLight3D = $Sun


func _ready() -> void:
	_gioi_han_tam_chu()
	_nho_mau_den()
	var performance_manager := get_node("/root/PerformanceManager")
	performance_manager.connect("graphics_mode_changed", _apply_graphics_quality)
	_apply_graphics_quality(int(performance_manager.get("graphics_mode")))
	$ClockTower/Loa.add_to_group("loa_nhac")
	_retint_decor()
	# Mặt trời trôi chậm để bóng sườn vòm quét qua sàn; mỗi máy tự chạy.
	var t := create_tween().set_loops()
	t.tween_property(sun, "rotation_degrees:y", 152.0, 900.0).from(128.0)
	t.tween_property(sun, "rotation_degrees:y", 128.0, 900.0)


## Chụp màu gốc mọi nguồn sáng trước khi ai kịp đổi.
func _nho_mau_den() -> void:
	for d: Light3D in $AccentLights.find_children("*", "Light3D", true, false):
		_mau_den_goc[d] = d.light_color
		if d.shadow_enabled:
			_den_do_bong.append(d)

	var we := $WorldEnvironment as WorldEnvironment
	# Bản sao riêng: Environment/Sky là sub-resource dùng chung giữa các lần vào phòng.
	_moi_truong = we.environment.duplicate(true)
	we.environment = _moi_truong
	_chat_troi = _moi_truong.sky.sky_material as ProceduralSkyMaterial

	_goc_mat_troi = sun.light_color
	_goc_ambient = _moi_truong.ambient_light_color
	_goc_suong = _moi_truong.fog_light_color
	if _chat_troi != null:
		_goc_troi_dinh = _chat_troi.sky_top_color
		_goc_troi_chan = _chat_troi.sky_horizon_color


## Bỏ bớt bóng, đèn xa và hậu kỳ theo preset; Chất lượng giữ nguyên hình gốc.
func _apply_graphics_quality(mode: int) -> void:
	var quality := mode == GRAPHICS_QUALITY
	var performance := mode == GRAPHICS_PERFORMANCE
	_moi_truong.ssao_enabled = quality
	_moi_truong.glow_enabled = not performance
	sun.directional_shadow_max_distance = 60.0 if quality else 36.0
	for d: Light3D in $AccentLights.find_children("*", "Light3D", true, false):
		d.distance_fade_enabled = not quality
		d.distance_fade_begin = LIGHT_FADE_BEGIN
		d.distance_fade_length = LIGHT_FADE_LENGTH
		d.distance_fade_shadow = LIGHT_SHADOW_CUTOFF
	for d in _den_do_bong:
		d.shadow_enabled = quality


## 0xRRGGBB → Color. ⚠️ `Color.hex` đọc RGBA, không phải ARGB.
static func _mau_tu_so(rgb: int) -> Color:
	return Color.hex((rgb << 8) | 0xFF)


## Nhuộm phòng bằng một hoặc hai màu (`rgb_b < 0` = một màu), -1 = trả về màu gốc.
## Hai màu: đèn trang trí chuyển dần theo trục X, trời đỉnh A chân B,
## mặt trời/ambient/sương lấy điểm giữa.
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


## Label3D tự mờ khi xa (`visibility_range_end`) để chữ các khu không chồng nhau.
## Không dùng `visible` vì game còn bật/tắt nó.
func _gioi_han_tam_chu() -> void:
	for chu: Label3D in find_children("*", "Label3D", true, false):
		if chu.visibility_range_end > 0.0:
			continue  # chỗ nào tự đặt tầm riêng thì để yên
		chu.visibility_range_end = TAM_CHU
		chu.visibility_range_end_margin = 2.0
		chu.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


## Vị trí spawn chia đều quanh lối đi vòng quanh tháp.
func spawn_transform(index: int) -> Transform3D:
	var pts := spawn_points.get_children()
	if pts.is_empty():
		return Transform3D.IDENTITY
	return (pts[index % pts.size()] as Node3D).global_transform


## Đổi lá sang 3 tông xanh, ghế/sofa sang màu mây theo tên vật liệu (thân cây giữ nguyên).
func _retint_decor() -> void:
	for item: Node in $Decor.get_children():
		var leaf: Material = null
		for cap in [["Palm", mat_la_palm], ["Fern", mat_la_fern], ["Ground", mat_la_ground]]:
			if item.name.begins_with(cap[0]):
				leaf = cap[1]
		var cane := item.name.begins_with("Sofa") or item.name.begins_with("Table")
		for mi: MeshInstance3D in item.find_children("*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(s)
				var mname := mat.resource_name if mat != null else ""
				if leaf != null and mname in LEAF_NAMES:
					mi.set_surface_override_material(s, leaf)
				elif cane and mname in CANE_NAMES:
					mi.set_surface_override_material(s, mat_may)
