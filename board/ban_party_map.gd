extends Node3D

## Đảo núi lửa quanh bàn (`dao_nui_lua.tscn`). Script chỉ lo môi trường; vật chuyển động dùng
## `VatChuyenDong`. Mesh sinh từ `3d/ban_do/tao_ban_do.py` theo vị trí ô: dời ô thì chạy lại.

var _env_khac: WorldEnvironment = null
var _env_cu: Environment = null

@onready var _moi_truong: WorldEnvironment = $RumbleReefEnvironment


## Scene chính đã có WorldEnvironment thì mượn nó (trả lại khi rời bàn).
func _ready() -> void:
	_env_khac = _tim_env(get_tree().current_scene)
	if _env_khac != null:
		_env_cu = _env_khac.environment
		_env_khac.environment = _moi_truong.environment
		_moi_truong.environment = null


func _exit_tree() -> void:
	if _env_khac != null and is_instance_valid(_env_khac):
		_env_khac.environment = _env_cu


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
