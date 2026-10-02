extends MiniGame3D

## TEMPORAL TRAILS — nhìn vệt sáng của mình, nhớ HÌNH của nó, vệt tắt rồi đi lại đúng đường đó.
##
## Khuôn T3. Mỗi vòng có bốn chặng:
##
## ```
## XEM (đứng yên, mọi vệt sáng rực) → MỜ DẦN → ĐI (vệt tắt hẳn, đi theo trí nhớ) → NGHỈ
## ```
##
## Thứ phải nhớ là **hình con đường** (thẳng → cong trái → vòng tròn → chữ S...), không phải chỗ
## mình đứng — đó là chỗ khác với Searing Spotlights, nơi thứ phải nhớ là vị trí của chính mình.
##
## ## Vệt là gì
##
## Mỗi người một đường cong liền màu riêng (`DuongVet.tao`), vẽ thành dải phát sáng trên sàn
## (`VetSang`). Vệt của mọi người hiện cùng lúc và có thể cắt nhau — nhầm nhánh ở chỗ giao là cái
## bẫy chính của trò. Mỗi người xuất phát ở một góc sân khác nhau, nên bám theo người khác là đi
## sai đường ngay từ đầu.
##
## ## Đi đúng đường
##
## Đường hợp lệ rộng `2 × DuongVet.BE_RONG` = 2,5 m quanh vệt đã tắt. Ra ngoài thì mất máu dần
## (`ThanhMau`, cùng hệ máu với Spotlights/Magma) và có chữ cảnh báo — lệch vài chục phân không
## sao, lạc hẳn mới mất máu. Chỉ xét toạ độ NGANG (xz): nhảy không giúp bay tắt qua đâu được, vì
## lúc đang bay vẫn bị đo như lúc đứng.
##
## ## 0 gói tin cho vệt, 1 gói mỗi người mỗi vòng
##
## Vệt và lịch chặng là hàm thuần của `(hạt giống, gio())`, mọi máy tự tính. Máu và tiến độ mỗi
## máy tự đo cho nhân vật của mình (luật chung: nạn nhân tự khai). Hết mỗi vòng, mỗi người gửi
## đúng MỘT gói báo mình đi được bao nhiêu phần vệt.

## Bốn vòng, khó dần: thời gian XEM ngắn lại (độ dài và độ cong nằm trong `DuongVet`).
const XEM := [7.0, 6.0, 5.0, 4.0]
const MO := 1.5
const NGHI := 2.0
## Đi bao lâu: theo chiều dài vệt, chừa dư cho người đang lục trí nhớ. Chạy thẳng 6 m/s; ở đây
## tính 3,5 m/s cộng 4 giây.
const TOC_DI_TINH := 3.5
const DU_DI := 4.0
## Mất máu mỗi giây khi ở ngoài đường hợp lệ. Máu 100 → 4 giây lạc tổng cộng là ra.
const MAT_MAU_MOI_GIAY := 25.0
## Hết giờ đi mà chưa tới cuối vệt thì mất thêm chừng này máu.
const PHAT_KHONG_TOI := 20.0
## Tới cách cuối vệt chừng này mét là tính là về đích.
const VE_DICH := 0.8

enum { PHA_XEM, PHA_MO, PHA_DI, PHA_NGHI, PHA_HET }

@export var vet_scene: PackedScene = null

@onready var _thanh: ThanhMau = $ThanhMau
@onready var _pha_chu: Label = $Lop/Pha
@onready var _canh_bao: Label = $Lop/CanhBao

## Thứ tự người chơi lúc vào ván — quyết định ai xuất phát ở góc sân nào.
var _ds_nguoi: Array = []
## player_id -> VetSang của vòng hiện tại.
var _vet: Dictionary = {}
## Đường của CHÍNH MÌNH ở vòng hiện tại (xz cục bộ trong sân).
var _duong := PackedVector2Array()
var _vong := -1
var _tien := 0.0
var _xong := false
var _da_bao := -1
## player_id -> tổng phần vệt đã đi được qua các vòng. Mọi máy cộng từ RPC; bảng của master là
## bảng chốt.
var _diem: Dictionary = {}


func _ready() -> void:
	super()
	ten = "TEMPORAL TRAILS"
	luat = ("Nhớ HÌNH vệt sáng màu của bạn · vệt tắt thì đi lại đúng đường đó"
			+ " · lạc đường là mất máu")
	giay_van = 0.0                      # ván kết thúc sau vòng cuối, xem `_luat_moi_nhip`


func bat_dau(nguoi_choi: Array, giong: int) -> void:
	_ds_nguoi = nguoi_choi.duplicate()
	super(nguoi_choi, giong)


func _dung_san() -> void:
	_diem.clear()
	for id in _song:
		_diem[int(id)] = 0.0
	_vong = -1
	_da_bao = -1
	_thanh.mo()
	$Lop.visible = true


func dung_som() -> void:
	_thanh.dong()
	$Lop.visible = false
	super()


func _luat_moi_nhip() -> void:
	var l := lich(gio())
	var v: int = l["vong"]
	var pha: int = l["pha"]
	if pha == PHA_HET:
		_hien_vet(0.0)
		if NetManager.is_master():
			_chot_ket_qua()
		return
	if v != _vong:
		_vao_vong(v)
	_hien_vet(1.0 if pha == PHA_XEM else (1.0 - float(l["qua"]) / MO if pha == PHA_MO else 0.0))

	var id := NetManager.local_id()
	var toi := _nguoi(id)
	var song := con_song(id)
	# Đứng yên lúc XEM / MỜ / NGHỈ: đi được lúc vệt còn sáng thì chỉ việc dò theo, không cần nhớ.
	if toi != null and song:
		toi.khoa_di_chuyen = pha != PHA_DI
	_canh_bao.visible = false
	if pha == PHA_DI and song and not _xong and toi != null:
		_di(toi)
	if pha == PHA_NGHI and song and _da_bao != v:
		_da_bao = v
		if not _xong:
			_thanh.tru(PHAT_KHONG_TOI, 1.0)
		var phan := clampf(_tien / maxf(DuongVet.dai(_duong), 0.01), 0.0, 1.0)
		Fusion.rpc(_net_ket_vong, id, v, phan)
	_pha_chu.text = _chu_pha(pha, float(l["con"]))


## Đo người chơi của MÁY NÀY trên đường đã tắt. Chỉ toạ độ ngang: nhảy không né được phép đo.
func _di(toi: Player) -> void:
	var l := toi.global_position - san.global_position
	var r := DuongVet.tien_do(_duong, _tien, Vector2(l.x, l.z))
	_tien = r.x
	if r.y > DuongVet.BE_RONG:
		_thanh.tru(MAT_MAU_MOI_GIAY, get_process_delta_time())
		_canh_bao.visible = true
	if _tien >= DuongVet.dai(_duong) - VE_DICH:
		_xong = true


## Vòng mới: dựng lại vệt của mọi người, đưa nhân vật của máy này về đầu vệt của mình.
func _vao_vong(v: int) -> void:
	_vong = v
	_tien = 0.0
	_xong = false
	for k in _vet:
		if is_instance_valid(_vet[k]):
			_vet[k].queue_free()
	_vet.clear()
	var goc := san.get_node("Vet") as Node3D
	var mau := _mau_rieng()
	for i in _ds_nguoi.size():
		var id := int(_ds_nguoi[i])
		var ds := DuongVet.tao(hat_giong, v, i, _ds_nguoi.size())
		var vs := vet_scene.instantiate() as VetSang
		goc.add_child(vs)
		# Nhích cao một chút theo thứ tự: hai vệt chồng nhau không nhấp nháy giành mặt.
		vs.position.y = 0.003 * i
		vs.dung(ds, mau[i])
		_vet[id] = vs
		if id == NetManager.local_id():
			_duong = ds
	var toi := _nguoi(NetManager.local_id())
	if toi != null and con_song(NetManager.local_id()) and _duong.size() > 1:
		var h := DuongVet.huong_dau(_duong)
		toi.global_position = san.global_position + Vector3(_duong[0].x, 1.0, _duong[0].y)
		toi.velocity = Vector3.ZERO
		toi.rotation.y = atan2(-h.x, -h.y)


func _hien_vet(a: float) -> void:
	for k in _vet:
		if is_instance_valid(_vet[k]):
			(_vet[k] as VetSang).do_sang(a)


## Màu vệt = màu nhân vật đã chọn (`NetManager.PLAYER_COLORS`). Hai người trùng màu thì người sau
## lấy màu kế tiếp còn trống — trùng màu là không ai biết vệt nào của mình. Tính trên `color_index`
## đã replicate, nên mọi máy ra cùng một bảng.
func _mau_rieng() -> Array[Color]:
	var da_dung := {}
	var ds: Array[Color] = []
	for i in _ds_nguoi.size():
		var p := _nguoi(int(_ds_nguoi[i]))
		var ci := p.color_index if p != null else i
		var n := NetManager.PLAYER_COLORS.size()
		for k in n:
			if not da_dung.has((ci + k) % n):
				ci = (ci + k) % n
				break
		da_dung[ci] = true
		ds.append(NetManager.color_for(ci))
	return ds


func _chu_pha(pha: int, con: float) -> String:
	match pha:
		PHA_XEM:
			return "VÒNG %d · NHỚ VỆT MÀU CỦA BẠN · %d" % [_vong + 1, ceili(con)]
		PHA_MO:
			return "VỆT ĐANG TẮT..."
		PHA_DI:
			return ("VỀ ĐÍCH ✓" if _xong else "ĐI THEO TRÍ NHỚ · %d" % ceili(con))
		_:
			return "VỀ ĐÍCH ✓" if _xong else "HẾT GIỜ"


## Mỗi người báo một lần mỗi vòng: đi được bao nhiêu phần vệt của mình.
@rpc("any_peer", "call_local")
func _net_ket_vong(id: int, _v: int, phan: float) -> void:
	if _diem.has(id):
		_diem[id] = float(_diem[id]) + clampf(phan, 0.0, 1.0)


## Ô điểm: tổng phần trăm vệt đã đi được qua các vòng (100 = trọn một vệt).
func diem_cua(id: int) -> float:
	return float(_diem[id]) * 100.0 if _diem.has(id) else NAN


## Ghi đè: hết máu là thua. Vẫn giữ luật rơi khỏi sàn của lớp cha.
func _toi_thua() -> bool:
	return _thanh.het() or super()


## Xếp theo tổng phần vệt đi được; bằng nhau thì ai sống lâu hơn đứng trên.
func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _diem:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool:
		if not is_equal_approx(float(_diem[a]), float(_diem[b])):
			return float(_diem[a]) > float(_diem[b])
		return con_song(a) and not con_song(b))
	Fusion.rpc(_net_xep_hang, xep)


# ───────────────────────── luật: hàm thuần ─────────────────────────

## Thời gian ĐI của vòng `v`.
static func giay_di(v: int) -> float:
	return float(DuongVet.DAI[v]) / TOC_DI_TINH + DU_DI


## Đang ở vòng nào, chặng nào lúc `t`. Trả về `{vong, pha, qua, con}`: `qua` = đã vào chặng bao
## lâu, `con` = chặng còn bao lâu. Mọi máy cùng tính từ `gio()` — không ai phải phát "sang chặng".
static func lich(t: float) -> Dictionary:
	var dau := 0.0
	for v in DuongVet.so_vong():
		var cac := [float(XEM[v]), MO, giay_di(v), NGHI]
		for k in cac.size():
			var d: float = cac[k]
			if t < dau + d:
				return {"vong": v, "pha": k, "qua": t - dau, "con": dau + d - t}
			dau += d
	return {"vong": DuongVet.so_vong() - 1, "pha": PHA_HET, "qua": 0.0, "con": 0.0}
