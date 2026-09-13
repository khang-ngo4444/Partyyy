extends Area3D

## O san sang. CHI la cong tac vat ly — no khong luu trang thai va khong quyet dinh
## khi nao bat dau tran.
##
## O nay ton tai tren MOI may (nam trong lobby.tscn ma may nao cung tu nap). Moi may
## chi phan ung voi NGUOI CHOI CUA CHINH NO, va nguoi do tu bat co is_ready cua minh
## — vi ho so huu object do. Khong co tranh chap quyen so huu nao.

@onready var glow: MeshInstance3D = $Mesh

var _mat := StandardMaterial3D.new()
var _occupied := false


func _ready() -> void:
	_mat.emission_enabled = true
	glow.material_override = _mat
	_set_lit(false)
	# Nguoi choi nam o lop rieng (xem Player.LOP_NGUOI), khong phai lop 1 mac dinh.
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


## Chi la phan hoi cho nguoi dung o may nay. Nguoi khac thay ai san sang qua bien
## is_ready duoc replicate, khong qua mau cua o.
func _set_lit(on: bool) -> void:
	_occupied = on
	_mat.albedo_color = Color("46a758") if on else Color("3a3a42")
	_mat.emission = _mat.albedo_color
	_mat.emission_energy_multiplier = 1.6 if on else 0.25
