extends RefCounted

const PART_COUNT := 5
const PICKUP_RADIUS := 1.8
const ASSEMBLY_RADIUS := 2.4
const BENCH_RADIUS := 11.5
const SHOT_COOLDOWN := 1.0
const AVAILABLE := -1
const ASSEMBLED := -2

static func bench(index: int, total: int) -> Vector3:
	var angle := TAU * index / maxi(total, 1)
	return Vector3(cos(angle), 0, sin(angle)) * BENCH_RADIUS


static func initial(ids: Array, seed: int) -> Dictionary:
	var state := {"built": {}, "held": {}, "finished": {}, "items": [], "cooldown": {}, "shots": []}
	for id: Variant in ids:
		state.built[str(int(id))] = []
		state.held[str(int(id))] = AVAILABLE
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for kind: int in PART_COUNT:
		var angle := TAU * kind / PART_COUNT
		for copy: int in ids.size():
			state.items.append({"kind": kind, "owner": AVAILABLE,
				"position": [cos(angle) * 5 + rng.randf_range(-1, 1),
					sin(angle) * 5 + rng.randf_range(-1, 1)]})
	return state


static func interact(state: Dictionary, ids: Array, id: int, position: Vector3, time: float) -> bool:
	var key := str(id)
	if not state.held.has(key) or state.finished.has(key):
		return false
	var held := int(state.held[key])
	if held >= 0:
		var item: Dictionary = state.items[held]
		var near_bench := Vector2(position.x, position.z).distance_to(
			Vector2(bench(ids.find(id), ids.size()).x, bench(ids.find(id), ids.size()).z)) < ASSEMBLY_RADIUS
		if near_bench and not state.built[key].has(int(item.kind)):
			state.built[key].append(int(item.kind))
			item.owner = ASSEMBLED
			if state.built[key].size() == PART_COUNT:
				state.finished[key] = time
			state.held[key] = AVAILABLE
		else:
			drop(state, id, position)
		return true
	var nearest := PICKUP_RADIUS
	var found := AVAILABLE
	for index: int in state.items.size():
		var item: Dictionary = state.items[index]
		if int(item.owner) != AVAILABLE:
			continue
		var point := Vector2(float(item.position[0]), float(item.position[1]))
		var distance := Vector2(position.x, position.z).distance_to(point)
		if distance < nearest:
			nearest = distance
			found = index
	if found < 0:
		return false
	state.items[found].owner = id
	state.held[key] = found
	return true


static func drop(state: Dictionary, id: int, position: Vector3) -> void:
	var key := str(id)
	var held := int(state.held.get(key, AVAILABLE))
	if held < 0:
		return
	state.items[held].owner = AVAILABLE
	state.items[held].position = [position.x, position.z]
	state.held[key] = AVAILABLE


static func fire(state: Dictionary, id: int, time: float) -> bool:
	var key := str(id)
	if not state.finished.has(key) or time < float(state.cooldown.get(key, -1)):
		return false
	state.cooldown[key] = time + SHOT_COOLDOWN
	return true


static func ranking(state: Dictionary, ids: Array, alive: Dictionary) -> Array:
	var result := ids.duplicate()
	result.sort_custom(func(a: Variant, b: Variant) -> bool:
		var first := str(int(a))
		var second := str(int(b))
		if (float(alive[first]) < 0) != (float(alive[second]) < 0):
			return float(alive[first]) < 0
		var first_finish := float(state.finished.get(first, INF))
		var second_finish := float(state.finished.get(second, INF))
		if first_finish != second_finish:
			return first_finish < second_finish
		if state.built[first].size() != state.built[second].size():
			return state.built[first].size() > state.built[second].size()
		return int(a) < int(b))
	return result
