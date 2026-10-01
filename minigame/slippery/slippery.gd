extends MiniGameLan

## SLIPPERY SPRINT — đua trên làn băng. Về đích trước thì hạng cao hơn.
##
## Khuôn T4 thứ ba. Trò đơn giản nhất trong cả 15 trò: không đòn, không chướng ngại, không ai
## giết ai. Đối thủ duy nhất là cái sàn không cho mình dừng lại và không cho mình rẽ gấp.
##
## ## 0 gói tin ngoài `"tôi về đích"`
##
## Về đích dùng lại NGUYÊN đường ống khai tử của lớp cha: `xin_chet()` phát một gói, `_song[id]`
## ghi lại giây về đích. Không viết thêm một hàm mạng nào — chỉ đọc cùng con số đó theo chiều
## ngược lại ở `_chot_ket_qua()`.
##
## ## Vì sao "về đích" lại đi bằng cửa "chết"
##
## Hai chuyện nghe trái ngược nhau nhưng là cùng MỘT sự kiện: *người chơi rời cuộc, tại giây
## thứ N, do chính máy của họ tuyên*. Thêm một cặp RPC riêng cho nó chỉ để tên hàm đọc cho
## thuận tai là thêm một đường ống nữa phải kiểm và phải đồng bộ. Chỗ khác nhau duy nhất nằm ở
## bảng xếp hạng: chết thì về SAU là tốt, về đích thì về TRƯỚC là tốt.
##
## ## Sàn băng
##
## `Player.truot` — số giây để tăng tốc lên `speed`, và cũng là số giây để dừng. `dung_som()`
## PHẢI tắt lại, không thì người chơi trượt băng giữa phòng chờ.

## Băng trơn cỡ nào: giây để tăng tốc lên `speed`, và cũng là giây để dừng. Trơn hẳn được vì ở
## đây chạy thẳng, không phải xoay xở né chướng ngại.
const TRON := 1.15

var _vach_tai := 145.0
## Người này đã về đích chưa — để khỏi bắn `xin_chet()` thêm lần nữa ở khung hình sau.
var _ve_roi := false


func _ready() -> void:
	super()
	ten = "SLIPPERY SPRINT"
	luat = "WASD chạy trên băng · chuột xoay người · về vạch đỏ trước"
	giay_van = 30.0


func _dung_san() -> void:
	_ve_roi = false
	if san == null:
		return
	# Vạch đích là node có sẵn trong `lan.tscn`, các trò khác giấu đi. Đọc luôn vị trí của nó
	# làm mốc về đích — không chép con số 145 vào code để rồi một ngày hai bên lệch nhau.
	for lan in san.find_children("Lan*", "Node3D", false, false):
		var vach := lan.get_node_or_null("Vach") as Node3D
		if vach == null:
			continue
		vach.visible = true
		_vach_tai = -vach.position.z
	_doi_truot(TRON)


func dung_som() -> void:
	_doi_truot(0.0)
	super()


func _luat_moi_nhip() -> void:
	ghi_quang_duong()
	if _ve_roi or not con_song(NetManager.local_id()):
		return
	var p := _nguoi(NetManager.local_id())
	if p != null and quang_duong(p) >= _vach_tai:
		_ve_roi = true
		xin_chet()


## Ghi đè: làn có tường hai bên, không có gì giết người. Về đích đi bằng `xin_chet()` ở trên.
func _toi_thua() -> bool:
	return false


## Về đích rồi thì đứng lại cho khỏi trượt tiếp ra ngoài mốc.
func _khi_ai_do_chet(id: int) -> void:
	if id != NetManager.local_id():
		return
	var p := _nguoi(id)
	if p != null:
		p.khoa_di_chuyen = true


## Xếp hạng: ai về đích thì trên, trong nhóm đó ai về SỚM hơn thì trên. Chưa về thì xếp theo
## quãng đường đã đi.
##
## Ngược hẳn với lớp cha (sống lâu hơn thì trên) nên phải viết lại, không gọi `super()`.
func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _xa_nhat:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool:
		var ta := float(_song.get(a, -1.0))
		var tb := float(_song.get(b, -1.0))
		if ta >= 0.0 and tb >= 0.0:
			return ta < tb                      # cả hai đã về: sớm hơn thì trên
		if ta >= 0.0 or tb >= 0.0:
			return ta >= 0.0                    # một người đã về: người đó trên
		return float(_xa_nhat[a]) > float(_xa_nhat[b]))
	Fusion.rpc(_net_xep_hang, xep)


func _doi_truot(muc: float) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	p.truot = muc
	if muc <= 0.0:
		p.khoa_di_chuyen = false
