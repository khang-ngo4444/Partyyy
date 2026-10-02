class_name MiniGameLan
extends MiniGame3D

## KHUNG CHUNG cho khuôn T4 — mỗi người một LÀN RIÊNG, nhưng các làn SÁT NHAU và cả phòng
## nhìn qua MỘT camera chung.
##
## ## Vì sao làn riêng mà vẫn chung một chỗ
##
## Làn riêng là để công bằng: chướng ngại và quà của mọi làn sinh từ cùng một hạt giống nên ai
## cũng gặp đúng một chuỗi thử thách, và không ai cấn được vào đường của ai.
##
## Nhưng bản đầu để các làn cách nhau 40 m — xa tới mức không ai thấy ai. Công bằng tuyệt đối
## và nhạt tuyệt đối: mỗi người chạy một mình trong ống, không biết mình đang thắng hay thua.
## Giờ các làn kề vai nhau (`KHOANG_LAN` = bề ngang một làn, tường chung vách) và một camera
## bao hết. Vẫn làn ai người ấy chạy, nhưng thấy được cả phòng đang ở đâu.
##
## ## Camera
##
## Khác T1–T3: sân của chúng là một vòng tròn bán kính 7 m, một camera đứng yên là xong. Làn
## dài 150 m nên camera phải đi theo. Nó bám NGƯỜI DẪN ĐẦU, lùi đủ xa để người bét vẫn trong
## khung, và dịch ngang về giữa những làn ĐANG CÓ NGƯỜI — bốn người thì không chừa chỗ cho bốn
## làn trống.
##
## Góc và khoảng lùi đặt trên SCENE (`san_lan.tscn`, node `SanDau/Cam`) — code chỉ TỊNH TIẾN
## camera theo tốp, không xoay, không tự chọn độ cao.
##
## Camera là việc CỤC BỘ, mỗi máy tự tính từ vị trí mà replicator đã gửi sẵn. Không gói tin,
## và hai máy có lệch nhau vài khung hình cũng không ảnh hưởng gì tới xếp hạng.

## Hai làn cách nhau bao xa. Khớp `lan.tscn`: làn rộng 4 m + vách 0,6 m, nên 4,6 là hai làn
## dán sát, dùng chung vách. Nới ra là tách rời nhau trở lại.
const KHOANG_LAN := 4.6
## Làn dài bao nhiêu mét. Khớp `lan.tscn` — chạy ~6 m/s nên 150 m hết chừng 25 giây.
const DAI_LAN := 150.0

## Khung phải chứa được khoảng cách dẫn–bét tới chừng này mét; xa hơn thì người bét ra khỏi
## khung và tự biết mình đang bị bỏ lại. Nới to là camera lùi xa, nhân vật bé đi.
const CAM_GIAN_TOI_DA := 30.0
## Camera đuổi theo mượt chừng nào. Cao quá thì giật mỗi lần đổi người dẫn đầu.
const CAM_MUOT := 6.0

## Thứ tự người chơi, quyết định ai chạy làn nào. Lưu trước khi lớp cha dùng tới.
var _ds_nguoi: Array = []
## Chỗ đặt camera trong scene, tính từ gốc sân. Chụp lúc vào ván, sau đó chỉ cộng thêm độ dời.
var _cam_goc := Vector3.ZERO
## player_id -> quãng đường xa nhất đã tới. Mọi máy cùng cộng; bảng của master là bảng chốt.
var _xa_nhat: Dictionary = {}


func bat_dau(nguoi_choi: Array, giong: int) -> void:
	_ds_nguoi = nguoi_choi.duplicate()
	_xa_nhat.clear()
	for id in nguoi_choi:
		_xa_nhat[int(id)] = 0.0
	super(nguoi_choi, giong)
	var cam := _cam_san()
	if cam != null:
		_cam_goc = cam.global_position - san.global_position
	# Quay mặt về đầu làn. `-Z` là hướng chạy, khớp cách `lan.tscn` được dựng.
	var toi := _nguoi(NetManager.local_id())
	if toi != null:
		toi.rotation.y = 0.0


## Người thứ `i` vào đầu làn thứ `i`.
func _cho_vao(i: int, _tong: int) -> Vector3:
	return Vector3(x_lan(i), 1.0, 0.0)


## Camera chung đi theo cả tốp. Chạy sau `super()` nên đọc được vị trí mới nhất của mọi người.
func _process(delta: float) -> void:
	super(delta)
	if _chay:
		_nhip_camera(delta)


## Đặt camera sao cho thấy hết người đang chạy.
##
## Trượt dần về chỗ cần tới chứ không nhảy thẳng: người dẫn đầu đổi liên tục, nhảy thẳng thì
## khung giật mỗi lần đổi.
func _nhip_camera(delta: float) -> void:
	var cam := _cam_san()
	if cam == null or san == null:
		return
	var dan := 0.0
	var bet := INF
	var lan_min := INF
	var lan_max := -INF
	var co := false
	for p: Player in get_tree().get_nodes_in_group("players"):
		var i := lan_cua(p.player_id())
		if i < 0:
			continue
		co = true
		var d := quang_duong(p)
		dan = maxf(dan, d)
		bet = minf(bet, d)
		lan_min = minf(lan_min, x_lan(i))
		lan_max = maxf(lan_max, x_lan(i))
	if not co:
		return
	# Người bét quá xa thì thôi không lùi theo nữa — lùi mãi thì cả tốp bé như hạt gạo.
	var gian := clampf(dan - bet, 0.0, CAM_GIAN_TOI_DA)
	var dich := san.global_position + _cam_goc + Vector3(
			(lan_min + lan_max) * 0.5, gian * 0.35, -bet + gian * 0.5)
	cam.global_position = cam.global_position.lerp(dich, clampf(CAM_MUOT * delta, 0.0, 1.0))


## Toạ độ X của làn thứ `i`.
static func x_lan(i: int) -> float:
	return i * KHOANG_LAN


## Người này chạy làn số mấy. -1 nếu không tham gia.
func lan_cua(id: int) -> int:
	return _ds_nguoi.find(id)


## Quãng đường đã đi trên làn, tính từ vạch xuất phát.
func quang_duong(p: Player) -> float:
	if san == null:
		return 0.0
	return clampf(san.global_position.z - p.global_position.z, 0.0, DAI_LAN)


## Cập nhật kỷ lục quãng đường của mọi người. Lớp con gọi trong `_luat_moi_nhip()`.
##
## Đọc từ vị trí mà replicator đã gửi sẵn, nên không tốn gói tin nào. Lấy XA NHẤT chứ không lấy
## vị trí hiện tại: bị hất lùi hay chết rồi trượt ngược lại thì không được mất điểm đã đi.
func ghi_quang_duong() -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		var id := p.player_id()
		if _xa_nhat.has(id):
			_xa_nhat[id] = maxf(float(_xa_nhat[id]), quang_duong(p))


## Ô điểm: mét xa nhất đã tới trên làn. ✓ = đã rời cuộc (về đích ở Slippery, trúng đá ở Sidestep).
func diem_cua(id: int) -> float:
	return float(_xa_nhat[id]) if _xa_nhat.has(id) else NAN


func chu_diem(id: int) -> String:
	if not _xa_nhat.has(id):
		return ""
	return "%.0f m%s" % [float(_xa_nhat[id]), "" if con_song(id) else " ✓"]


## Xếp hạng theo quãng đường đi được, xa hơn thì trên.
func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _xa_nhat:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool:
		return float(_xa_nhat[a]) > float(_xa_nhat[b]))
	Fusion.rpc(_net_xep_hang, xep)
