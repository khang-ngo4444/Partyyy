class_name XeTang
extends Node2D

## Một xe tăng: giữ trạng thái và tự lái theo hướng hiện tại.

const TOC_DO := 110.0            ## pixel/giây
const CO := 26.0                 ## cạnh thân xe
## Nghỉ giữa hai phát (giây).
const NGHI_BAN := 0.45

## Hướng nòng (giữ nguyên khi thả phím).
var huong := Vector2i(0, -1)
var song := true
var _di := Vector2i.ZERO
var _ban_luc := -99.0

@onready var _than: ColorRect = $Than
@onready var _vien: ColorRect = $Vien


func khoi_tao(mau: Color, cua_toi: bool) -> void:
	_than.color = mau
	# Xe của mình có viền trắng.
	_vien.visible = cua_toi


## Đặt hướng và vị trí (nắn lệch giữa các máy).
func lai(h: Vector2i, vi: Vector2) -> void:
	position = vi
	_di = h
	if h != Vector2i.ZERO:
		huong = h
	# Xoay cả node; thả phím thì nòng giữ hướng cũ.
	rotation = Vector2(huong).angle()


func chay(delta: float, ban_do: BanDoTank) -> void:
	if not song or _di == Vector2i.ZERO:
		return
	var moi := position + Vector2(_di) * TOC_DO * delta
	# Kiểm bốn góc thân xe.
	var r := CO * 0.5 - 1.0
	for g: Vector2 in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		if ban_do.loai_tai(moi + g) != BanDoTank.TRONG:
			return
	position = moi


func san_sang_ban(gio: float) -> bool:
	return song and gio - _ban_luc >= NGHI_BAN


func ghi_ban(gio: float) -> void:
	_ban_luc = gio


func chet() -> void:
	song = false
	_di = Vector2i.ZERO
	hide()
