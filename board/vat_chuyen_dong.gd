class_name VatChuyenDong
extends Node3D

## Chuyển động trang trí của đảo: gắn lên node nào cần xoay, nhấp nhô, bay vòng hoặc trôi.

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
var _y_goc := 0.0


func _ready() -> void:
	_y_goc = position.y


func _process(delta: float) -> void:
	_thoi_gian += delta
	match kieu:
		Kieu.XOAY:
			rotation.y += delta * toc
		Kieu.NHAP_NHO:
			position.y = _y_goc + sin(_thoi_gian * toc + pha) * bien_do
			rotation.z = sin(_thoi_gian * TOC_NGHIENG_NHAP_NHO + pha) * GOC_NGHIENG_NHAP_NHO
		Kieu.BAY_VONG:
			var goc := pha + _thoi_gian * toc
			position = Vector3(cos(goc) * ban_kinh, _y_goc + sin(goc * 2.0) * BIEN_DO_LUON_BAY,
					sin(goc) * ban_kinh)
			rotation.y = -goc
		Kieu.TROI:
			position.x += delta * toc
			if position.x > MEP_TROI:
				position.x = -MEP_TROI
