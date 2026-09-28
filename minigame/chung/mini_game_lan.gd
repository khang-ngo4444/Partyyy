class_name MiniGameLan
extends MiniGame3D

## KHUNG CHUNG cho khuôn T4 — mỗi người một LÀN CHẠY riêng, camera sau lưng của chính mình.
##
## Khác T1/T2/T3 ở đúng hai điểm, và cả hai đều nằm gọn trong file này:
##
## ## 1. Không có camera chung
##
## T1–T3 ném cả phòng vào một sân rồi mọi người nhìn qua đúng một `Camera3D` treo trên cao.
## T4 thì ngược lại: mỗi người chạy làn của riêng mình và nhìn từ sau lưng mình. Nên `_che_do_san()`
## ở đây **không đổi camera** — nó để nguyên `CameraRig` mà người chơi vẫn đang dùng từ phòng chờ.
##
## Hệ quả: điều khiển cũng giữ nguyên kiểu phòng chờ (WASD theo thân, chuột xoay người). Bật
## `che_do_san` của `Player` ở đây là hỏng: WASD sẽ theo trục thế giới trong khi camera lại
## theo thân, và thân thì tự xoay theo hướng chạy — camera quay vòng mỗi lần né sang bên.
##
## ## 2. Làn tách rời nhau, không phải vòng tròn quanh tâm
##
## `_cho_vao()` xếp người theo hàng ngang cách nhau `KHOANG_LAN`, xa tới mức không ai nhìn thấy
## làn của ai. Chướng ngại và quà của từng làn sinh từ **hạt giống + chỉ số làn**, nên hai người
## gặp đúng một chuỗi thử thách — công bằng mà vẫn không phải gửi gói tin nào.

## Hai làn cách nhau bao xa. Đủ để không nhìn thấy nhau, kể cả lúc camera lùi ra sau.
const KHOANG_LAN := 40.0
## Làn dài bao nhiêu mét. Khớp `lan.tscn` — người chơi chạy ~6 m/s nên 400 m là quá đủ cho 60 giây.
const DAI_LAN := 400.0

## Thứ tự người chơi, quyết định ai chạy làn nào. Lưu trước khi lớp cha dùng tới.
var _ds_nguoi: Array = []
## player_id -> quãng đường xa nhất đã tới. Mọi máy cùng cộng; bảng của master là bảng chốt.
var _xa_nhat: Dictionary = {}


func bat_dau(nguoi_choi: Array, giong: int) -> void:
	_ds_nguoi = nguoi_choi.duplicate()
	_xa_nhat.clear()
	for id in nguoi_choi:
		_xa_nhat[int(id)] = 0.0
	super(nguoi_choi, giong)
	# Quay mặt về đầu làn. `-Z` là hướng chạy, khớp cách `lan.tscn` được dựng.
	var toi := _nguoi(NetManager.local_id())
	if toi != null:
		toi.rotation.y = 0.0


## Người thứ `i` vào đầu làn thứ `i`.
func _cho_vao(i: int, _tong: int) -> Vector3:
	return Vector3(x_lan(i), 1.0, 0.0)


## Ghi đè: T4 KHÔNG đổi sang camera chung — xem ghi chú đầu file.
func _che_do_san(_bat: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not p.is_mine:
			continue
		p.che_do_san = false
		if p.rig != null and is_instance_valid(p.rig):
			p.rig.make_current()


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
