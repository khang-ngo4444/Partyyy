extends "res://minigame/machine_playground/objective_game.gd"

const Rules = preload("res://minigame/machine_playground/wave_rules.gd")
const SHELTER_DISTANCE := 4.2
const PUSH_STRENGTH := 8.0
var _seen_event := 0


func initial_shared_state(ids: Array, _seed: int) -> Dictionary:
	return Rules.initial(ids)


func _cho_vao(index: int, total: int) -> Vector3:
	var angle := TAU * index / maxi(total, 1)
	return Vector3(cos(angle), 0, sin(angle)) * 4.5


func _luat_moi_nhip() -> void:
	var player: Player = _nguoi(NetManager.local_id())
	if player == null:
		return
	var local := player.global_position - san.global_position
	var land: CSGPolygon3D = san.get_node("Land")
	var point := Vector2(local.x, local.z)
	if not Geometry2D.is_point_in_polygon(point, land.polygon) or local.y < -2:
		player.global_position = san.global_position + _cho_vao(
			maxi(shared_snapshot.ids.find(player.player_id()), 0), shared_snapshot.ids.size()) + Vector3.UP
		player.velocity = Vector3.ZERO


func _present_shared_players() -> void:
	super()
	if san == null:
		return
	var sample := Rules.sample(hat_giong, gio())
	var direction: Vector2 = sample.direction
	var wave: Node3D = san.get_node("Wave")
	wave.position = Vector3(direction.x, 0, direction.y) * float(sample.front)
	wave.rotation.y = atan2(direction.x, direction.y)
	wave.visible = bool(sample.active) and _chay and gio() >= 0
	var covers := san.get_node("Shelters").get_children()
	var rocks := san.get_node("Rocks").get_children()
	var index := 0
	for rock: Node3D in rocks:
		if rock is StaticBody3D:
			continue
		var cover: MeshInstance3D = covers[index]
		cover.position = rock.position + Vector3(direction.x, 0, direction.y) * 3
		cover.position.y = 0.025
		cover.rotation.y = atan2(direction.x, direction.y)
		cover.visible = bool(sample.warning) and gio() >= 0 and _chay
		index += 1
	var key := str(NetManager.local_id())
	var state: Dictionary = shared_snapshot.objective
	var direction_name := _direction_name(direction)
	san.get_node("HUD/Progress").text = "Sóng %d/6 · %s · %d điểm" % [
		int(sample.cycle) + 1, direction_name, int(state.score.get(key, 0))]
	_consume_event(state)


func _direction_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "→" if direction.x > 0 else "←"
	return "↓" if direction.y > 0 else "↑"


func _consume_event(state: Dictionary) -> void:
	var event: Dictionary = state.events.get(str(NetManager.local_id()), {})
	var serial := int(event.get("serial", 0))
	if serial <= _seen_event:
		return
	_seen_event = serial
	var player: Player = _nguoi(NetManager.local_id())
	if player == null or gio() - float(event.time) > 2:
		return
	if event.kind == "wash":
		player.global_position = san.global_position + _cho_vao(
			maxi(shared_snapshot.ids.find(player.player_id()), 0), shared_snapshot.ids.size()) + Vector3.UP
		player.velocity = Vector3.ZERO
	else:
		var direction := Vector3(float(event.direction[0]), 0, float(event.direction[1]))
		player.day(direction * PUSH_STRENGTH + Vector3.UP * 2)


func sheltered(position: Vector3, direction: Vector2) -> bool:
	var origin := position + Vector3.UP
	var incoming := Vector3(direction.x, 0, direction.y)
	var ray := PhysicsRayQueryParameters3D.create(origin,
		origin - incoming * SHELTER_DISTANCE, Rules.ROCK_LAYER)
	return not san.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func advance_shared_rules(snapshot: Dictionary, elapsed: float) -> void:
	var sample := Rules.sample(int(snapshot.seed), elapsed)
	var cycle := int(sample.cycle)
	var direction: Vector2 = sample.direction
	var front := float(sample.front)
	# Resolve a swept interval once, including a tick that crosses the end of a wave.
	if front > -Rules.EXTENT:
		for id: Variant in snapshot.ids:
			if float(snapshot.alive[str(int(id))]) >= 0:
				continue
			var player: Player = _nguoi(int(id))
			if player == null or absf(player.global_position.y - san.global_position.y) > 5:
				continue
			var position := player.global_position - san.global_position
			var projection := Vector2(position.x, position.z).dot(direction)
			if projection <= front:
				Rules.resolve(snapshot.objective, int(id), cycle,
					sheltered(player.global_position, direction), elapsed)


func handle_shared_action(snapshot: Dictionary, id: int, action: String, _payload: Array, elapsed: float) -> bool:
	var key := str(id)
	if action != "push" or elapsed < float(snapshot.objective.cooldown.get(key, -1)):
		return false
	var source: Player = _nguoi(id)
	if source == null or absf(source.global_position.y - san.global_position.y) > 5:
		return false
	var target: Player = null
	var nearest := Rules.PUSH_RADIUS
	var forward := -source.global_basis.z
	for candidate_id: Variant in snapshot.ids:
		if int(candidate_id) == id or float(snapshot.alive[str(int(candidate_id))]) >= 0:
			continue
		var candidate: Player = _nguoi(int(candidate_id))
		if candidate == null:
			continue
		var delta := candidate.global_position - source.global_position
		delta.y = 0
		if delta.length() < 0.01 or delta.length() > nearest or forward.dot(delta.normalized()) < 0.2:
			continue
		var ray := PhysicsRayQueryParameters3D.create(source.global_position + Vector3.UP,
			candidate.global_position + Vector3.UP, 1)
		if not san.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		nearest = delta.length()
		target = candidate
	if target == null:
		return false
	var direction := target.global_position - source.global_position
	Rules.event(snapshot.objective, target.player_id(), "push", elapsed,
		Vector2(direction.x, direction.z).normalized())
	snapshot.objective.cooldown[key] = elapsed + Rules.PUSH_COOLDOWN
	return true


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		request_action("push")


func shared_ranking(snapshot: Dictionary) -> Array:
	return Rules.ranking(snapshot.objective, snapshot.ids, snapshot.alive)


func diem_cua(id: int) -> float:
	return float(shared_snapshot.get("objective", {}).get("score", {}).get(str(id), 0))


func chu_diem(id: int) -> String:
	return "%d/6" % int(diem_cua(id))
