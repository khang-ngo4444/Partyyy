extends MiniGame3D

## BREAKING BLOCKS — sàn tan rồi mọc lại, đừng rơi xuống.
##
## Khuôn T2, trò đầu tiên dựng trên `MiniGame3D` nên cũng là bài kiểm cho cái khung đó.
##
## ## Vì sao trò này tốn ĐÚNG 0 gói tin lúc chơi
##
## Ô nào tan lúc nào là **hàm thuần** của `(pha_cua_o, gio(), chu_ky)`. Pha lấy từ hạt giống
## master gieo, `gio()` mỗi máy tự đếm. Không máy nào phải kể cho máy nào nghe điều gì.
##
## Gói duy nhất bay đi cả ván là `"tôi chết"`, và do **chính người rơi** phát.
##
## ## Chu kỳ ngắn dần
##
## Để nguyên một nhịp thì phút đầu đã học xong và nửa phút sau chỉ là chờ hết giờ. Chu kỳ co
## từ `CHU_KY_DAU` xuống `CHU_KY_CUOI` nên ván tự kết thúc kể cả khi ai cũng giỏi.

enum { THUONG, CANH_BAO, TAN }

## Ô biến mất bao lâu mỗi nhịp.
const GIAY_TAN := 1.1
## Hiện màu cảnh báo bao lâu TRƯỚC khi tan. Núm chỉnh độ khó quan trọng nhất: ngắn quá thì trò
## thành tung xúc xắc, dài quá thì đi dạo cũng không chết.
const GIAY_BAO := 0.9
const CHU_KY_DAU := 6.0
const CHU_KY_CUOI := 2.6
## Chu kỳ co hết cỡ sau chừng này giây.
const GIAY_CO_HET := 45.0

var _o: Array[OSan] = []
## Pha của từng ô, cùng thứ tự với `_o`. Gieo từ hạt giống nên mọi máy ra y hệt.
var _pha: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	super()
	ten = "BREAKING BLOCKS"
	luat = "WASD chạy · sàn đỏ là sắp tan · đừng rơi"


func _dung_san() -> void:
	_o.assign(san.find_children("*", "OSan", true, false))
	_pha.resize(_o.size())
	# Pha nằm trong khoảng KHÔNG chạm cửa sổ cảnh báo, nên ở `t = 0` mọi ô đều còn nguyên.
	#
	# Gieo pha trên cả chu kỳ thì ngay lúc vào sân đã có ~30% sàn biến mất — đo lần chạy đầu:
	# cả bốn người rơi trong vài giây, ván kết thúc trước cả ảnh chụp thứ hai. Cho ván mở ra
	# với sàn lành rồi thủng dần vừa công bằng hơn vừa đọc được luật.
	var toi_da := maxf(CHU_KY_DAU - GIAY_TAN - GIAY_BAO, 0.1)
	for i in _o.size():
		_pha[i] = _rng.randf() * toi_da
		_o[i].dat(true)
	if _o.is_empty():
		push_error("BreakingBlocks: san khong co o nao (thieu instance cua o_san.tscn)")


func _luat_moi_nhip() -> void:
	var t := gio()
	var ck := chu_ky(t)
	for i in _o.size():
		var tt := trang_thai_o(_pha[i], t, ck)
		_o[i].dat(tt != TAN, tt == CANH_BAO)


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Chu kỳ tại thời điểm `t`, co tuyến tính rồi dừng.
static func chu_ky(t: float) -> float:
	return lerpf(CHU_KY_DAU, CHU_KY_CUOI, clampf(t / GIAY_CO_HET, 0.0, 1.0))


## Trạng thái một ô. `pha` xê dịch mỗi ô một nhịp để cả sàn không tan cùng lúc.
##
## Thứ tự kiểm quan trọng: TAN phải xét TRƯỚC CANH_BAO. Xét ngược lại thì khi
## `GIAY_BAO + GIAY_TAN > chu_ky` (chu kỳ đã co hết), cửa sổ cảnh báo nuốt luôn cửa sổ tan và
## ô không bao giờ biến mất — trò tự tắt độ khó đúng lúc đáng ra khó nhất.
static func trang_thai_o(pha: float, t: float, ck: float) -> int:
	var u := fposmod(t + pha, ck)
	if u >= ck - GIAY_TAN:
		return TAN
	if u >= ck - GIAY_TAN - GIAY_BAO:
		return CANH_BAO
	return THUONG
