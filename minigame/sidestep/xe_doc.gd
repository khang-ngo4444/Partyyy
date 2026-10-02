class_name XeDoc
extends Area3D

## MỘT xe (toa goòng) đang lao XUỐNG dốc về phía người chơi.
##
## Hình xe, đèn pha và hộp va chạm nằm trong `xe_doc.tscn` và bằng nhau. Script chỉ lo **chạy
## theo lịch và tự tan**.
##
## ## Xe là hàm thuần của đồng hồ — 0 gói tin
##
## Vị trí một xe chỉ phụ thuộc `(làn, tốc độ, lúc tới vạch xuất phát, gio())`, và cả lịch xe sinh
## từ hạt giống (`lich`). Mọi máy chiếu đúng một cuốn phim giao thông; không ai phải gửi "xe đang
## ở đâu". Người bị tông tự áp cú hất lên mình (luật chung: nạn nhân tự khai).
##
## Hàm thuần nằm ở ĐÂY chứ không ở `sidestep.gd`: file này không đụng `NetManager`, nên
## `kiem_luat.gd` chạy được bằng `godot --headless -s`.

## Dốc nghiêng chừng này độ, khớp `Doc` trong `san_doc.tscn`.
const DOC := 6.0
## Đường dài (đo ngang) và nửa bề rộng lòng đường, khớp `san_doc.tscn`.
const DAI := 250.0
## Năm làn xe, toạ độ X tâm làn. Xe rộng 1,8 m nên hai làn kề nhau chỉ hở 0,6 m — không lách
## qua được; muốn qua phải tìm làn TRỐNG.
const LAN := [-4.8, -2.4, 0.0, 2.4, 4.8]
## Một hàng xe chiếm tối đa chừng này làn — luôn chừa ít nhất 2 làn trống để thoát.
const TOI_DA_MOI_HANG := 3
## Lệch ngẫu nhiên quanh tâm làn: đủ để không đọc thuộc lòng được, không đủ để lấn làn bên.
const LECH := 0.3
## Tốc độ xe đầu ván và cuối ván, m/s. 17 m/s thấy từ 35 m vẫn còn 2 giây để né.
const TOC_DAU := 9.0
const TOC_CUOI := 17.0
## Khoảng cách giữa hai hàng xe, giây — đầu ván thưa, cuối ván dày.
const NHIP_DAU := 2.4
const NHIP_CUOI := 1.0
## Tăng dần tới hết cỡ ở giây (tới-vạch) này.
const GIAY_KHO_HET := 45.0
## Lúc ván bắt đầu, mọi xe phải còn cách vạch xuất phát ít nhất chừng này mét về phía dốc trên —
## không xe nào "mọc" cạnh người chơi.
const CACH_LUC_DAU := 45.0
## Xe chạy quá vạch xuất phát chừng này mét thì tan.
const QUA_VACH := 15.0

## Tốc độ của xe này, m/s, và lúc nó tới vạch xuất phát (giây theo `gio()`).
var toc := 0.0
var toi_vach := 0.0
var _x := 0.0
var _goc_san := Vector3.ZERO


## Xe chạy trong làn `x`, tới vạch xuất phát lúc `toi_vach_luc`. `goc_san` là gốc sân (vạch).
func chay(x: float, toc_do: float, toi_vach_luc: float, goc_san: Vector3) -> void:
	_x = x
	toc = toc_do
	toi_vach = toi_vach_luc
	_goc_san = goc_san
	rotation_degrees.x = DOC


## Đặt xe đúng chỗ ở giây `t`. Trả về `false` khi xe đã chạy hết đường (người gọi xoá xe).
func dat_luc(t: float) -> bool:
	var z := vi_tri(toc, toi_vach, t)
	if z > QUA_VACH:
		return false
	# +0,2: mặt trên của tấm đường dày 0,4 m.
	global_position = _goc_san + Vector3(_x, cao_tai(-z) + 0.2, z)
	return true


## Toạ độ Z (theo trục sân, âm = phía dốc trên) của xe ở giây `t`.
static func vi_tri(toc_do: float, toi_vach_luc: float, t: float) -> float:
	return toc_do * (t - toi_vach_luc)


## Mặt đường cao bao nhiêu ở khoảng cách ngang `d` mét lên dốc.
static func cao_tai(d: float) -> float:
	return d * tan(deg_to_rad(DOC))


## Cả lịch xe của một ván: `[{x, toc, toi_vach}]`, sinh từ hạt giống.
##
## Lịch đánh theo lúc TỚI VẠCH chứ không theo lúc sinh: thế thì lúc ván mở, đường đã có sẵn dòng
## xe đang chạy (xe "sinh" từ trước, ở xa trên dốc), và hàng đầu tiên tới đám đông sau vài giây
## thay vì phải chờ xe bò hết 250 m.
static func lich(giong: int, giay_van: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	# Xe cuối cùng cần trong lịch: tới vạch đủ muộn để người dẫn đầu (chạy hết ván) vẫn gặp xe.
	var het := giay_van + DAI / TOC_DAU
	var t := 0.0
	while t < het:
		var k := clampf(t / GIAY_KHO_HET, 0.0, 1.0)
		var v := lerpf(TOC_DAU, TOC_CUOI, k)
		# Bỏ những hàng mà lúc ván mở đã ở quá gần vạch.
		if v * t >= CACH_LUC_DAU:
			# Đầu ván 1 xe/hàng, giữa ván tới 2, cuối ván tới `TOI_DA_MOI_HANG`.
			var so := 1 + rng.randi_range(0, int(round(k * float(TOI_DA_MOI_HANG - 1))))
			var lan := range(LAN.size())
			_tron(lan, rng)
			for j in so:
				ds.append({"x": float(LAN[lan[j]]) + rng.randf_range(-LECH, LECH), "toc": v,
						"toi_vach": t})
		t += lerpf(NHIP_DAU, NHIP_CUOI, k)
	return ds


static func _tron(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tam = a[i]
		a[i] = a[j]
		a[j] = tam
