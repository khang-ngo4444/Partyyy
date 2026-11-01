extends Node3D

## Đảo núi lửa quanh bàn (`dao_nui_lua.tscn`). Script lo môi trường và mức đồ hoạ; vật chuyển động
## dùng `VatChuyenDong`. Mesh sinh từ `3d/ban_do/tao_ban_do.py` theo vị trí ô: dời ô thì chạy lại.
## Node thuộc group `chi_tiet_cao` (cỏ, tàu xa, bướm, cua...) bị ẩn ở mức MƯỢT.

const NHOM_CHI_TIET_CAO := &"chi_tiet_cao"

var _env_khac: WorldEnvironment = null
var _env_cu: Environment = null
var _env: Environment = null
var _hat: Array[GPUParticles3D] = []

@onready var _moi_truong: WorldEnvironment = $RumbleReefEnvironment
@onready var _mat_troi: DirectionalLight3D = $MatTroi
@onready var _hieu_nang: Node = get_node("/root/PerformanceManager")


## Scene chính đã có WorldEnvironment thì mượn nó (trả lại khi rời bàn).
func _ready() -> void:
	_env = _moi_truong.environment
	_env_khac = _tim_env(get_tree().current_scene)
	if _env_khac != null:
		_env_cu = _env_khac.environment
		_env_khac.environment = _env
		_moi_truong.environment = null
	_hat.assign(find_children("*", "GPUParticles3D", true, false))
	_hieu_nang.connect("graphics_mode_changed", _ap_chat_luong)
	_ap_chat_luong(int(_hieu_nang.get("muc_hieu_luc")))


func _exit_tree() -> void:
	if _env_khac != null and is_instance_valid(_env_khac):
		_env_khac.environment = _env_cu


func _ap_chat_luong(_mode: int) -> void:
	var ts: Dictionary = _hieu_nang.call("thong_so")
	_env.ssao_enabled = ts["ssao"]
	_env.glow_enabled = ts["glow"]
	_mat_troi.directional_shadow_max_distance = ts["xa_bong"]
	_mat_troi.directional_shadow_mode = ts["che_do_bong"]
	for vat: Node in get_tree().get_nodes_in_group(NHOM_CHI_TIET_CAO):
		if is_ancestor_of(vat):
			vat.set("visible", ts["chi_tiet_cao"])
	for hat in _hat:
		hat.amount_ratio = ts["ti_le_hat"]


func _tim_env(n: Node) -> WorldEnvironment:
	if n == null or n == self:
		return null
	if n is WorldEnvironment:
		return n as WorldEnvironment
	for c in n.get_children():
		var thay := _tim_env(c)
		if thay != null:
			return thay
	return null
