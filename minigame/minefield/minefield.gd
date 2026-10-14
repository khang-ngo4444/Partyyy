extends "res://minigame/machine_playground/objective_game.gd"

const Rules = preload("res://minigame/minefield/mine_rules.gd")
const TILE_SCENE = preload("res://minigame/minefield/mine_tile.tscn")
var _tiles: Array[Node3D] = []
var _seen_events: Dictionary = {}
var _jump_before := -1
var _materials: Array[StandardMaterial3D] = []


func initial_shared_state(ids: Array, seed: int) -> Dictionary:
	return Rules.initial(ids, seed)


func _cho_vao(index: int, total: int) -> Vector3:
	return Vector3(lerpf(-5, 5, float(index) / maxi(total - 1, 1)) if total > 1 else 0, 0, -1)


func _dung_san() -> void:
	for index in 5:
		_materials.append(load("res://minigame/minefield/palette_%d.tres" % index))
	for index in Rules.COLUMNS * Rules.ROWS:
		var tile: Node3D = TILE_SCENE.instantiate()
		var center: Vector2 = Rules.center(index)
		tile.position = Vector3(center.x, 0, -center.y)
		san.get_node("Tiles").add_child(tile)
		_tiles.append(tile)
	var player := _nguoi(NetManager.local_id())
	if player != null:
		_jump_before = player.so_lan_nhay
		player.so_lan_nhay = 0


func advance_shared_rules(snapshot: Dictionary, elapsed: float) -> void:
	for id: Variant in snapshot.ids:
		var key := str(int(id))
		if float(snapshot.alive[key]) >= 0:
			continue
		var player := _nguoi(int(id))
		if player == null:
			continue
		var local := player.global_position - san.global_position
		Rules.advance(snapshot.objective, int(id), Vector2(local.x, -local.z), elapsed)
		if int(snapshot.objective.players[key].hp) <= 0:
			snapshot.alive[key] = elapsed


func round_complete(snapshot: Dictionary) -> bool:
	for id: Variant in snapshot.ids:
		var key := str(int(id))
		if float(snapshot.alive[key]) < 0 and float(snapshot.objective.players[key].finished) < 0:
			return false
	return true


func _luat_moi_nhip() -> void:
	var player := _nguoi(NetManager.local_id())
	if player == null:
		return
	var local := player.global_position - san.global_position
	local.x = clampf(local.x, -Rules.WIDTH * 0.5 + 0.35, Rules.WIDTH * 0.5 - 0.35)
	local.z = clampf(local.z, -Rules.LENGTH - 2, -0.35)
	if local.y < -1 or local.y > 4:
		local.y = 1
		player.velocity = Vector3.ZERO
	player.global_position = san.global_position + local


func _present_shared_players() -> void:
	super()
	if san == null:
		return
	var elapsed := maxf(gio(), 0)
	var state: Dictionary = shared_snapshot.objective
	san.get_node("Roller").position.z = -Rules.front(elapsed)
	san.get_node("Roller/Drum").rotation.x = elapsed * 1.3
	for index in _tiles.size():
		var tile := _tiles[index]
		var key := str(index)
		var revealed: bool = state.revealed.has(key)
		var exploded: bool = state.exploded.has(key)
		var mine := bool(state.mines[index])
		tile.get_node("Mine").visible = revealed and mine and not exploded
		var clue: Label3D = tile.get_node("Clue")
		clue.visible = exploded
		clue.text = "✦" if exploded else ""
		var palette := 4 if exploded else (3 if revealed and mine else (2 if revealed else index % 2))
		tile.get_node("Tile").material_override = _materials[palette]
	var id := NetManager.local_id()
	var own: Dictionary = state.players.get(str(id), {})
	var player := _nguoi(id)
	if player != null and not own.is_empty():
		var finished := float(own.finished) >= 0
		var stunned := elapsed < float(own.immune) - 0.45
		player.khoa_di_chuyen = player.khoa_di_chuyen or finished or stunned
		var scanner: MeshInstance3D = san.get_node("Scanner")
		var origin: Array = own.get("scan_origin", [0, 0])
		scanner.position = Vector3(float(origin[0]), 0.12, -float(origin[1]))
		scanner.visible = _chay and con_song(id) and not finished and elapsed - float(own.scanned) < Rules.SCAN_FLASH
		san.get_node("HUD/Progress").text = "%s  ·  %.1f m%s" % ["♥".repeat(int(own.hp)), float(own.distance), "  ✓" if finished else ""]
		var target_z := clampf(player.global_position.z - san.global_position.z, -Rules.LENGTH + 6, -4)
		if not con_song(id):
			for other: Variant in shared_snapshot.ids:
				if con_song(int(other)):
					target_z = -float(state.players[str(int(other))].distance)
					break
		san.get_node("Cam").position.z = target_z + 10
	_consume_events(state, elapsed)


func _consume_events(state: Dictionary, elapsed: float) -> void:
	for key: String in state.events:
		var event: Dictionary = state.events[key]
		if int(event.serial) <= int(_seen_events.get(key, 0)):
			continue
		_seen_events[key] = event.serial
		var player := _nguoi(int(key))
		if player != null and elapsed - float(event.time) < 2:
			if player.has_method("play_reaction"):
				player.play_reaction("hit", 0.75)
			if player.is_mine:
				player.velocity = Vector3.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if _chay and gio() >= 0:
			request_action("scan")
			get_viewport().set_input_as_handled()


func handle_shared_action(snapshot: Dictionary, id: int, action: String, _payload: Array, elapsed: float) -> bool:
	var player := _nguoi(id)
	if action != "scan" or player == null or elapsed < 0 or elapsed >= float(snapshot.duration):
		return false
	if float(snapshot.alive.get(str(id), 0)) >= 0:
		return false
	var local := player.global_position - san.global_position
	if absf(local.y) > 2:
		return false
	return Rules.scan(snapshot.objective, id, Vector2(local.x, -local.z), elapsed)


func shared_ranking(snapshot: Dictionary) -> Array:
	return Rules.ranking(snapshot.objective, snapshot.ids, snapshot.alive)


func diem_cua(id: int) -> float:
	return float(shared_snapshot.get("objective", {}).get("players", {}).get(str(id), {}).get("distance", 0))


func chu_diem(id: int) -> String:
	return "%.1f m" % diem_cua(id)


func dung_som() -> void:
	var player := _nguoi(NetManager.local_id())
	if player != null and _jump_before >= 0:
		player.so_lan_nhay = _jump_before
	_jump_before = -1
	super()
