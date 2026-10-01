extends MiniGame3D

## ACIDIC ATOLL — sáu đảo giữa bồn axit, đảo chìm dần. Chọn đứng đâu, và chạy sang kịp lúc nào.
##
## Khuôn T1. Bom **không giết**: nó hất. Axit **không giết ngay**: nó trừ máu, bò ra là ngưng.
##
## ## Khác Magma & Mages ở đâu
##
## Magma là MỘT sân, nham ăn vào từ ngoài, ai cũng dồn về cùng một tâm. Ở đây là SÁU đảo rời, và
## tập đảo an toàn **đổi mỗi chặng** — không có chỗ nào "càng vào giữa càng an toàn". Câu hỏi của
## Magma là "trụ ở giữa thế nào"; câu hỏi ở đây là "nhảy sang đảo nào, và lúc nào".
##
## ## Đảo chìm theo cửa sổ TRƯỢT, không phải chìm dần rồi hết
##
## Mỗi chặng, cửa sổ đảo-chìm trượt đi một bước trên một thứ tự gieo từ hạt giống: một đảo nổi
## lên, đảo kế tiếp chìm xuống. Nên người chơi phải di chuyển LẶP LẠI suốt ván, chứ không phải
## dồn một lần về đảo cuối cùng rồi đứng đó tới hết giờ.
##
## Số đảo chìm cùng lúc thì tăng dần (0 → `TOI_DA_CHIM`), nên chỗ an toàn ít đi theo thời gian.
##
## ## Axit đứng được
##
## Bồn axit có va chạm và chỉ thấp hơn mặt đảo `CAO_DAO` mét — rơi xuống là lội trong axit, mất
## máu, nhảy lên đảo lại được. Bản trước axit là một mặt phẳng trang trí ở `y = -5` và ra khỏi
## đảo là rơi vào hư không, chết ngay: lùi quá đà một bước là hết ván, và không có chỗ nào cho
## "bị bom hất xuống axit rồi bò lên".
##
## ## 0 gói tin
##
## Lịch bom, thứ tự chìm, chặng nào chìm đảo nào — tất cả là hàm thuần của `hat_giong` và
## `gio()`. Người bị nạn tự áp lực đẩy lên mình và tự khai tử, nên không có kết quả nào để chỏi.

## Sáu đảo: số 0 ở giữa, 1..5 rải trên một vành.
const SO_DAO := 6
const SO_VANH := 5
## Bán kính một đảo và bán kính cái vành. Khớp `dao.tscn`.
##
## Hai con số này phải cho KHE nhảy được: khe giữa↔vành là 1,50 m, khe vành↔vành là 3,42 m, còn
## tầm nhảy ngang của `Player` là 4,16 m (cao 1,2 m, trọng lực 20, tốc 6). Nới `BAN_KINH_VANH`
## thì phải kiểm lại cả hai khe.
const BAN_KINH_DAO := 3.0
const BAN_KINH_VANH := 7.5
## Mặt đảo cao hơn mặt axit chừng này. PHẢI nhỏ hơn `jump_height` (1,2) — không thì rơi xuống
## axit là không leo lên được và axit thành bẫy chết.
const CAO_DAO := 0.8

## Nhiều nhất bao nhiêu đảo chìm cùng lúc. `SO_DAO - TOI_DA_CHIM` = số đảo an toàn cuối ván.
const TOI_DA_CHIM := 4
## Giữ nguyên sáu đảo chừng này giây đầu — chừa lúc hiểu luật và chọn chỗ.
const CHO_TRUOC_KHI_CHIM := 8.0
## Mỗi chặng dài bao lâu.
const GIAY_MOI_CHANG := 9.0
## Đảo bị đánh dấu trước khi chìm chừng này giây.
const GIAY_BAO := 3.5

## Mất bao nhiêu máu mỗi giây khi lội trong axit. Máu đầy 100 (đặt trong `.tscn`) nên khoảng
## 5 giây là chết — đủ đau để phải leo lên ngay, nhưng bị hất xuống một cái không phải là xong.
const MAT_MAU_MOI_GIAY := 20.0

## Bom đầu tiên rơi sau chừng này giây, chừa lúc cho người chơi định thần.
const BAT_DAU_NEM := 3.0
## Nghỉ giữa hai quả, lúc đầu và lúc cuối.
##
## Cuối ván 1,0 chứ không 0,5 như bản trước: giờ áp lực chính là đảo chìm, bom chỉ còn là thứ
## đẩy người ta khỏi chỗ tốt. Giữ 0,5 là hai nguồn áp lực chồng lên nhau thành rối.
const NGHI_DAU := 2.3
const NGHI_CUOI := 1.0
## Dày hết cỡ sau chừng này giây.
const GIAY_DAY_HET := 55.0
## Dính nổ thì văng mạnh cỡ nào — ra xa tâm vụ nổ, và hất lên.
const DAY_NGANG := 14.0
const DAY_LEN := 5.0

@export var bom_scene: PackedScene = null
@export var dao_scene: PackedScene = null

@onready var _thanh: ThanhMau = $ThanhMau

## Lịch rơi sinh từ hạt giống: `[{"luc": giây, "cho": Vector3}]`, sắp sẵn theo thời gian.
var _lich: Array = []
## Quả kế tiếp trong `_lich` chưa thả.
var _ke_tiep := 0
var _bom: Array[BomAxit] = []
## instance_id của những quả ĐÃ hất mình rồi. Quầng nổ sống 0,4 giây ~ 24 khung hình; không nhớ
## thì một quả bom cộng dồn 24 lần lực đẩy và bắn người chơi ra khỏi bản đồ.
var _da_dinh: Dictionary = {}

var _dao: Array[Node3D] = []
var _mau_thuong: StandardMaterial3D = null
var _mau_bao: StandardMaterial3D = null
## Bán kính bồn axit, ĐỌC từ mesh chứ không chép tay.
var _ban_kinh_bon := 11.5
## Mặt đảo nằm ở `y` nào trong toạ độ của `san`.
var _mat_dao := 1.0


func _ready() -> void:
	super()
	ten = "ACIDIC ATOLL"
	luat = "WASD chạy · Space nhảy sang đảo khác · đảo đỏ sắp chìm · axit trừ máu"
	giay_van = 70.0
	_mau_thuong = load("res://materials/mat_san_thuong.tres") as StandardMaterial3D
	_mau_bao = load("res://materials/mat_san_canh_bao.tres") as StandardMaterial3D


func _dung_san() -> void:
	_lich = lich_roi(hat_giong)
	_ke_tiep = 0
	_bom.clear()
	_da_dinh.clear()
	_thanh.mo()
	_dao.clear()
	if dao_scene == null:
		push_error("AcidicAtoll: thieu dao_scene (dao.tscn)")
		return

	var bon := san.get_node_or_null("SanTron") as Node3D
	var m := bon.get_node_or_null("Mat") as MeshInstance3D if bon != null else null
	var cyl := m.mesh as CylinderMesh if m != null else null
	if cyl != null:
		_ban_kinh_bon = cyl.top_radius
		_mat_dao = cyl.height * 0.5 + CAO_DAO

	# Dựng sáu đảo bằng code: đổi `SO_VANH` hay `BAN_KINH_VANH` một chỗ là xong, không phải sửa
	# sáu transform bằng tay.
	for i in SO_DAO:
		var d := dao_scene.instantiate() as Node3D
		san.add_child(d)
		var c := cho_dao(i)
		# Tâm đảo đặt sao cho MẶT đảo nằm ở `_mat_dao`.
		d.position = Vector3(c.x, _mat_dao - CAO_DAO * 0.5, c.z)
		_dao.append(d)
	_ve_dao(0.0)


func dung_som() -> void:
	_thanh.dong()
	super()


func _luat_moi_nhip() -> void:
	var t := gio()
	_ve_dao(t)
	while _ke_tiep < _lich.size() and t >= float(_lich[_ke_tiep]["luc"]):
		_tha(_lich[_ke_tiep]["cho"] as Vector3)
		_ke_tiep += 1
	_bom = _bom.filter(func(b: BomAxit) -> bool: return is_instance_valid(b))
	if con_song(NetManager.local_id()):
		_giu_trong_bon()
		_an_mau(t)


## Đảo chìm thì tắt HẲN cả va chạm, không chỉ giấu mặt: giấu mà để nguyên `StaticBody3D` thì
## người chơi đứng trên khoảng không vô hình và không ai hiểu vì sao mình không rơi.
func _ve_dao(t: float) -> void:
	var chim := dao_chim(hat_giong, chang(t))
	var bao := dao_bao(hat_giong, t)
	for i in _dao.size():
		var d := _dao[i]
		var di_chim: bool = chim.has(i)
		d.visible = not di_chim
		var than := d.get_node_or_null("Than") as StaticBody3D
		if than != null:
			than.collision_layer = 0 if di_chim else 1
		if di_chim:
			continue
		var mat := d.get_node_or_null("Mat") as MeshInstance3D
		if mat != null:
			mat.material_override = _mau_bao if bao.has(i) else _mau_thuong


## Kẹp nhân vật CỦA MÁY NÀY trong lòng bồn. Chỉ `is_mine` — kéo người khác là đánh nhau với
## replicator đang gửi vị trí của họ.
func _giu_trong_bon() -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	var l := p.global_position - san.global_position
	var r := Vector2(l.x, l.z)
	var toi_da := _ban_kinh_bon - 0.5
	if r.length() <= toi_da:
		return
	r = r.normalized() * toi_da
	p.global_position = san.global_position + Vector3(r.x, l.y, r.y)


## Lội trong axit thì mất máu.
##
## Điều kiện là "không ở trên đảo nào CÒN NỔI" **và** "đang ở thấp ngang mặt axit". Thiếu điều
## kiện thứ hai thì nhảy qua khe giữa hai đảo cũng bị trừ máu giữa không trung, mà nhảy qua khe
## chính là việc trò này bắt người chơi làm.
func _an_mau(t: float) -> void:
	var p := _nguoi(NetManager.local_id())
	if p == null:
		return
	var l := p.global_position - san.global_position
	if l.y > _mat_dao - 0.3:
		return
	var chim := dao_chim(hat_giong, chang(t))
	var xz := Vector2(l.x, l.z)
	for i in SO_DAO:
		if chim.has(i):
			continue
		var c := cho_dao(i)
		if xz.distance_to(Vector2(c.x, c.z)) <= BAN_KINH_DAO:
			return
	_thanh.tru(MAT_MAU_MOI_GIAY, get_process_delta_time())


## Ghi đè: bom HẤT chứ không giết; chết là do hết máu.
##
## Vẫn gọi `super()` ở cuối: kẹp vị trí chặn được việc đi ra khỏi bồn, nhưng nếu một ngày vật lý
## đẩy ai xuyên qua mặt bồn thì lưới đỡ của lớp cha vẫn phải ở đó.
func _toi_thua() -> bool:
	var p := _nguoi(NetManager.local_id())
	if p != null:
		for b in _bom:
			if not b.dang_no() or _da_dinh.has(b.get_instance_id()):
				continue
			if not b.vung().overlaps_body(p):
				continue
			_da_dinh[b.get_instance_id()] = true
			var ra := p.global_position - b.global_position
			ra.y = 0.0
			# Đứng đúng tâm thì hướng hất là vô định — đẩy đại một phía còn hơn không đẩy.
			if ra.length_squared() < 0.001:
				ra = Vector3.RIGHT
			p.day(ra.normalized() * DAY_NGANG + Vector3.UP * DAY_LEN)
	return _thanh.het() or super()


func _tha(cho: Vector3) -> void:
	if san == null or bom_scene == null:
		return
	var b := bom_scene.instantiate() as BomAxit
	san.add_child(b)
	b.tha(san.global_position + cho)
	_bom.append(b)


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Tâm đảo thứ `i` trong toạ độ phẳng của sân. Đảo 0 ở giữa.
static func cho_dao(i: int) -> Vector3:
	if i <= 0:
		return Vector3.ZERO
	var a := TAU * float(i - 1) / float(SO_VANH)
	return Vector3(cos(a) * BAN_KINH_VANH, 0.0, sin(a) * BAN_KINH_VANH)


## Thứ tự đảo bị chìm, trộn từ hạt giống.
##
## Fisher-Yates với `RandomNumberGenerator` chứ KHÔNG dùng `Array.shuffle()`: `shuffle()` lấy RNG
## toàn cục, mỗi máy một trạng thái khác nhau nên mỗi người sẽ thấy một đảo khác chìm. Cả trò
## dựa vào chỗ này để khỏi phải gửi gói tin nào.
static func thu_tu_chim(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	for i in SO_DAO:
		ds.append(i)
	for i in range(ds.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tam = ds[i]
		ds[i] = ds[j]
		ds[j] = tam
	return ds


## Chặng thứ mấy tại giây `t`. 0 = chưa chìm đảo nào.
static func chang(t: float) -> int:
	if t < CHO_TRUOC_KHI_CHIM:
		return 0
	return 1 + int((t - CHO_TRUOC_KHI_CHIM) / GIAY_MOI_CHANG)


## Chặng kế tiếp bắt đầu ở giây nào.
static func luc_chang_sau(t: float) -> float:
	return CHO_TRUOC_KHI_CHIM + float(chang(t)) * GIAY_MOI_CHANG


## Bao nhiêu đảo chìm cùng lúc ở chặng `k`.
static func so_chim(k: int) -> int:
	return mini(maxi(k, 0), TOI_DA_CHIM)


## Những đảo ĐANG chìm ở chặng `k`.
##
## Cửa sổ TRƯỢT trên `thu_tu_chim()`: bắt đầu ở `k - 1`, dài `so_chim(k)`. Mỗi chặng cửa sổ dịch
## một bước nên có đảo nổi lên trong khi đảo khác chìm xuống — đó là thứ bắt người chơi di chuyển
## lặp lại, thay vì dồn một lần về đảo cuối rồi đứng đó tới hết giờ.
static func dao_chim(giong: int, k: int) -> Array:
	if k <= 0:
		return []
	var tt := thu_tu_chim(giong)
	var ds: Array = []
	for j in so_chim(k):
		ds.append(tt[(k - 1 + j) % SO_DAO])
	return ds


## Những đảo đang bị ĐÁNH DẤU: còn nổi, nhưng sẽ chìm ở chặng sau.
static func dao_bao(giong: int, t: float) -> Array:
	if t < luc_chang_sau(t) - GIAY_BAO:
		return []
	var k := chang(t)
	var nay := dao_chim(giong, k)
	var ds: Array = []
	for i in dao_chim(giong, k + 1):
		if not nay.has(i):
			ds.append(i)
	return ds


## Những đảo còn nổi ở chặng `k`.
static func dao_noi(giong: int, k: int) -> Array:
	var chim := dao_chim(giong, k)
	var ds: Array = []
	for i in SO_DAO:
		if not chim.has(i):
			ds.append(i)
	return ds


## Toàn bộ lịch rơi của một ván, suy ra từ hạt giống. Cùng hạt giống thì cùng kết quả — đó là lý
## do trò này không tốn gói tin nào.
##
## Bom nhắm vào một đảo CÒN NỔI ở đúng giây nó rơi, không nhắm bừa khắp bồn: bom rơi xuống axit
## là bom vô nghĩa, còn bom rơi lên đảo thì đẩy người ta khỏi chỗ tốt — đúng việc của nó.
static func lich_roi(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong + 1            # lệch hạt giống của `thu_tu_chim` để hai thứ không khoá nhau
	var ds: Array = []
	var t := BAT_DAU_NEM
	# 180 giây là trần an toàn: ván dài nhất 70 giây, nhưng sinh dư thì không bao giờ hết bom.
	while t < 180.0:
		var noi := dao_noi(giong, chang(t))
		var i: int = noi[rng.randi_range(0, noi.size() - 1)]
		var c := cho_dao(i)
		var a := rng.randf() * TAU
		# `sqrt` chứ không phải `randf()` thẳng: không có nó thì bom dồn về tâm đảo, vì diện tích
		# một vành tăng theo bán kính mà xác suất lại chia đều theo bán kính.
		var r := sqrt(rng.randf()) * BAN_KINH_DAO
		ds.append({"luc": t, "cho": Vector3(c.x + cos(a) * r, 0.0, c.z + sin(a) * r)})
		t += lerpf(NGHI_DAU, NGHI_CUOI, clampf(t / GIAY_DAY_HET, 0.0, 1.0))
	return ds
