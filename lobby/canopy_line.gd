class_name CanopyLine
extends Path3D

## Canopy Line: tàu chạy vòng trong nhà kính. Không ai lái thì tự chạy đều hết một vòng trong
## `LAP_SECONDS`; ngồi vào ghế lái (`Car/GheLai`) thì người đó điều khiển ga/phanh.
## Đường ray (curve), ray và tà vẹt dựng sẵn trong canopy_line.tscn; sửa đường thì sửa curve
## trong editor rồi dựng lại tà vẹt `Sleepers`.
##
## Mạng: mọi máy chạy cùng một công thức. Người phát (người lái; không có thì master) gửi ảnh
## chụp (vị trí, vận tốc, ga) khi đổi ga và định kỳ để các máy khớp lại; máy khác chỉ chạy tiếp
## từ ảnh gần nhất. Ai được lái do master phân xử, giống ghế bài.
## ⚠️ `Car/GheLai/Hitbox` phải `sync_to_physics = false`: Car (node cha) mới là thứ chạy.

const LAP_SECONDS := 105.0

## m/s.
const TOC_TOI_DA := 8.0
const LUI_TOI_DA := 2.5

## m/s²: tăng ga, đạp phanh (ga ngược chiều xe đang chạy), thả ga, và tự chạy khi không ai lái.
const GIA_TOC := 3.0
const PHANH := 7.0
const MA_SAT := 1.5
const GIA_TOC_TU_CHAY := 0.5

## Giây giữa hai ảnh chụp: lúc có người lái / lúc không ai lái.
const CHU_KY_LAI := 0.2
const CHU_KY_RANH := 2.0

## Lệch hơn chừng này (mét) thì nhảy thẳng tới vị trí người phát; nhỏ hơn thì kéo dần.
const NHAY_LECH := 3.0
const KEO_LECH := 0.35

## Id người đang lái; 0 = không ai. Đọc qua `lai_hop_le()` vì người đó có thể đã thoát phòng.
var lai_boi := 0

## Ga hiện tại: 1 tiến, -1 lùi/phanh, 0 thả.
var ga := 0.0

var _s := 0.0
var _v := 0.0
var _dai := 1.0
var _dem := 0.0

@onready var _xe: PathFollow3D = $Car


func _ready() -> void:
	# Chạy trước người chơi để người ngồi trên xe bám theo vị trí đã cập nhật của cùng khung.
	process_priority = -10
	Fusion.register_broadcast_receiver(self)
	_dai = curve.get_baked_length()
	_v = _toc_tu_chay()
	# Khớp đồng hồ hệ thống để lúc mới vào các máy đã gần cùng một chỗ.
	_s = fposmod(Time.get_unix_time_from_system(), LAP_SECONDS) * _v


func _process(delta: float) -> void:
	_chay(delta)
	_xe.progress = _s
	_phat(delta)


func _toc_tu_chay() -> float:
	return _dai / LAP_SECONDS


## Người lái còn ở trong phòng.
func lai_hop_le() -> bool:
	if lai_boi == 0:
		return false
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == lai_boi:
			return true
	return false


## Cùng một công thức ở mọi máy.
func _chay(dt: float) -> void:
	var dich := _toc_tu_chay()
	var toc := GIA_TOC_TU_CHAY
	if lai_hop_le():
		if ga > 0.0:
			dich = TOC_TOI_DA
			toc = GIA_TOC if _v >= 0.0 else PHANH
		elif ga < 0.0:
			dich = -LUI_TOI_DA
			toc = GIA_TOC if _v <= 0.0 else PHANH
		else:
			dich = 0.0
			toc = MA_SAT
	_v = move_toward(_v, dich, toc * dt)
	_s = fposmod(_s + _v * dt, _dai)


## Người lái gọi mỗi khung với dấu của phím ga; đổi ga thì gửi ảnh chụp ngay.
func dat_ga(moi: float) -> void:
	if moi == ga:
		return
	ga = moi
	_dem = INF


## Người phát ảnh chụp: người lái, không có thì master.
func co_quyen_phat() -> bool:
	if lai_hop_le():
		return lai_boi == NetManager.local_id()
	return NetManager.is_master()


func _phat(dt: float) -> void:
	if Fusion.get_room() == null or not co_quyen_phat():
		return
	_dem += dt
	if _dem < (CHU_KY_LAI if lai_boi != 0 else CHU_KY_RANH):
		return
	_dem = 0.0
	Fusion.rpc(_net_anh, _s, _v, ga, lai_boi)


@rpc("any_peer", "call_local")
func _net_anh(s: float, v: float, g: float, id: int) -> void:
	if co_quyen_phat():
		return
	lai_boi = id
	ga = g
	_v = v
	var lech := fposmod(s - _s + _dai * 0.5, _dai) - _dai * 0.5
	_s = fposmod(_s + (lech if absf(lech) > NHAY_LECH else lech * KEO_LECH), _dai)


## Người chơi máy này xin lái; master phân xử để hai người bấm cùng lúc không cùng lái.
func xin_lai() -> void:
	Fusion.rpc(_net_xin_lai, NetManager.local_id())


func nha_lai() -> void:
	Fusion.rpc(_net_nha, NetManager.local_id())


@rpc("any_peer", "call_local")
func _net_xin_lai(id: int) -> void:
	if not NetManager.is_master() or lai_hop_le():
		return
	Fusion.rpc(_net_lai, id)


@rpc("any_peer", "call_local")
func _net_lai(id: int) -> void:
	lai_boi = id
	ga = 0.0
	_dem = INF


@rpc("any_peer", "call_local")
func _net_nha(id: int) -> void:
	if lai_boi != id:
		return
	lai_boi = 0
	ga = 0.0
	_dem = INF
