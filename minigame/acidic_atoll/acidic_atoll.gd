extends MiniGame3D

## ACIDIC ATOLL — đảo nhỏ giữa biển axit, bom rơi không ngớt. Trụ lâu hơn thì hạng cao hơn.
##
## Khuôn T1 thứ ba. Bom **không giết**: nó hất. Chết là do văng xuống axit.
##
## ## 0 gói tin — guide ghi "mỗi bom rơi gửi 1 gói tin"
##
## Không cần. Lịch rơi (lúc nào, chỗ nào) sinh ra từ `hat_giong` ngay ở `_dung_san()`, mà hạt
## giống thì mọi máy đã có sẵn từ lúc vào ván. Cùng hạt giống → cùng danh sách → mọi máy thấy
## đúng những quả bom đó ở đúng những chỗ đó. Một ván 70 giây có khoảng 50 quả bom; gửi tin thì
## là 50 gói, ở đây là 0.
##
## Lệch đồng hồ giữa các máy vài chục ms không sinh ra bất đồng: **người bị nạn tự áp lực đẩy
## lên chính mình và tự khai tử**, nên không có kết quả nào để chỏi nhau.
##
## ## Vì sao bom rơi dày dần
##
## Đây là thứ bảo đảm ván kết thúc. Sàn không co, người chơi giỏi có thể né mãi — cho tới lúc
## không còn chỗ trống nào để né vào.

## Bom đầu tiên rơi sau chừng này giây, chừa lúc cho người chơi định thần.
const BAT_DAU_NEM := 3.0
## Nghỉ giữa hai quả, lúc đầu và lúc cuối.
const NGHI_DAU := 2.3
const NGHI_CUOI := 0.5
## Dày hết cỡ sau chừng này giây.
const GIAY_DAY_HET := 55.0
## Bom rơi trong vòng bán kính này quanh tâm đảo. Đảo rộng 11,5 m.
const BAN_KINH_NEM := 10.5
## Dính nổ thì văng mạnh cỡ nào — ra xa tâm vụ nổ, và hất lên.
const DAY_NGANG := 14.0
const DAY_LEN := 5.0

@export var bom_scene: PackedScene = null

## Lịch rơi sinh từ hạt giống: `[{"luc": giây, "cho": Vector3}]`, sắp sẵn theo thời gian.
var _lich: Array = []
## Quả kế tiếp trong `_lich` chưa thả.
var _ke_tiep := 0
var _bom: Array[BomAxit] = []
## instance_id của những quả ĐÃ hất mình rồi. Quầng nổ sống 0,4 giây ~ 24 khung hình; không
## nhớ thì một quả bom cộng dồn 24 lần lực đẩy và bắn người chơi ra khỏi bản đồ.
var _da_dinh: Dictionary = {}


func _ready() -> void:
	super()
	ten = "ACIDIC ATOLL"
	luat = "WASD chạy · tránh vòng đỏ · đừng rơi xuống axit"
	giay_van = 70.0


func _dung_san() -> void:
	_lich = lich_roi(hat_giong)
	_ke_tiep = 0
	_bom.clear()
	_da_dinh.clear()


func _luat_moi_nhip() -> void:
	var t := gio()
	while _ke_tiep < _lich.size() and t >= float(_lich[_ke_tiep]["luc"]):
		_tha(_lich[_ke_tiep]["cho"] as Vector3)
		_ke_tiep += 1
	_bom = _bom.filter(func(b: BomAxit) -> bool: return is_instance_valid(b))


## Ghi đè: giữ nguyên luật rơi khỏi đảo của lớp cha, thêm sức nổ.
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
	return super()


func _tha(cho: Vector3) -> void:
	if san == null or bom_scene == null:
		return
	var b := bom_scene.instantiate() as BomAxit
	san.add_child(b)
	b.tha(san.global_position + cho)
	_bom.append(b)


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Toàn bộ lịch rơi của một ván, suy ra từ hạt giống. Cùng hạt giống thì cùng kết quả — đó là
## lý do trò này không tốn gói tin nào.
static func lich_roi(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	var t := BAT_DAU_NEM
	# 180 giây là trần an toàn: ván dài nhất 70 giây, nhưng sinh dư thì không bao giờ hết bom.
	while t < 180.0:
		var a := rng.randf() * TAU
		# `sqrt` chứ không phải `randf()` thẳng: không có nó thì bom dồn về tâm đảo, vì diện
		# tích một vành tăng theo bán kính mà xác suất lại chia đều theo bán kính.
		var r := sqrt(rng.randf()) * BAN_KINH_NEM
		ds.append({"luc": t, "cho": Vector3(cos(a) * r, 0.0, sin(a) * r)})
		t += lerpf(NGHI_DAU, NGHI_CUOI, clampf(t / GIAY_DAY_HET, 0.0, 1.0))
	return ds
