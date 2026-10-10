extends Area3D

## Ô sẵn sàng: công tắc vật lý, mỗi máy chỉ bật `is_ready` cho người chơi của chính nó.

var _mat := StandardMaterial3D.new()
var _occupied := false

@onready var glow: MeshInstance3D = $Mesh


func _ready() -> void:
	_mat.emission_enabled = true
	glow.material_override = _mat
	_set_lit(false)
	# Người chơi nằm lớp riêng (Player.LOP_NGUOI).
	collision_mask = Player.LOP_NGUOI
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if not _is_local_player(body):
		return
	body.is_ready = true
	_set_lit(true)


func _on_exit(body: Node3D) -> void:
	if not _is_local_player(body):
		return
	body.is_ready = false
	_set_lit(false)


func _is_local_player(body: Node3D) -> bool:
	return body.is_in_group("players") and body.is_mine


## Phản hồi tại chỗ; người khác thấy qua `is_ready` đã replicate.
func _set_lit(on: bool) -> void:
	_occupied = on
	_mat.albedo_color = Color("46a758") if on else Color("3a3a42")
	_mat.emission = _mat.albedo_color
	_mat.emission_energy_multiplier = 1.6 if on else 0.25
