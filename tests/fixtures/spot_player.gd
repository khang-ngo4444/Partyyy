extends Player
var test_id := -1

## Avatar cục bộ cho kiểm tra ánh sáng, không kết nối Photon hoặc nhận input.
func _ready() -> void:
	add_to_group("players")
	is_mine = player_id() == NetManager.local_id()
	name_tag.visible = not is_mine
	var model: Node3D = load("res://player/characters/Mage.tscn").instantiate()
	model_root.add_child(model)
	model.get_node("Model/PartyAnimationPlayer").play("idle")
	set_physics_process(false)
	set_process(false)

func player_id() -> int:
	return NetManager.local_id() if test_id < 0 else test_id
