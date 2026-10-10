extends Node3D

## Quần đảo trang trí quanh bàn (`ban_party_map.tscn`). Script chỉ lo chuyển động và môi trường.
## Vật chuyển động theo group, thông số ở metadata của node:
##   ban_do_xoay: toc_xoay · ban_do_nhap_nho: y_goc, toc, pha, bien_do
##   ban_do_bay_vong: ban_kinh, y_goc, toc, pha · ban_do_troi: toc
## Lối gỗ/chân ô đặt theo vị trí ô lúc dựng — dời ô thì kéo chúng theo.

const MEP_TROI := 125.0

var _thoi_gian := 0.0
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


func _process(delta: float) -> void:
	_thoi_gian += delta
	var t := _thoi_gian
	for n: Node3D in get_tree().get_nodes_in_group("ban_do_xoay"):
		n.rotation.y += delta * float(n.get_meta("toc_xoay", 0.3))
	for n: Node3D in get_tree().get_nodes_in_group("ban_do_nhap_nho"):
		var pha := float(n.get_meta("pha", 0.0))
		n.position.y = float(n.get_meta("y_goc", 0.0)) \
				+ sin(t * float(n.get_meta("toc", 1.0)) + pha) * float(n.get_meta("bien_do", 0.2))
		n.rotation.z = sin(t * 0.65 + pha) * 0.04
	for n: Node3D in get_tree().get_nodes_in_group("ban_do_bay_vong"):
		var a := float(n.get_meta("pha", 0.0)) + t * float(n.get_meta("toc", 0.1))
		var r := float(n.get_meta("ban_kinh", 10.0))
		n.position = Vector3(cos(a) * r, float(n.get_meta("y_goc", 0.0)) + sin(a * 2.0) * 0.2,
				sin(a) * r)
		n.rotation.y = -a + PI * 0.5
	for n: Node3D in get_tree().get_nodes_in_group("ban_do_troi"):
		n.position.x += delta * float(n.get_meta("toc", 0.5))
		if n.position.x > MEP_TROI:
			n.position.x = -MEP_TROI


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
