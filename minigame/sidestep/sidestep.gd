extends MiniGameLan

## SIDESTEP SLOPE — chạy xuôi làn, đá lăn ngược lên. Đi xa hơn thì hạng cao hơn.
##
## Khuôn T4 đầu tiên: làn riêng, camera sau lưng của chính mình.
##
## ## 0 gói tin
##
## Đá sinh ra lúc nào, ở đâu — tất cả là hàm thuần của `(hạt giống, chỉ số làn, gio())`. Trúng
## đá thì **chính người bị trúng khai tử**. Quãng đường thì mọi máy đọc từ vị trí mà replicator
## đã gửi sẵn. Cả ván không thêm một byte nào ngoài gói `"tôi chết"`.
##
## ## Vì sao đá sinh ra theo ĐỒNG HỒ chứ không theo vị trí người chơi
##
## Sinh theo vị trí thì đá của mỗi người xuất hiện ở một chỗ khác nhau, và vị trí người chơi
## trên máy người khác luôn trễ vài chục ms — hai máy sẽ đặt cùng một tảng đá ở hai chỗ.
## Sinh theo đồng hồ thì làn của một người là một cuốn phim: bấm nút là nó chạy, ai xem cũng
## thấy đúng cảnh đó. Điểm sinh bám theo `TOC_CHAY_MAU` — tốc độ của một người chạy đều — nên
## đá luôn ló ra trong tầm nhìn chứ không rơi vào lưng.

## Tốc độ mẫu dùng để tính điểm sinh đá. Xấp xỉ `Player.speed`; không cần khớp tuyệt đối vì
## `TAM_NHIN` đã chừa dư.
const TOC_CHAY_MAU := 6.0
## Đá ló ra cách điểm sinh chừng này mét về phía trước. Camera bám tốp nên tầm nhìn ngắn hơn
## bản làn-riêng nhiều: 70 m là đá sinh ngoài khung, người chơi không kịp thấy nó tới.
const TAM_NHIN := 30.0
## Nghỉ giữa hai đợt đá, lúc đầu và lúc cuối.
const NGHI_DAU := 1.5
const NGHI_CUOI := 0.45
## Dày hết cỡ sau chừng này giây. Phải <= lúc đá ngừng sinh (`cho_sinh` chạm cuối làn ở ~20 s),
## không thì cả ván trôi qua mà đá chưa bao giờ đạt mật độ tối đa.
const GIAY_DAY_HET := 20.0
## Đá lệch trái/phải trong khoảng này. Làn rộng 4 m nên nửa làn là 2 m, trừ bán kính đá còn
## 1,4. Nới quá là đá nằm trong tường.
const LECH_TOI_DA := 1.4

@export var da_scene: PackedScene = null

var _lich: Array = []
var _ke_tiep := 0
var _da: Array[DaLan] = []


func _ready() -> void:
	super()
	ten = "SIDESTEP SLOPE"
	luat = "WASD chạy · chuột xoay người · né đá lăn · đi càng xa càng tốt"
	giay_van = 30.0


func _dung_san() -> void:
	_lich = lich_da(hat_giong)
	_ke_tiep = 0
	_da.clear()


func _luat_moi_nhip() -> void:
	ghi_quang_duong()
	var t := gio()
	while _ke_tiep < _lich.size() and t >= float(_lich[_ke_tiep]["luc"]):
		_nem(_lich[_ke_tiep])
		_ke_tiep += 1
	_da = _da.filter(func(d: DaLan) -> bool: return is_instance_valid(d))


## Ghi đè: trên làn có tường hai bên nên không ai rơi — luật duy nhất là trúng đá.
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return false
	for d in _da:
		if d.overlaps_body(p):
			return true
	return false


## Trúng đá thì đứng yên tại chỗ. Không khoá thì người đã chết vẫn chạy tiếp và vẫn ăn quãng
## đường — thành ra chết xong lại về nhất.
func _khi_ai_do_chet(id: int) -> void:
	if id != NetManager.local_id():
		return
	var p := _nguoi(id)
	if p != null:
		p.khoa_di_chuyen = true


func dung_som() -> void:
	var p := _nguoi(NetManager.local_id())
	if p != null:
		p.khoa_di_chuyen = false
	super()


## Một đợt đá: mỗi làn đang có người đều nhận đúng một tảng ở cùng chỗ lệch, cùng lúc.
##
## Cùng chuỗi thử thách cho mọi người là điều kiện để bảng xếp hạng có nghĩa — khác chuỗi thì
## người thắng chỉ là người bốc được làn dễ.
func _nem(muc: Dictionary) -> void:
	if san == null or da_scene == null:
		return
	var z: float = san.global_position.z - cho_sinh(float(muc["luc"]))
	for i in _ds_nguoi.size():
		var d := da_scene.instantiate() as DaLan
		san.add_child(d)
		d.lan(Vector3(san.global_position.x + x_lan(i) + float(muc["lech"]),
				san.global_position.y + 1.3, z))
		_da.append(d)


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Đá đợt lúc `t` ló ra cách vạch xuất phát bao nhiêu mét.
static func cho_sinh(t: float) -> float:
	return TOC_CHAY_MAU * t + TAM_NHIN


## Toàn bộ lịch đá của một ván, suy ra từ hạt giống.
static func lich_da(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	var t := 2.0
	# Dừng khi điểm sinh chạy quá cuối làn: đá sinh ngoài sàn thì rơi thẳng xuống hư không.
	while t < 90.0 and cho_sinh(t) <= MiniGameLan.DAI_LAN:
		ds.append({"luc": t, "lech": rng.randf_range(-LECH_TOI_DA, LECH_TOI_DA)})
		t += lerpf(NGHI_DAU, NGHI_CUOI, clampf(t / GIAY_DAY_HET, 0.0, 1.0))
	return ds
