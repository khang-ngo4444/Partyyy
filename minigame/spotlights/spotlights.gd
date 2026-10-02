extends MiniGame3D

## SEARING SPOTLIGHTS — nhớ mình đang đứng đâu lúc sàn còn sáng, rồi đi trong tối.
##
## Khuôn T2. Khác hai trò kia ở hai chỗ: **có máu** (trò duy nhất không giết ngay trong một lần
## chạm) và **sàn tắt đèn theo chu kỳ**.
##
## ## Vòng lặp cốt lõi
##
## ```
## SÁNG HẲN  →  tối dần  →  TỐI HẲN  →  sáng dần  →  SÁNG HẲN  →  chu kỳ sau, thêm một đèn
##   (nhìn,        (thấy       (đi theo      (nhận ra      (định vị
##  ghi nhớ       rõ đang      ký ức +       mình đang      lại)
##  chỗ mình)     tắt dần)    vệt đèn)       ở đâu)
## ```
##
## Thứ người chơi phải nhớ là **chỗ của CHÍNH MÌNH trên sàn**, không phải đường đi của đèn. Đèn
## chạy Lissajous, không khép thành vòng đoán trước được — nhớ đường đi của nó là vô ích, và đó
## là cố ý.
##
## Trong tối, vệt sáng của đèn là **mốc định hướng duy nhất đáng kể**: người chơi nhìn xem đèn
## đang rọi ở đâu, suy ra mình đang ở đâu so với nó, rồi quyết định đi hướng nào.
##
## ## Vì sao bản này thêm chu kỳ
##
## Bản trước **tối từ giây 0 tới hết ván**. Không có lúc nào sáng để mà nhớ, nên không có gì để
## nhớ: người chơi bị thả vào bóng tối và đi loạn. Toàn bộ vòng lặp trên không tồn tại — trò chỉ
## còn là tránh vài vùng sáng trong một căn phòng tối.
##
## ## Vì sao KHÔNG chết vì rơi
##
## Lớp cha giết người rơi khỏi sàn, nhưng sàn ở đây là chỗ người chơi đi trong tối và không thấy
## bờ — chết vì chạy quá đà trong bóng tối là chết vì không có thông tin, không phải vì chơi dở.
## `_toi_thua()` ở đây **không gọi `super()`**, và vị trí người chơi bị kẹp trong `BAN_KINH_GIU`
## nên không ai ra khỏi sàn được. Viền sàn phát sáng (`VienSan`) chính là chỗ bức tường vô hình
## đó nằm, nên nó không phải tường bí ẩn.
##
## ## 0 gói tin
##
## Đường đi của đèn, số đèn, và độ sáng đều là hàm thuần của `gio()` và hạt giống. Máu trừ cục
## bộ, hết thì tự khai tử.

## Mất bao nhiêu máu mỗi giây khi đứng trong đèn. Máu đầy 100 (đặt trong `.tscn`) nên
## 100 / 40 = 2,5 giây là chết.
const MAT_MAU_MOI_GIAY := 40.0
## Đèn đi trên quỹ đạo Lissajous quanh tâm sàn, biên độ chừng này.
##
## 6,2 là trần, suy ra từ hai ràng buộc chứ không chọn bừa — và bản cũ để 7,8 nên phá cả hai:
##
##   1. **Đèn phải rọi TRONG sàn.** Lissajous hai trục nên tâm đèn ra xa nhất là `TAM_QUET·√2`,
##      không phải `TAM_QUET`. Với 7,8 thì tâm ra tới 11,03 m, cộng vệt sáng 2,66 là 13,69 m
##      trên sàn bán kính 11,5 — vệt sáng rơi ra ngoài sàn.
##   2. **Người phải chạy nhanh hơn đèn.** Tốc đèn đỉnh là `TAM_QUET·nhịp·√(1+1,37²)`. Với 7,8
##      và nhịp 0,52 thì ra 6,88 m/s, trong khi `Player.speed` là 6,0 — đèn đuổi được người.
##
## 6,2 cho tâm xa nhất 8,77 m (+vệt = 11,43 m, vừa tới viền) và tốc đỉnh 5,47 m/s. Vẫn phủ hết
## phần sàn đi được (`BAN_KINH_GIU` = 11,0) nên không sinh ra vành ngoài an toàn vĩnh viễn.
const TAM_QUET := 6.2

## Bốn chặng của một chu kỳ, giây.
##
## `GIAY_SANG` phải đủ dài để kịp nhìn và ghi nhớ chỗ mình — đây là chặng QUAN TRỌNG NHẤT, cắt
## ngắn nó là bỏ luôn phần "nhớ". `GIAY_MO` và `GIAY_SANG_LAI` phải thấy được là đang chuyển,
## không được tắt phụp.
const GIAY_SANG := 4.0
const GIAY_MO := 1.6
const GIAY_TOI := 6.5
const GIAY_SANG_LAI := 1.4
const CHU_KY := GIAY_SANG + GIAY_MO + GIAY_TOI + GIAY_SANG_LAI

## Chu kỳ đầu có mấy đèn, và trần.
##
## Trần là 8 vì hình học, không phải vì thích: nón đèn rọi vệt bán kính 2,66 m nên 8 đèn chiếm
## ~43% sàn (bán kính 11,5). Đèn nón cũ 18° rọi vệt 3,9 m — 8 đèn là 92% sàn, kín gần hết, và
## lúc đó không còn chỗ nào để mà đi.
const DEN_DAU := 3
const DEN_TOI_DA := 8

## Kẹp người chơi trong bán kính này. Sàn 11,5; kẹp 11,0 để thân người còn hẳn trên mặt sàn.
const BAN_KINH_GIU := 11.0

## Hai đầu của thang sáng. `_dung_san()` đọc đầu TỐI từ chính `san_spot.tscn` nên không chép tay;
## đầu SÁNG là giá trị mặc định của `san_dau.tscn`.
const DEN_TROI_SANG := 1.1

@onready var _thanh: ThanhMau = $ThanhMau

var _den: Array[Node3D] = []
## Vùng sáng của từng đèn, cùng thứ tự với `_den`.
var _vung: Array[Area3D] = []
var _pha: PackedFloat32Array = PackedFloat32Array()
var _nhip: PackedFloat32Array = PackedFloat32Array()

## Đèn trời của sân và môi trường, hai thứ bị chu kỳ sáng/tối điều khiển.
var _troi: DirectionalLight3D = null
var _env: Environment = null
var _env_toi: Environment = null
var _env_sang: Environment = null
var _troi_toi := 0.0
## Viền sàn — tắt dần theo độ sáng, để lúc tối màn hình ĐEN HẲN.
var _vien: GeometryInstance3D = null


func _ready() -> void:
	super()
	ten = "SEARING SPOTLIGHTS"
	luat = "WASD chạy · nhớ chỗ mình lúc còn sáng · tránh vùng sáng khi tối"
	giay_van = 75.0


func _dung_san() -> void:
	_den.assign(san.find_children("Den*", "Node3D", false, false))
	_vung.clear()
	for d in _den:
		_vung.append(d.get_node("Vung") as Area3D)
	_vien = san.get_node_or_null("VienSan") as GeometryInstance3D
	_pha.resize(_den.size())
	_nhip.resize(_den.size())
	for i in _den.size():
		_pha[i] = _rng.randf() * TAU
		# Nhịp lệch nhau thì hai đèn không bao giờ khoá pha thành một cặp đi song song mãi.
		_nhip[i] = _rng.randf_range(0.28, 0.52)
	_thanh.mo()
	if _den.is_empty():
		push_error("Spotlights: san khong co node ten Den*")
		return

	# Môi trường phải DUPLICATE: `env_san_toi.tres` là tài nguyên trên đĩa, sửa thẳng nó thì
	# trong editor nó bị ghi đè thật và ván sau mở ra với độ sáng của ván trước.
	var cam := _cam_san()
	_env_toi = load("res://materials/env_san_toi.tres") as Environment
	_env_sang = load("res://materials/env_san_sang.tres") as Environment
	if cam != null:
		_env = _env_toi.duplicate() as Environment
		cam.environment = _env
	_troi = san.find_child("Den", true, false) as DirectionalLight3D
	if _troi != null:
		_troi_toi = _troi.light_energy
	# Ván mở ra ở chặng SÁNG, nên đặt đúng độ sáng ngay từ khung hình đầu — không thì khung đầu
	# tối đen rồi mới bật, và cái nháy đó đúng lúc người chơi đang cần nhìn chỗ mình.
	_dat_sang(1.0)


func dung_som() -> void:
	_thanh.dong()
	_hien_ten(true)
	super()


func _luat_moi_nhip() -> void:
	var t := gio()
	_dat_sang(do_sang(t))
	var n := so_den(t)
	for i in _den.size():
		var v := cho_den(_pha[i], _nhip[i], t)
		_den[i].position = Vector3(v.x, _den[i].position.y, v.y)
		# Đèn chưa tới lượt thì tắt HẲN — cả bóng đèn lẫn chùm tia `Tia`. Vùng sát thương thì
		# `_an_mau` đã chỉ xét `i < n`, nên ẩn cả node không đẻ ra vùng cháy vô hình.
		_den[i].visible = i < n
	# Kẹp cả người đã hết máu: trò này không ai được rơi khỏi sàn, kể cả lúc đang xem.
	giu_trong_san(BAN_KINH_GIU)
	if con_song(NetManager.local_id()):
		_an_mau(n)


## Trừ máu nếu đang đứng trong vùng sáng của một đèn ĐANG BẬT.
##
## Hỏi thẳng `Area3D`: bán kính vùng cháy bằng đúng vệt sáng của nón đèn trong `.tscn`.
##
## Bản trước tự tính với `BAN_KINH_DEN = 3.4` trong khi nón đèn (cao 12 m, góc 18°) rọi ra vệt
## bán kính 3,9 — đứng trong quầng sáng mà không mất máu.
func _an_mau(n: int) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	for i in mini(n, _vung.size()):
		if _vung[i] != null and _vung[i].overlaps_body(p):
			_thanh.tru(MAT_MAU_MOI_GIAY, get_process_delta_time())
			return


## Đặt độ sáng chung của sàn: `s` = 0 là tối hẳn, 1 là sáng hẳn.
##
## Tối hẳn là ĐEN HẲN: không đèn trời, không ánh sáng nền, viền sàn tắt, tên người khác ẩn —
## nhìn thấy nhân vật (kể cả của mình) CHỈ khi nó đứng trong vệt đèn.
##
## Nội suy giữa hai tài nguyên `env_san_toi` và `env_san_sang` chứ không chép số vào code — hai
## con số đó đã nằm trong `.tres`, chép ra đây là có hai nguồn sự thật.
func _dat_sang(s: float) -> void:
	if _troi != null:
		_troi.light_energy = lerpf(_troi_toi, DEN_TROI_SANG, s)
	if _vien != null:
		_vien.transparency = 1.0 - s
	_hien_ten(s > 0.5)
	if _env == null:
		return
	_env.ambient_light_energy = lerpf(
			_env_toi.ambient_light_energy, _env_sang.ambient_light_energy, s)
	_env.ambient_light_color = _env_toi.ambient_light_color.lerp(
			_env_sang.ambient_light_color, s)
	_env.background_color = _env_toi.background_color.lerp(_env_sang.background_color, s)


## Tên nổi trên đầu là `Label3D` không bị bóng tối che — để nguyên thì tối hẳn vẫn thấy từng
## người đứng đâu. Tên của chính mình vốn đã ẩn (`Player._apply_name`), không bật lại.
func _hien_ten(hien: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not p.is_mine:
			p.name_tag.visible = hien


## Ghi đè và KHÔNG gọi `super()`: xem ghi chú "vì sao không chết vì rơi" đầu file. Hết máu là
## đường thua duy nhất.
func _toi_thua() -> bool:
	return _thanh.het()


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Chỗ của một đèn tại thời điểm `t`. Quỹ đạo Lissajous: hai nhịp lệch nhau nên đường đi không
## khép thành một vòng tròn đoán trước được. Đèn chạy liên tục qua CẢ bốn chặng, kể cả lúc tối.
static func cho_den(pha: float, nhip: float, t: float) -> Vector2:
	return Vector2(
			sin(t * nhip + pha) * TAM_QUET,
			sin(t * nhip * 1.37 + pha * 2.0) * TAM_QUET)


## Chu kỳ thứ mấy tại giây `t`, đếm từ 0.
static func chu_ky_thu(t: float) -> int:
	return int(t / CHU_KY)


## Mấy đèn bật tại giây `t`. Thêm một đèn mỗi chu kỳ, tới trần.
##
## Đèn mới bật đúng lúc chu kỳ mở ra, tức đang ở chặng SÁNG — người chơi thấy nó xuất hiện và
## còn kịp dịch chỗ. Bật giữa lúc tối thì là một vùng cháy mọc ra không báo.
static func so_den(t: float) -> int:
	return mini(DEN_DAU + chu_ky_thu(t), DEN_TOI_DA)


## Độ sáng chung của sàn tại giây `t`: 1 = sáng hẳn, 0 = tối hẳn.
static func do_sang(t: float) -> float:
	var u := fposmod(t, CHU_KY)
	if u < GIAY_SANG:
		return 1.0
	u -= GIAY_SANG
	if u < GIAY_MO:
		return 1.0 - u / GIAY_MO
	u -= GIAY_MO
	if u < GIAY_TOI:
		return 0.0
	return (u - GIAY_TOI) / GIAY_SANG_LAI
