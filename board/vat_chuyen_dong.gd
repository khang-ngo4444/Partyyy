@tool
class_name VatChuyenDong
extends MeshInstance3D

## Chuyển động trang trí của đảo: gắn lên mesh nào cần xoay, nhấp nhô, bay vòng, trôi hoặc nhảy sóng.
## Bay vòng và nhảy sóng chạy quanh gốc của node cha; mesh hướng mũi +z theo chiều đi.
## Trong editor chỉ xem trước qua RenderingServer, không đổi transform nên scene không bị bẩn.

enum Kieu { XOAY, NHAP_NHO, BAY_VONG, TROI, NHAY_SONG }

const GOC_NGHIENG_NHAP_NHO := 0.04
const TOC_NGHIENG_NHAP_NHO := 0.65
## Trôi qua mép này thì quay lại mép đối diện.
const MEP_TROI := 280.0
const BUOC_GOC_TINH_HUONG := 0.001

@export var kieu := Kieu.XOAY
## rad/s khi xoay, bay vòng, nhảy sóng (âm = đi ngược); m/s khi trôi; hệ số sóng khi nhấp nhô.
@export var toc := 0.3
@export var bien_do := 0.2
@export var ban_kinh := 10.0
## Tâm vòng (x, z trong toạ độ node cha) khi bay vòng và nhảy sóng.
@export var tam := Vector2.ZERO
@export var pha := 0.0
## Độ lệch bán kính (m) để đường đi lượn sóng, không tròn đều.
@export var lech_vong := 0.0
## Số khúc lượn trong một vòng và pha của chúng.
@export var so_khuc := 3.0
@export var pha_khuc := 0.0
## Nhịp nhấp nhô khi bay vòng (rad/s).
@export var toc_nhap := 1.1
## Số cú nhảy trong một vòng khi nhảy sóng.
@export var so_cu_nhay := 60.0

var _thoi_gian := 0.0
var _goc := Transform3D.IDENTITY


func _ready() -> void:
	_goc = transform


func _process(delta: float) -> void:
	_thoi_gian += delta
	if Engine.is_editor_hint():
		_xem_truoc_trong_editor()
	else:
		transform = _bien_doi_luc_nay()


func _xem_truoc_trong_editor() -> void:
	_goc = transform
	var cha := global_transform * transform.affine_inverse()
	RenderingServer.instance_set_transform(get_instance(), cha * _bien_doi_luc_nay())


func _bien_doi_luc_nay() -> Transform3D:
	match kieu:
		Kieu.XOAY:
			return Transform3D(_goc.basis * Basis(Vector3.UP, _thoi_gian * toc), _goc.origin)
		Kieu.NHAP_NHO:
			return _nhap_nho()
		Kieu.BAY_VONG:
			return _bay_vong()
		Kieu.TROI:
			var chieu_dai := MEP_TROI * 2.0
			var x := fposmod(_goc.origin.x + _thoi_gian * toc + MEP_TROI, chieu_dai) - MEP_TROI
			return Transform3D(_goc.basis, Vector3(x, _goc.origin.y, _goc.origin.z))
		Kieu.NHAY_SONG:
			return _nhay_song()
	return _goc


func _nhap_nho() -> Transform3D:
	var nghieng := sin(_thoi_gian * TOC_NGHIENG_NHAP_NHO + pha) * GOC_NGHIENG_NHAP_NHO
	var vi_tri := _goc.origin + Vector3.UP * sin(_thoi_gian * toc + pha) * bien_do
	return Transform3D(_goc.basis * Basis(Vector3.BACK, nghieng), vi_tri)


func _bay_vong() -> Transform3D:
	var goc := pha + _thoi_gian * toc
	var nghieng := sin(_thoi_gian * TOC_NGHIENG_NHAP_NHO + pha) * GOC_NGHIENG_NHAP_NHO
	var quay := Basis(Vector3.UP, _huong_theo_vong(goc)) * Basis(Vector3.BACK, nghieng)
	var y := _goc.origin.y + sin(_thoi_gian * toc_nhap + pha) * bien_do
	return Transform3D(quay.scaled(_goc.basis.get_scale()), _tren_vong(goc, y))


func _tren_vong(goc: float, y: float) -> Vector3:
	var r := ban_kinh + sin(goc * so_khuc + pha_khuc) * lech_vong
	return Vector3(tam.x + cos(goc) * r, y, tam.y + sin(goc) * r)


## Hướng mũi +z theo tiếp tuyến thật của đường đi, kể cả khi vòng lượn sóng hoặc đi ngược.
func _huong_theo_vong(goc: float) -> float:
	var buoc := BUOC_GOC_TINH_HUONG * signf(toc if toc != 0.0 else 1.0)
	var di := _tren_vong(goc + buoc, 0.0) - _tren_vong(goc, 0.0)
	return atan2(di.x, di.z)


func _nhay_song() -> Transform3D:
	var goc := pha + _thoi_gian * toc
	var song := goc * so_cu_nhay
	var doc := cos(song) * so_cu_nhay * bien_do / ban_kinh
	var quay := Basis(Vector3.UP, _huong_theo_vong(goc)) * Basis(Vector3.RIGHT, -atan(doc))
	var y := _goc.origin.y + sin(song) * bien_do
	return Transform3D(quay.scaled(_goc.basis.get_scale()), _tren_vong(goc, y))
