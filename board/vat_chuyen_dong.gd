@tool
class_name VatChuyenDong
extends MeshInstance3D

## Chuyển động trang trí của đảo: gắn lên mesh nào cần xoay, nhấp nhô, bay vòng hoặc trôi.
## Trong editor chỉ xem trước qua RenderingServer, không đổi transform nên scene không bị bẩn.

enum Kieu { XOAY, NHAP_NHO, BAY_VONG, TROI }

const GOC_NGHIENG_NHAP_NHO := 0.04
const TOC_NGHIENG_NHAP_NHO := 0.65
const BIEN_DO_LUON_BAY := 0.2
## Trôi qua mép này thì quay lại mép đối diện.
const MEP_TROI := 280.0

@export var kieu := Kieu.XOAY
## rad/s khi xoay và bay vòng; m/s khi trôi; hệ số sóng khi nhấp nhô.
@export var toc := 0.3
@export var bien_do := 0.2
@export var ban_kinh := 10.0
@export var pha := 0.0

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
	var ra := _goc
	match kieu:
		Kieu.XOAY:
			ra.basis = _goc.basis * Basis(Vector3.UP, _thoi_gian * toc)
		Kieu.NHAP_NHO:
			ra.origin.y += sin(_thoi_gian * toc + pha) * bien_do
			var nghieng := sin(_thoi_gian * TOC_NGHIENG_NHAP_NHO + pha) * GOC_NGHIENG_NHAP_NHO
			ra.basis = _goc.basis * Basis(Vector3.BACK, nghieng)
		Kieu.BAY_VONG:
			var goc := pha + _thoi_gian * toc
			ra.origin = Vector3(cos(goc) * ban_kinh, _goc.origin.y + sin(goc * 2.0) * BIEN_DO_LUON_BAY,
					sin(goc) * ban_kinh)
			ra.basis = Basis(Vector3.UP, -goc)
		Kieu.TROI:
			var chieu_dai := MEP_TROI * 2.0
			ra.origin.x = fposmod(_goc.origin.x + _thoi_gian * toc + MEP_TROI, chieu_dai) - MEP_TROI
	return ra
