class_name AmThanh
extends Node

## AmThanh (autoload tên "AmThanhHook"): nhạc nền chuyển mượt + bể SFX không định vị.
## Gọi qua hàm static; khi autoload chưa chạy (test trong editor) thì lặng lẽ bỏ qua.

const BUS_MASTER := &"Master"
const BUS_NHAC := &"Nhac"
const BUS_SFX := &"SFX"
## Loa tháp đồng hồ ở sảnh: tắt tiếng lúc có nhạc bàn/minigame, bài vẫn chạy để không lệch các máy.
const BUS_LOA_SANH := &"LoaSanh"

const GIAY_CHUYEN_NHAC := 0.6
## Cùng một SFX gọi sát nhau (nhiều ô sập một lúc) chỉ kêu một lần.
const GIAY_CHONG_LAP_SFX := 0.05
const DO_LECH_CAO_DO := 0.04

static var _ban: AmThanh = null
static var _master_ve_khong := false
static var _tat_khi_roi_cua_so := true
static var _dang_roi_cua_so := false

var _khoa_nhac := ""
var _sfx_da_nap: Dictionary = {}  # StringName -> AudioStream (null = không có file)
var _sfx_luc_phat: Dictionary = {}  # StringName -> giây
var _tween_nhac: Tween = null

@onready var _nhac_chinh: AudioStreamPlayer = $NhacA
@onready var _nhac_phu: AudioStreamPlayer = $NhacB
@onready var _be_sfx: Array[Node] = $Sfx.get_children()


func _ready() -> void:
	_ban = self
	_nhac_chinh.bus = BUS_NHAC
	_nhac_phu.bus = BUS_NHAC
	for loa: AudioStreamPlayer in _be_sfx:
		loa.bus = BUS_SFX
	get_tree().node_added.connect(_dua_vao_bus_sfx)


func _exit_tree() -> void:
	if _ban == self:
		_ban = null


## Gọi mỗi khung được: đổi khóa mới chuyển bài. Khóa lấy từ `BangAmThanh.khoa_nhac`.
static func dat_nhac(khoa: String) -> void:
	if _ban != null and khoa != _ban._khoa_nhac:
		_ban._chuyen_nhac(khoa)


static func phat(ten: StringName) -> void:
	if _ban != null:
		_ban._phat_sfx(ten)


## Âm lượng 0–100 của một bus (thanh trượt trong Cài đặt).
static func dat_am_luong(bus: StringName, phan_tram: float) -> void:
	var chi_so := AudioServer.get_bus_index(bus)
	if chi_so < 0:
		push_warning("AmThanh: không có bus %s" % bus)
		return
	AudioServer.set_bus_volume_db(chi_so, linear_to_db(phan_tram / 100.0) if phan_tram > 0.0 else -80.0)
	if bus == BUS_MASTER:
		_master_ve_khong = phan_tram <= 0.0
		_ap_tat_master()
	else:
		AudioServer.set_bus_mute(chi_so, phan_tram <= 0.0)


## Tùy chọn trong Cài đặt: rời cửa sổ game thì tắt toàn bộ âm thanh.
static func dat_tat_khi_roi_cua_so(bat: bool) -> void:
	_tat_khi_roi_cua_so = bat
	_ap_tat_master()


static func _ap_tat_master() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MASTER),
			BangAmThanh.tat_master(_master_ve_khong, _tat_khi_roi_cua_so, _dang_roi_cua_so))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_dang_roi_cua_so = what == NOTIFICATION_APPLICATION_FOCUS_OUT
		_ap_tat_master()


## Tiếng đặt sẵn trong scene (bom, sảnh...) mặc định ở Master: gom về SFX để theo thanh trượt.
func _dua_vao_bus_sfx(nut: Node) -> void:
	var la_loa := nut is AudioStreamPlayer or nut is AudioStreamPlayer2D or nut is AudioStreamPlayer3D
	if la_loa and nut.get("bus") == BUS_MASTER:
		nut.set("bus", BUS_SFX)


func _chuyen_nhac(khoa: String) -> void:
	_khoa_nhac = khoa
	var loa_sanh := AudioServer.get_bus_index(BUS_LOA_SANH)
	if loa_sanh >= 0:
		AudioServer.set_bus_mute(loa_sanh, not khoa.is_empty())
	if _tween_nhac != null:
		_tween_nhac.kill()
	var loa_cu := _nhac_chinh
	_nhac_chinh = _nhac_phu
	_nhac_phu = loa_cu
	_tween_nhac = create_tween().set_parallel()
	_tween_nhac.tween_property(loa_cu, "volume_linear", 0.0, GIAY_CHUYEN_NHAC)
	var bai := _nap_nhac(khoa)
	if bai == null:
		_nhac_chinh.stop()
	else:
		_nhac_chinh.stream = bai
		_nhac_chinh.volume_linear = 0.0
		_nhac_chinh.play()
		_tween_nhac.tween_property(_nhac_chinh, "volume_linear", 1.0, GIAY_CHUYEN_NHAC)
	_tween_nhac.chain().tween_callback(loa_cu.stop)


func _nap_nhac(khoa: String) -> AudioStream:
	if khoa.is_empty():
		return null
	var duong_dan := BangAmThanh.tim_file(BangAmThanh.ung_vien_nhac(khoa))
	if duong_dan.is_empty():
		push_warning("AmThanh: không có file nhạc cho %s" % khoa)
		return null
	var bai := load(duong_dan) as AudioStream
	if bai != null:
		_dat_lap(bai, BangAmThanh.co_lap(khoa))
	return bai


## Đặt lặp bằng code để người thay file không phải chỉnh import.
static func _dat_lap(bai: AudioStream, lap: bool) -> void:
	if bai is AudioStreamOggVorbis or bai is AudioStreamMP3:
		bai.set("loop", lap)
	elif bai is AudioStreamWAV:
		var wav := bai as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if lap else AudioStreamWAV.LOOP_DISABLED
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)


func _phat_sfx(ten: StringName) -> void:
	var bay_gio := Time.get_ticks_msec() / 1000.0
	if bay_gio - float(_sfx_luc_phat.get(ten, -INF)) < GIAY_CHONG_LAP_SFX:
		return
	var tieng := _nap_sfx(ten)
	if tieng == null:
		return
	_sfx_luc_phat[ten] = bay_gio
	var loa := _loa_sfx_ranh()
	loa.stream = tieng
	loa.pitch_scale = randf_range(1.0 - DO_LECH_CAO_DO, 1.0 + DO_LECH_CAO_DO)
	loa.play()


func _nap_sfx(ten: StringName) -> AudioStream:
	if not _sfx_da_nap.has(ten):
		var duong_dan := BangAmThanh.tim_file(BangAmThanh.ung_vien_sfx(ten))
		if duong_dan.is_empty():
			push_warning("AmThanh: không có file SFX %s" % ten)
		_sfx_da_nap[ten] = null if duong_dan.is_empty() else load(duong_dan)
	return _sfx_da_nap[ten]


## Hết loa rảnh thì cướp loa đầu bể.
func _loa_sfx_ranh() -> AudioStreamPlayer:
	for loa: AudioStreamPlayer in _be_sfx:
		if not loa.playing:
			return loa
	return _be_sfx[0]
