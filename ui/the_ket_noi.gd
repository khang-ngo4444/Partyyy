class_name TheKetNoi
extends PanelContainer

## Thẻ trạng thái mạng ở menu chính: tình trạng, ping, khu vực máy chủ, số phòng và người chơi.

enum TrangThai { DANG_KET_NOI, TRUC_TUYEN, MAT_KET_NOI }

const PING_TOT_MS := 100
const PING_VUA_MS := 200
const SO_VACH_TOI_DA := 3
const PING_REFRESH := 1.0
const REGION_SETTING := "fusion/connection/default_region"

const MAU_DANG_KET_NOI := Color("F5B041")
const MAU_VACH_TAT := Color(UIKit.MUC, 0.18)
const BO_GOC_VACH := 3
const DO_NAY_KHI_KET_NOI := 1.5

var _trang_thai := TrangThai.DANG_KET_NOI
var _rooms: Variant = null
var _ping_acc := 0.0

@onready var status_dot: Panel = %StatusDot
@onready var status_title: Label = %StatusTitle
@onready var status_detail: Label = %StatusDetail
@onready var ping_bars: HBoxContainer = %PingBars
@onready var ping_value: Label = %PingValue


## Số vạch sóng theo độ trễ; 0 = chưa đo được.
static func so_vach_ping(ms: int) -> int:
	if ms <= 0:
		return 0
	if ms <= PING_TOT_MS:
		return SO_VACH_TOI_DA
	return 2 if ms <= PING_VUA_MS else 1


static func mau_ping(so_vach: int) -> Color:
	if so_vach >= SO_VACH_TOI_DA:
		return UIKit.LA
	return MAU_DANG_KET_NOI if so_vach == 2 else UIKit.DO


static func mo_ta_phong(rooms: Array) -> String:
	if rooms.is_empty():
		return "Chưa có phòng mở"
	var so_nguoi := 0
	for room in rooms:
		so_nguoi += int(room["players"])
	return "%d phòng mở · %d người" % [rooms.size(), so_nguoi]


func _ready() -> void:
	dang_ket_noi()


func _process(delta: float) -> void:
	if _trang_thai != TrangThai.TRUC_TUYEN or not is_visible_in_tree():
		return
	_ping_acc += delta
	if _ping_acc >= PING_REFRESH:
		_ping_acc = 0.0
		_ve_ping(NetManager.rtt_ms())


func dang_ket_noi() -> void:
	_trang_thai = TrangThai.DANG_KET_NOI
	tooltip_text = ""
	_ve("ĐANG KẾT NỐI", "Máy chủ %s…" % _ten_khu_vuc(), MAU_DANG_KET_NOI)
	_ve_ping(0)


func da_ket_noi() -> void:
	_trang_thai = TrangThai.TRUC_TUYEN
	tooltip_text = ""
	_ve("TRỰC TUYẾN", _chi_tiet_truc_tuyen(), UIKit.LA)
	_ve_ping(NetManager.rtt_ms())
	UINav.nay(status_dot, DO_NAY_KHI_KET_NOI)


func mat_ket_noi(ly_do: String) -> void:
	_trang_thai = TrangThai.MAT_KET_NOI
	tooltip_text = ly_do
	_ve("MẤT KẾT NỐI", "Kiểm tra mạng rồi mở lại game", UIKit.DO)
	_ve_ping(0)


func cap_nhat_phong(rooms: Array) -> void:
	_rooms = rooms
	if _trang_thai == TrangThai.TRUC_TUYEN:
		status_detail.text = _chi_tiet_truc_tuyen()


func _chi_tiet_truc_tuyen() -> String:
	var phong: String = "Đang tải phòng…" if _rooms == null else mo_ta_phong(_rooms)
	return "%s · %s" % [_ten_khu_vuc(), phong]


func _ten_khu_vuc() -> String:
	return String(ProjectSettings.get_setting(REGION_SETTING, "")).capitalize()


func _ve(tieu_de: String, chi_tiet: String, mau: Color) -> void:
	status_title.text = tieu_de
	status_detail.text = chi_tiet
	status_dot.add_theme_stylebox_override("panel", UIKit.hop(mau, 999, 0, 3, 0))


func _ve_ping(ms: int) -> void:
	var so_vach := so_vach_ping(ms)
	ping_value.text = "%d ms" % ms if so_vach > 0 else "— ms"
	var mau := mau_ping(so_vach)
	var vach := ping_bars.get_children()
	for i in vach.size():
		var bat := i < so_vach
		(vach[i] as Panel).add_theme_stylebox_override("panel",
				UIKit.hop(mau if bat else MAU_VACH_TAT, BO_GOC_VACH, 0, 0, 0))
