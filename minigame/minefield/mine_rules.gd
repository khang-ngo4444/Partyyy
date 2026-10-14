extends RefCounted

const COLUMNS := 4
const ROWS := 14
const CELL := 2.0
const LENGTH := ROWS * CELL
const WIDTH := COLUMNS * CELL
const SCAN_COOLDOWN := 0.7
const SCAN_FLASH := 0.45
const ROLLER_START := 2.0
const ROLLER_FINISH := 23.0
const SCAN_RADIUS := 3.2
const HIT_IMMUNITY := 1.2


static func initial(ids: Array, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var mines: Array = []
	for index in COLUMNS * ROWS:
		mines.append(index >= COLUMNS * 2)
	# One narrow connected corridor; every other cell in a danger row is mined.
	var column := rng.randi_range(1, COLUMNS - 2)
	var previous_bend := false
	for row in range(2, ROWS):
		var direction := -1 if rng.randi_range(0, 1) == 0 else 1
		if column == 1:
			direction = 1
		elif column == COLUMNS - 2:
			direction = -1
		var bend := row == 2 or (not previous_bend and rng.randf() < 0.7)
		var next := column + direction if bend else column
		for x in range(mini(column, next), maxi(column, next) + 1):
			mines[row * COLUMNS + x] = false
		column = next
		previous_bend = bend
	var state := {"mines": mines, "revealed": {}, "exploded": {}, "players": {}, "events": {}}
	for id: Variant in ids:
		state.players[str(int(id))] = {"hp": 2, "distance": 0.0, "finished": -1.0,
			"immune": -1.0, "last": [], "scan_at": -1.0, "scanned": -99.0}
	return state


static func front(elapsed: float) -> float:
	var t := clampf((elapsed - ROLLER_START) / (ROLLER_FINISH - ROLLER_START), 0, 1)
	return -4.0 + (LENGTH + 5.0) * (0.7 * t + 0.3 * t * t)


static func cell_at(point: Vector2) -> int:
	if point.x < -WIDTH / 2 or point.x >= WIDTH / 2 or point.y < 0 or point.y >= LENGTH:
		return -1
	return floori(point.y / CELL) * COLUMNS + floori((point.x + WIDTH / 2) / CELL)


static func center(index: int) -> Vector2:
	return Vector2((index % COLUMNS + 0.5) * CELL - WIDTH / 2, (index / COLUMNS + 0.5) * CELL)


static func event(state: Dictionary, key: String, kind: String, elapsed: float) -> void:
	var previous: Dictionary = state.events.get(key, {})
	state.events[key] = {"serial": int(previous.get("serial", 0)) + 1, "kind": kind, "time": elapsed}


static func advance(state: Dictionary, id: int, point: Vector2, elapsed: float) -> void:
	var key := str(id)
	if not state.players.has(key):
		return
	var player: Dictionary = state.players[key]
	if int(player.hp) <= 0 or float(player.finished) >= 0:
		return
	# The pursuing roller ignores hearts and mine immunity.
	if point.y <= front(elapsed):
		player.hp = 0
		event(state, key, "roller", elapsed)
		return
	var previous := point
	if player.last.size() == 2:
		previous = Vector2(player.last[0], player.last[1])
	# Reject implausible teleports rather than granting distance or skipping mines.
	if previous.distance_to(point) > 6:
		return
	var steps := maxi(ceili(previous.distance_to(point) / 0.25), 1)
	for step in range(steps + 1):
		var sample := previous.lerp(point, float(step) / steps)
		var index := cell_at(sample)
		if index >= 0 and state.mines[index] and not state.exploded.has(str(index)) and elapsed >= float(player.immune):
			state.exploded[str(index)] = elapsed
			state.revealed[str(index)] = true
			player.hp = int(player.hp) - 1
			player.immune = elapsed + HIT_IMMUNITY
			event(state, key, "mine", elapsed)
			if int(player.hp) <= 0:
				player.distance = maxf(float(player.distance), clampf(sample.y, 0, LENGTH))
				return
	player.distance = maxf(float(player.distance), clampf(point.y, 0, LENGTH))
	if point.y >= LENGTH:
		player.finished = elapsed
		return
	player.last = [point.x, point.y]


static func scan(state: Dictionary, id: int, point: Vector2, elapsed: float) -> bool:
	var player: Dictionary = state.players.get(str(id), {})
	if player.is_empty() or not point.is_finite() or cell_at(point) < 0:
		return false
	if int(player.hp) <= 0 or float(player.finished) >= 0 or elapsed < float(player.scan_at):
		return false
	player.scan_at = elapsed + SCAN_COOLDOWN
	player.scanned = elapsed
	player.scan_origin = [point.x, point.y]
	for index in state.mines.size():
		if center(index).distance_to(point) <= SCAN_RADIUS:
			state.revealed[str(index)] = true
	return true


static func complete(state: Dictionary) -> bool:
	for player: Dictionary in state.players.values():
		if int(player.hp) > 0 and float(player.finished) < 0:
			return false
	return true


static func ranking(state: Dictionary, ids: Array, alive: Dictionary) -> Array:
	var result := ids.duplicate()
	result.sort_custom(func(a: Variant, b: Variant) -> bool:
		var pa: Dictionary = state.players[str(int(a))]
		var pb: Dictionary = state.players[str(int(b))]
		var departed_a := float(alive.get(str(int(a)), -1)) >= 0 and int(pa.hp) > 0 and float(pa.finished) < 0
		var departed_b := float(alive.get(str(int(b)), -1)) >= 0 and int(pb.hp) > 0 and float(pb.finished) < 0
		if departed_a != departed_b:
			return not departed_a
		if not is_equal_approx(float(pa.distance), float(pb.distance)):
			return float(pa.distance) > float(pb.distance)
		if float(pa.finished) >= 0 and float(pb.finished) >= 0 and pa.finished != pb.finished:
			return float(pa.finished) < float(pb.finished)
		if int(pa.hp) != int(pb.hp):
			return int(pa.hp) > int(pb.hp)
		return int(a) < int(b))
	return result
