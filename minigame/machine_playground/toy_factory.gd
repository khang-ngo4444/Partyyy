extends "res://minigame/machine_playground/objective_game.gd"

const Rules = preload("res://minigame/machine_playground/factory_rules.gd")
const PART_SCENES := [
	preload("res://asset/cartoon_props/water_gun/body.tscn"),
	preload("res://asset/cartoon_props/water_gun/tank.tscn"),
	preload("res://asset/cartoon_props/water_gun/pump.tscn"),
	preload("res://asset/cartoon_props/water_gun/barrel.tscn"),
	preload("res://asset/cartoon_props/water_gun/nozzle.tscn")]
const BENCH_SCENE = preload("res://asset/cartoon_props/water_gun/bench.tscn")
const GUN_SCENE = preload("res://asset/cartoon_props/water_gun/water_gun.tscn")
const PART_NAMES := ["Thân", "Bình", "Bơm", "Ống", "Vòi"]
const SHOT_RANGE := 13.0
const AIM_DOT := 0.94
var _items: Array[Node3D] = []
var _benches: Dictionary = {}
var _guns: Dictionary = {}


func initial_shared_state(ids: Array, seed: int) -> Dictionary:
	return Rules.initial(ids, seed)


func _dung_san() -> void:
	var state: Dictionary = shared_snapshot.objective
	for item: Dictionary in state.items:
		var model: Node3D = PART_SCENES[int(item.kind)].instantiate()
		san.get_node("Items").add_child(model)
		_items.append(model)
	var ids: Array = shared_snapshot.ids
	for index: int in ids.size():
		var id := int(ids[index])
		var bench: Node3D = BENCH_SCENE.instantiate()
		san.get_node("Benches").add_child(bench)
		bench.position = Rules.bench(index, ids.size())
		var owner: Player = _nguoi(id)
		bench.get_node("Owner").text = "Bàn của bạn" if id == NetManager.local_id() else (owner.player_name if owner != null and not owner.player_name.is_empty() else str(id))
		_benches[str(id)] = bench
		var gun: Node3D = GUN_SCENE.instantiate()
		san.get_node("Items").add_child(gun)
		_guns[str(id)] = gun


func _cho_vao(index: int, total: int) -> Vector3:
	return Rules.bench(index, total) * 0.8


func _luat_moi_nhip() -> void:
	var player: Player = _nguoi(NetManager.local_id())
	if player != null:
		var offset := player.global_position - san.global_position
		offset.x = clampf(offset.x, -13, 13)
		offset.z = clampf(offset.z, -13, 13)
		if offset.y < -2:
			offset.y = 1
		player.global_position = san.global_position + offset


func _present_shared_players() -> void:
	super()
	if san == null or not shared_snapshot.has("objective"):
		return
	var state: Dictionary = shared_snapshot.objective
	for index: int in _items.size():
		var item: Dictionary = state.items[index]
		var model := _items[index]
		var owner := int(item.owner)
		model.visible = owner != Rules.ASSEMBLED
		if owner == Rules.AVAILABLE:
			model.position = Vector3(float(item.position[0]), 0.8, float(item.position[1]))
			model.rotation.y = gio() * 0.6
		elif owner >= 0:
			var player: Player = _nguoi(owner)
			model.visible = player != null and con_song(owner)
			if player != null:
				model.global_position = player.global_position + Vector3.UP * 2.2
	for key: String in _benches:
		var built: Array = state.built[key]
		var blueprint: Node3D = _benches[key].get_node("Blueprint")
		for index: int in Rules.PART_COUNT:
			blueprint.get_child(index).visible = built.has(index)
		var player: Player = _nguoi(int(key))
		var gun: Node3D = _guns[key]
		gun.visible = state.finished.has(key) and player != null and con_song(int(key))
		if gun.visible:
			gun.global_position = player.global_position + Vector3.UP * 1.1
			gun.rotation.y = player.rotation.y + PI * 0.5
	var key := str(NetManager.local_id())
	var built: Array = state.built.get(key, [])
	var held := int(state.held.get(key, -1))
	var carrying: String = " · " + PART_NAMES[int(state.items[held].kind)] if held >= 0 else ""
	san.get_node("HUD/Progress").text = "Súng nước %d/5%s" % [built.size(), carrying]
	_present_shot(state)


func _present_shot(state: Dictionary) -> void:
	var spray: MeshInstance3D = san.get_node("Spray")
	spray.visible = false
	if state.shots.is_empty():
		return
	var shot: Dictionary = state.shots.back()
	if gio() - float(shot.time) > 0.18:
		return
	var origin := Vector3(float(shot.origin[0]), 1.1, float(shot.origin[1]))
	var direction := Vector3(float(shot.direction[0]), 0, float(shot.direction[1]))
	spray.position = origin + direction * SHOT_RANGE * 0.5
	spray.quaternion = Quaternion(Vector3.UP, direction)
	spray.scale = Vector3(1, SHOT_RANGE, 1)
	spray.visible = true


func _input(event: InputEvent) -> void:
	if not _chay or gio() < 0:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		request_action("interact")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player: Player = _nguoi(NetManager.local_id())
		var camera := _cam_san()
		if player == null or camera == null:
			return
		var mouse := get_viewport().get_mouse_position()
		var plane := Plane(Vector3.UP, player.global_position.y + 1.1)
		var point: Variant = plane.intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
		if point is Vector3:
			var direction: Vector3 = point - player.global_position
			request_action("spray", [direction.x, direction.z])


func advance_shared_rules(snapshot: Dictionary, _elapsed: float) -> void:
	var state: Dictionary = snapshot.objective
	for id: Variant in snapshot.ids:
		if float(snapshot.alive[str(int(id))]) >= 0:
			var player: Player = _nguoi(int(id))
			Rules.drop(state, int(id), player.global_position - san.global_position if player != null else Vector3.ZERO)


func handle_shared_action(snapshot: Dictionary, id: int, action: String, payload: Array, elapsed: float) -> bool:
	var source: Player = _nguoi(id)
	if source == null or absf(source.global_position.y - san.global_position.y) > 5:
		return false
	var position := source.global_position - san.global_position
	if action == "interact":
		return Rules.interact(snapshot.objective, snapshot.ids, id, position, elapsed)
	if action != "spray" or payload.size() != 2:
		return false
	var direction := Vector2(float(payload[0]), float(payload[1]))
	if not direction.is_finite() or direction.length_squared() < 0.001:
		return false
	direction = direction.normalized()
	if not Rules.fire(snapshot.objective, id, elapsed):
		return false
	var target := _shot_target(snapshot, id, source, direction)
	if target != null:
		Rules.drop(snapshot.objective, target.player_id(), target.global_position - san.global_position)
	snapshot.objective.shots.append({"time": elapsed, "origin": [position.x, position.z],
		"direction": [direction.x, direction.y]})
	if snapshot.objective.shots.size() > 16:
		snapshot.objective.shots.pop_front()
	return true


func _shot_target(snapshot: Dictionary, id: int, source: Player, direction: Vector2) -> Player:
	var nearest := SHOT_RANGE
	var target: Player = null
	for candidate_id: Variant in snapshot.ids:
		if int(candidate_id) == id or float(snapshot.alive[str(int(candidate_id))]) >= 0:
			continue
		var candidate: Player = _nguoi(int(candidate_id))
		if candidate == null:
			continue
		var delta := candidate.global_position - source.global_position
		var flat := Vector2(delta.x, delta.z)
		if flat.length() < 0.01 or flat.length() > nearest or direction.dot(flat.normalized()) < AIM_DOT:
			continue
		var ray := PhysicsRayQueryParameters3D.create(source.global_position + Vector3.UP,
			candidate.global_position + Vector3.UP, 1)
		if not san.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		nearest = flat.length()
		target = candidate
	return target


func shared_ranking(snapshot: Dictionary) -> Array:
	return Rules.ranking(snapshot.objective, snapshot.ids, snapshot.alive)


func diem_cua(id: int) -> float:
	return float(shared_snapshot.get("objective", {}).get("built", {}).get(str(id), []).size())


func chu_diem(id: int) -> String:
	var finished: Dictionary = shared_snapshot.get("objective", {}).get("finished", {})
	return "%.1fs" % float(finished[str(id)]) if finished.has(str(id)) else "%d/5" % int(diem_cua(id))
