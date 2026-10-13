extends MiniGame3D

func network_parameters() -> Dictionary:
	return {"objectives": true}


func initial_shared_state(_ids: Array, _seed: int) -> Dictionary:
	return {}


func advance_shared_rules(_snapshot: Dictionary, _elapsed: float) -> void:
	pass


func handle_shared_action(_snapshot: Dictionary, _id: int, _action: String, _payload: Array, _elapsed: float) -> bool:
	return false


func shared_ranking(snapshot: Dictionary) -> Array:
	return snapshot.ids.duplicate()


func _toi_thua() -> bool:
	return false


func _prepare_shared_owner(player: Player) -> void:
	var entered := player.che_do_san
	super(player)
	if not entered and player.sync.has_authority():
		var ids: Array = shared_snapshot.ids
		player.global_position = san.global_position + _cho_vao(maxi(ids.find(player.player_id()), 0), ids.size()) + Vector3.UP
		player.velocity = Vector3.ZERO


func _present_shared_players() -> void:
	super()
	if san != null:
		san.get_node("HUD").visible = gio() >= 0 and _chay


func request_action(action: String, payload: Array = []) -> void:
	if shared_session != null and _chay and gio() >= 0:
		shared_session.request_action(action, payload)
