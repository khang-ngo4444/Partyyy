class_name ManChuyen
extends CanvasLayer

## ManChuyen (autoload tên "ManChuyenHook"): màn chuyển phủ toàn cửa sổ, chỉ để trình bày.
## `await ManChuyen.che(...)` chờ che kín rồi mới dựng cảnh; `ManChuyen.mo()` lộ cảnh mới.
## Gọi qua hàm static; khi autoload chưa chạy (test trong editor) thì bỏ qua ngay.

const GIAY_CHE := 0.45
const GIAY_LO := 0.45
## Che kín tối thiểu bao lâu: đủ đọc chữ và giấu khựng hình lúc dựng scene.
const GIAY_GIU := 0.6
## Lưới an toàn: mạng rớt mà không ai gọi `mo` thì cũng không kẹt màn.
const GIAY_TOI_DA := 15.0
const GIAY_RAT_NGAN := 0.01
const GIAY_NHIP_CHAM := 0.28
const DO_NAY_CHAM := -10.0

enum Pha { MO, DANG_CHE, DA_CHE, DANG_LO }

signal da_che

static var _ban: ManChuyen = null

var _pha := Pha.MO
var _tween: Tween = null
var _tween_cham: Tween = null
var _luc_che_xong := 0.0
## Tăng mỗi lần có yêu cầu che mới; lịch lộ màn và lưới an toàn cũ tự huỷ khi lệch phiên.
var _phien := 0
var _muon_lo := false

@onready var _nen: ColorRect = $Nen
@onready var _noi_dung: Control = $NoiDung
@onready var _the: Control = %The
@onready var _tieu_de: Label = %TieuDe
@onready var _phu: Label = %Phu
@onready var _cham: Control = %Cham


func _ready() -> void:
	_ban = self
	visible = false
	_noi_dung.visible = false
	_dat_tien_do(0.0)


func _exit_tree() -> void:
	if _ban == self:
		_ban = null


## Che màn có hiệu ứng; đã che rồi thì chỉ đổi chữ.
static func che(tieu_de: String, phu := "") -> void:
	if _ban != null:
		await _ban._che(tieu_de, phu)


## Che ngay trong khung này, dùng khi sắp dựng scene nặng mà chưa kịp diễn hiệu ứng.
static func che_ngay(tieu_de: String, phu := "") -> void:
	if _ban != null:
		_ban._che_ngay(tieu_de, phu)


## Lộ cảnh sau khi đã che đủ `GIAY_GIU`; đang che dở thì đợi che xong.
static func mo() -> void:
	if _ban != null:
		_ban._yeu_cau_lo()


static func dang_phu() -> bool:
	return _ban != null and _ban._pha != Pha.MO


func _che(tieu_de: String, phu: String) -> void:
	_nhan_yeu_cau_che(tieu_de, phu)
	if _pha == Pha.DA_CHE:
		return
	if _pha != Pha.DANG_CHE:
		var dau := 2.0 - _tien_do() if _pha == Pha.DANG_LO else 0.0
		_bat_dau_che(dau)
	await da_che


func _che_ngay(tieu_de: String, phu: String) -> void:
	_nhan_yeu_cau_che(tieu_de, phu)
	if _pha == Pha.DA_CHE:
		return
	var dang_cho := _pha == Pha.DANG_CHE
	_huy_tween()
	visible = true
	if not dang_cho:
		AmThanh.phat(BangAmThanh.SFX_CHUYEN_CANH)
	_xong_che()


func _nhan_yeu_cau_che(tieu_de: String, phu: String) -> void:
	_tieu_de.text = tieu_de
	_phu.text = phu
	_phu.visible = not phu.is_empty()
	_phien += 1
	_muon_lo = false
	_hen_luoi_an_toan(_phien)


func _hen_luoi_an_toan(phien: int) -> void:
	await get_tree().create_timer(GIAY_TOI_DA, true).timeout
	if phien == _phien and _pha != Pha.MO:
		push_warning("ManChuyen: quá %.0f giây chưa ai mở màn" % GIAY_TOI_DA)
		_yeu_cau_lo()


func _bat_dau_che(dau: float) -> void:
	_huy_tween()
	_pha = Pha.DANG_CHE
	visible = true
	_an_noi_dung()
	AmThanh.phat(BangAmThanh.SFX_CHUYEN_CANH)
	_dat_tien_do(dau)
	_tween = create_tween()
	_tween.tween_method(_dat_tien_do, dau, 1.0, _giay(GIAY_CHE))
	_tween.tween_callback(_xong_che)


func _xong_che() -> void:
	_pha = Pha.DA_CHE
	_dat_tien_do(1.0)
	_luc_che_xong = Time.get_ticks_msec() / 1000.0
	_hien_noi_dung()
	da_che.emit()
	if _muon_lo:
		_yeu_cau_lo()


func _yeu_cau_lo() -> void:
	if _pha == Pha.MO or _pha == Pha.DANG_LO:
		return
	_muon_lo = true
	if _pha == Pha.DA_CHE:
		_lo_sau_khi_giu(_phien)


func _lo_sau_khi_giu(phien: int) -> void:
	var con_lai := GIAY_GIU - (Time.get_ticks_msec() / 1000.0 - _luc_che_xong)
	if con_lai > 0.0:
		await get_tree().create_timer(_giay(con_lai), true).timeout
	if phien != _phien or _pha != Pha.DA_CHE:
		return
	_pha = Pha.DANG_LO
	_muon_lo = false
	_an_noi_dung()
	_huy_tween()
	_tween = create_tween()
	_tween.tween_method(_dat_tien_do, 1.0, 2.0, _giay(GIAY_LO))
	_tween.tween_callback(_xong_lo)


func _xong_lo() -> void:
	_pha = Pha.MO
	visible = false
	_dat_tien_do(0.0)


func _hien_noi_dung() -> void:
	_noi_dung.visible = true
	UINav.dap(_the)
	if _tween_cham != null:
		_tween_cham.kill()
	_tween_cham = null
	if UINav.giam_chuyen_dong:
		return
	_tween_cham = create_tween().set_loops()
	for cham: Control in _cham.get_children():
		UINav._chuan_bi(cham)
		_tween_cham.tween_property(cham, "offset_transform_position", Vector2(0, DO_NAY_CHAM), GIAY_NHIP_CHAM) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween_cham.tween_property(cham, "offset_transform_position", Vector2.ZERO, GIAY_NHIP_CHAM) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _an_noi_dung() -> void:
	_noi_dung.visible = false
	if _tween_cham != null:
		_tween_cham.kill()
		_tween_cham = null


func _huy_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _dat_tien_do(gia_tri: float) -> void:
	(_nen.material as ShaderMaterial).set_shader_parameter("tien_do", gia_tri)


func _tien_do() -> float:
	return float((_nen.material as ShaderMaterial).get_shader_parameter("tien_do"))


## Giảm chuyển động thì đổi cảnh gần như tức thì.
func _giay(giay: float) -> float:
	return GIAY_RAT_NGAN if UINav.giam_chuyen_dong else giay
