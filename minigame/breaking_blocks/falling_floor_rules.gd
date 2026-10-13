extends RefCounted

const SIDE := 8
const TILE_COUNT := SIDE * SIDE
const TILE_SIZE := 2.8
const WARNING_SECONDS := 2.4
const DROP_SECONDS := 0.45
const SUBMERGED_SECONDS := 2.0
const RISE_SECONDS := 0.45
const DEPTH := 12.0
const FIRST_WARNING := 2.0
const CYCLE_SECONDS := 7.0
const REGULAR_WAVES := 7
const PERMANENT_FROM := 3
const FINAL_WARNING := 55.5


static func plan(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var waves: Array = []
	var permanent: Array = []
	for wave_index: int in REGULAR_WAVES:
		var selected: Array = _group(rng.randi_range(0, 3), wave_index % 2 == 0)
		selected = selected.filter(func(index: int) -> bool: return not permanent.has(index))
		var stays_down: Array = []
		if wave_index >= PERMANENT_FROM:
			var edges: Array = selected.filter(func(index: int) -> bool: return _on_edge(index))
			for count: int in mini(2, edges.size()):
				var choice := rng.randi_range(0, edges.size() - 1)
				var index: int = edges.pop_at(choice)
				stays_down.append(index)
				permanent.append(index)
		waves.append({"start": FIRST_WARNING + wave_index * CYCLE_SECONDS,
			"tiles": selected, "permanent": stays_down})
	var all_tiles: Array = []
	for index: int in TILE_COUNT:
		all_tiles.append(index)
	waves.append({"start": FINAL_WARNING, "tiles": all_tiles, "permanent": all_tiles})
	return waves


static func _group(direction: int, half: bool) -> Array:
	var selected: Array = []
	for index: int in TILE_COUNT:
		var row: int = index / SIDE
		var column: int = index % SIDE
		var rotated := Vector2i(column, row)
		for turn: int in direction:
			rotated = Vector2i(SIDE - 1 - rotated.y, rotated.x)
		if rotated.x < SIDE / 2 and (half or rotated.y < SIDE / 2):
			selected.append(index)
	return selected


static func _on_edge(index: int) -> bool:
	var row: int = index / SIDE
	var column: int = index % SIDE
	return row == 0 or row == SIDE - 1 or column == 0 or column == SIDE - 1


static func center(index: int) -> Vector3:
	return Vector3((float(index % SIDE) - 3.5) * TILE_SIZE, 0.0,
		(float(index / SIDE) - 3.5) * TILE_SIZE)


static func tile_at(waves: Array, index: int, elapsed: float) -> Dictionary:
	var sample := {"solid": true, "warning": false, "depth": 0.0}
	for wave: Dictionary in waves:
		if not wave.tiles.has(index):
			continue
		var time := elapsed - float(wave.start)
		if time < 0.0:
			continue
		if time < WARNING_SECONDS:
			sample.warning = true
			continue
		var drop_time := time - WARNING_SECONDS
		if drop_time < DROP_SECONDS:
			return {"solid": false, "warning": false,
				"depth": DEPTH * smoothstep(0.0, DROP_SECONDS, drop_time)}
		if wave.permanent.has(index):
			return {"solid": false, "warning": false, "depth": DEPTH}
		var rise_time := drop_time - DROP_SECONDS - SUBMERGED_SECONDS
		if rise_time < 0.0:
			return {"solid": false, "warning": false, "depth": DEPTH}
		if rise_time < RISE_SECONDS:
			return {"solid": false, "warning": false,
				"depth": DEPTH * (1.0 - smoothstep(0.0, RISE_SECONDS, rise_time))}
	return sample


## Reverse authoritative elimination receive-order. Death timestamps never sort ranks.
static func ranking(ids: Array, alive: Dictionary, death_order: Array) -> Array:
	var survivors: Array = ids.filter(func(id: Variant) -> bool:
		return float(alive.get(id, 0.0)) < 0.0)
	var result: Array = survivors.duplicate()
	for index: int in range(death_order.size() - 1, -1, -1):
		var id: Variant = death_order[index]
		if ids.has(id) and not result.has(id):
			result.append(id)
	return result
