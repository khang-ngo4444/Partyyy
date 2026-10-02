extends MiniGameLan

## SIDESTEP SLOPE — chạy NGƯỢC lên một con dốc, xe lao XUỐNG về phía mình. Né sang trái/phải hay
## nhảy, leo được xa nhất lúc hết giờ thì thắng.
##
## Khuôn T4 (`MiniGameLan`): camera chung bám tốp, xếp hạng theo quãng đường xa nhất. Khác bản
## đầu ba chỗ, và cả ba đều do bản đầu không ra trò:
##
##   1. **Một con dốc CHUNG rộng 14 m** (`san_doc.tscn`) thay cho làn riêng 4 m có tường hai bên.
##      Làn 4 m với chướng ngại 2,6 m thì né hay không là chuyện may rủi.
##   2. **Xe** (`XeDoc`) thay cho đá lăn, chạy trong 5 làn có vạch kẻ — nhìn là đọc được đường đi.
##   3. **Bị tông là văng ngược xuống dốc**, không bị loại. Mất quãng đường + mất thời gian bò lại
##      là cái giá; một cú chạm không được kết thúc cả ván của ai.
##
## ## 0 gói tin cho xe
##
## Lịch xe là hàm thuần của hạt giống (`XeDoc.lich`), vị trí xe là hàm thuần của `gio()`. Mọi máy
## chiếu cùng một cuốn phim giao thông. Ai bị tông thì CHÍNH máy người đó tự hất mình (luật chung).
##
## ## Công bằng
##
## Không xe nào "mọc" cạnh người: lúc ván mở mọi xe còn cách vạch ≥ 45 m, xe mới vào đường từ đỉnh
## dốc 250 m (không ai leo tới trong 35 giây). Một hàng xe chiếm tối đa 3/5 làn. Tốc độ và mật độ
## tăng đều. `kiem_luat.gd` mô phỏng cả lịch và chặn bản nào phá các điều này.

## Bị tông thì văng ngược xuống dốc mạnh cỡ nào (m/s) — ngang và dốc lên. Lực đẩy tắt dần 9 m/s²
## (`Player.DAY_TAT_DAN`) nên trừ đi tốc chạy 6 m/s còn văng lùi chừng 8 m, cộng thời gian bò lại.
const HAT_LUI := 18.0
const HAT_LEN := 5.0
## Vừa bị tông thì chừng này giây sau mới bị tông lần nữa — không thì một xe đi qua người mình
## hất liên tục mỗi khung hình.
const MIEN := 0.8
## Khoảng cách giữa hai người lúc xuất phát, mét.
const CACH_XUAT_PHAT := 2.2

@export var xe_scene: PackedScene = null

var _lich: Array = []
var _ke_tiep := 0
var _xe: Array[XeDoc] = []
var _mien_toi := -99.0


func _ready() -> void:
	super()
	ten = "SIDESTEP SLOPE"
	luat = "WASD chạy lên dốc · Space nhảy · né xe lao xuống · bị tông là văng ngược xuống"
	giay_van = 35.0


func _dung_san() -> void:
	_lich = XeDoc.lich(hat_giong, giay_van)
	_ke_tiep = 0
	_xe.clear()
	_mien_toi = -99.0


## Rải người ngang lòng đường quanh tâm, không xếp mỗi người một làn riêng.
func _cho_vao(i: int, tong: int) -> Vector3:
	var x := (float(i) - float(tong - 1) * 0.5) * CACH_XUAT_PHAT
	return Vector3(clampf(x, -6.0, 6.0), 1.0, 0.0)


func dai_lan() -> float:
	return XeDoc.DAI


func cao_tai(d: float) -> float:
	return XeDoc.cao_tai(d)


func _luat_moi_nhip() -> void:
	ghi_quang_duong()
	var t := gio()
	# Xe vào đường khi đầu xe chạm đỉnh dốc. Lịch xếp theo lúc tới vạch và tốc độ chỉ tăng, nên
	# lúc vào đường cũng tăng dần — duyệt tuần tự là đủ.
	while _ke_tiep < _lich.size():
		var m: Dictionary = _lich[_ke_tiep]
		if XeDoc.vi_tri(float(m["toc"]), float(m["toi_vach"]), t) < -XeDoc.DAI:
			break
		_tha_xe(m)
		_ke_tiep += 1
	var con: Array[XeDoc] = []
	for x in _xe:
		if x.dat_luc(t):
			con.append(x)
		else:
			x.queue_free()
	_xe = con
	_bi_tong()


## Nhân vật CỦA MÁY NÀY vừa bị xe nào tông thì tự hất mình ngược xuống dốc.
func _bi_tong() -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null or gio() < _mien_toi:
		return
	for x in _xe:
		if x.overlaps_body(p):
			_mien_toi = gio() + MIEN
			# +Z là xuống dốc. Lệch ngang theo phía người đứng so với tâm xe: bị tông bên trái
			# xe thì văng chéo sang trái, đọc ra được là "xe húc vào mình".
			var ngang := signf(p.global_position.x - x.global_position.x) * 3.0
			p.day(Vector3(ngang, HAT_LEN, HAT_LUI))
			return


func _tha_xe(m: Dictionary) -> void:
	if san == null or xe_scene == null:
		return
	var x := xe_scene.instantiate() as XeDoc
	san.add_child(x)
	x.chay(float(m["x"]), float(m["toc"]), float(m["toi_vach"]), san.global_position)
	x.dat_luc(gio())
	_xe.append(x)


## Ghi đè: trò này KHÔNG loại ai — bị tông chỉ văng ngược. Sàn có tường hai bên nên cũng không
## rơi ra ngoài được.
func _toi_thua() -> bool:
	return false
