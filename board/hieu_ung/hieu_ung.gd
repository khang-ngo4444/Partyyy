class_name HieuUng
extends Node3D

## Gốc mọi scene hiệu ứng dùng đồ (`board/hieu_ung/<món>.tscn`). Mọi máy dựng cùng một scene từ
## cùng một gói của master. Hình và thời gian nằm trong scene (AnimationPlayer "chay"; thêm "truot"
## khi trượt hoặc không kéo được). Script chỉ đặt các điểm neo vào thế giới và dời vài thứ theo
## hai thuộc tính mà animation điều khiển:
##   `tien` 0→1: node `Bay` đi từ tay người dùng tới mục tiêu (hoặc dọc `duong`); node `Day` căng
##       từ tay tới `Bay` (trụ dài 1 m dọc −Z).
##   `doi_cho` 0→1: quân cờ người bị kéo trượt từ chỗ cũ sang chỗ mới (Cần câu).
## Node neo (đều không bắt buộc): `Tu` (chân người dùng), `Dich` (chân mục tiêu), `Bay`, `Day`;
## trục −Z của chúng hướng từ người dùng sang mục tiêu.
## Track "Call Method" trong animation gọi: `bao_cham` (khoảnh khắc đòn ảnh hưởng quân cờ — bàn
## chỉ giật quân về ô sau mốc này), `no_o` (dựng `o_scene` trên từng ô của `cac_o`), `don_dep`.

signal cham
signal xong

## Dựng trên mỗi ô khi gọi `no_o` (tự phát và tự xoá).
@export var o_scene: PackedScene = null

## `Bay` chở luôn quân cờ người dùng (Trâu điên), cưỡi cao hơn `Bay` chừng `cao_cho`.
@export var mang_nguoi_dung := false
@export var cao_cho := 0.0

## Độ cao điểm xuất phát (tay người dùng) và điểm chạm ở mục tiêu, mét trên chân.
@export var cao_tay := 1.5
@export var cao_dich := 1.2

## Quỹ đạo vồng lên chừng này ở giữa đường.
@export var cao_cung := 0.0

@export_range(0.0, 1.0) var tien := 0.0: set = _dat_tien
@export_range(0.0, 1.0) var doi_cho := 0.0: set = _dat_doi_cho

var da_cham := false
var da_xong := false

var _bat_dau := false
var _tu_vt := Vector3.ZERO
var _den_vt := Vector3.ZERO
var _den_moi := Vector3.ZERO
var _duong := PackedVector3Array()
## Độ dài cộng dồn dọc `_duong`.
var _do_dai := PackedFloat32Array()
var _cac_o := PackedVector3Array()
var _nguoi_tu: Node3D = null
var _nguoi_den: Node3D = null
var _co_so := Basis.IDENTITY

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _tu: Node3D = get_node_or_null("Tu") as Node3D
@onready var _dich: Node3D = get_node_or_null("Dich") as Node3D
@onready var _bay: Node3D = get_node_or_null("Bay") as Node3D
@onready var _day: Node3D = get_node_or_null("Day") as Node3D


func _exit_tree() -> void:
	# Bị xoá sớm thì cũng phải để bàn giật quân về ô, không treo mãi.
	bao_cham()
	_bao_xong()


## `ngu`: "tu" Vector3 (chân người dùng), "den" Vector3 (chân mục tiêu / điểm rơi), "den_moi"
## (chỗ mục tiêu sẽ đứng sau đòn), "duong" Array[Vector3] (đường Bay đi), "cac_o" Array[Vector3],
## "nguoi_tu" / "nguoi_den" Node3D, "trung" bool (false → chạy clip "truot" nếu có).
func bat_dau(ngu: Dictionary) -> void:
	_tu_vt = ngu.get("tu", global_position)
	_den_vt = ngu.get("den", _tu_vt)
	_den_moi = ngu.get("den_moi", _den_vt)
	_duong = PackedVector3Array(ngu.get("duong", []))
	_cac_o = PackedVector3Array(ngu.get("cac_o", []))
	_nguoi_tu = ngu.get("nguoi_tu") as Node3D
	_nguoi_den = ngu.get("nguoi_den") as Node3D
	_do_dai = PackedFloat32Array([0.0])
	for i in range(1, _duong.size()):
		_do_dai.append(_do_dai[i - 1] + _duong[i - 1].distance_to(_duong[i]))
	var h := _den_vt - _tu_vt
	h.y = 0.0
	_co_so = Basis.looking_at(h.normalized() if h.length_squared() > 0.0001 else Vector3.FORWARD,
			Vector3.UP)
	global_transform = Transform3D(Basis.IDENTITY, _tu_vt)
	_bat_dau = true
	_cap_nhat()
	var khong_trung := not bool(ngu.get("trung", true))
	_anim.play("truot" if khong_trung and _anim.has_animation("truot") else "chay")
	_anim.advance(0.0)


func bao_cham() -> void:
	if da_cham:
		return
	da_cham = true
	cham.emit()


func no_o() -> void:
	if o_scene == null:
		return
	for vt in _cac_o:
		var n := o_scene.instantiate() as Node3D
		add_child(n)
		n.global_position = vt


func don_dep() -> void:
	_bao_xong()
	queue_free()


func _bao_xong() -> void:
	if not da_xong:
		da_xong = true
		xong.emit()


func _dat_tien(v: float) -> void:
	tien = v
	_cap_nhat()


func _dat_doi_cho(v: float) -> void:
	doi_cho = v
	if _bat_dau and _nguoi_den != null:
		_nguoi_den.global_position = _den_vt.lerp(_den_moi, v)
	_cap_nhat()


## Chân mục tiêu lúc này (đang bị kéo thì đi theo quân cờ).
func _den_hien() -> Vector3:
	if _nguoi_den != null and doi_cho > 0.0:
		return _nguoi_den.global_position
	return _den_vt


func _cap_nhat() -> void:
	if not _bat_dau:
		return
	if _tu != null:
		_tu.global_transform = Transform3D(_co_so, _tu_vt)
	if _dich != null:
		_dich.global_transform = Transform3D(_co_so, _den_hien())
	if _bay == null:
		return
	var diem := _diem_bay(tien)
	var huong := _diem_bay(minf(tien + 0.02, 1.0)) - diem
	if huong.length_squared() < 0.000001:
		huong = diem - _diem_bay(maxf(tien - 0.02, 0.0))
	if huong.length_squared() < 0.000001:
		huong = -_co_so.z
	huong = huong.normalized()
	var len_tren := Vector3.FORWARD if absf(huong.dot(Vector3.UP)) > 0.99 else Vector3.UP
	_bay.global_transform = Transform3D(Basis.looking_at(huong, len_tren), diem)
	if mang_nguoi_dung and _nguoi_tu != null:
		_nguoi_tu.global_position = diem + Vector3.UP * cao_cho
	if _day != null:
		var tay := _tu_vt + Vector3.UP * cao_tay
		var d := diem - tay
		var dai := d.length()
		var co := Basis.from_scale(Vector3(1.0, 1.0, maxf(dai, 0.0001)))
		if dai > 0.0001:
			var tren := Vector3.FORWARD if absf(d.normalized().dot(Vector3.UP)) > 0.99 else Vector3.UP
			co = Basis.looking_at(d / dai, tren) * co
		_day.global_transform = Transform3D(co, tay)


func _diem_bay(t: float) -> Vector3:
	if _duong.size() >= 2:
		var muc := t * _do_dai[_do_dai.size() - 1]
		for i in range(1, _duong.size()):
			if muc <= _do_dai[i] or i == _duong.size() - 1:
				var doan := _do_dai[i] - _do_dai[i - 1]
				var r := 0.0 if doan < 0.0001 else clampf((muc - _do_dai[i - 1]) / doan, 0.0, 1.0)
				return _duong[i - 1].lerp(_duong[i], r)
	var tay := _tu_vt + Vector3.UP * cao_tay
	var dich := _den_hien() + Vector3.UP * cao_dich
	return tay.lerp(dich, t) + Vector3.UP * (sin(PI * t) * cao_cung)
