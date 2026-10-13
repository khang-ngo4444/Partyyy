extends RefCounted

const MAP_SIZE := 28.0
const GRID_SIZE := 56
const CELL_SIZE := MAP_SIZE / GRID_SIZE
const BRUSH_RADIUS := 0.85
const MAX_STROKE := 4.0
const OWNER_CODES := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+-"
const HIT_COOLDOWN := 0.8
const STUN_SECONDS := 0.7


static func initial(ids: Array) -> Dictionary:
	var state := {"cells": "0".repeat(GRID_SIZE * GRID_SIZE), "counts": {},
		"last": {}, "cooldown": {}, "stun": {}, "events": {}}
	for id: Variant in ids:
		state.counts[str(int(id))] = 0
	return state


static func paint(state: Dictionary, ids: Array, id: int, position: Vector2) -> bool:
	var index := ids.find(id)
	if index < 0 or index + 1 >= OWNER_CODES.length() or not position.is_finite():
		return false
	var key := str(id)
	var previous: Array = state.last.get(key, [position.x, position.y])
	var start := Vector2(float(previous[0]), float(previous[1]))
	if start.distance_to(position) > MAX_STROKE:
		start = position
	state.last[key] = [position.x, position.y]
	var cells: PackedByteArray = str(state.cells).to_ascii_buffer()
	var changed := _stroke(cells, state.counts, ids, index + 1, start, position)
	if changed:
		state.cells = cells.get_string_from_ascii()
	return changed


static func _stroke(cells: PackedByteArray, counts: Dictionary, ids: Array,
		owner: int, start: Vector2, finish: Vector2) -> bool:
	var low := (start.min(finish) - Vector2.ONE * BRUSH_RADIUS + Vector2.ONE * MAP_SIZE * 0.5) / CELL_SIZE
	var high := (start.max(finish) + Vector2.ONE * BRUSH_RADIUS + Vector2.ONE * MAP_SIZE * 0.5) / CELL_SIZE
	var changed := false
	for y: int in range(maxi(int(floor(low.y)), 0), mini(int(floor(high.y)), GRID_SIZE - 1) + 1):
		for x: int in range(maxi(int(floor(low.x)), 0), mini(int(floor(high.x)), GRID_SIZE - 1) + 1):
			var point := Vector2(x + 0.5, y + 0.5) * CELL_SIZE - Vector2.ONE * MAP_SIZE * 0.5
			if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point, start, finish)) > BRUSH_RADIUS * BRUSH_RADIUS:
				continue
			var cell := y * GRID_SIZE + x
			var old_owner := OWNER_CODES.find(String.chr(cells[cell]))
			if old_owner == owner:
				continue
			if old_owner > 0:
				var old_key := str(int(ids[old_owner - 1]))
				counts[old_key] = int(counts[old_key]) - 1
			var key := str(int(ids[owner - 1]))
			counts[key] = int(counts[key]) + 1
			cells[cell] = OWNER_CODES.unicode_at(owner)
			changed = true
	return changed


static func stop_stroke(state: Dictionary, id: int) -> void:
	state.last.erase(str(id))


static func hit(state: Dictionary, attacker: int, victim: int, time: float, direction: Vector2) -> bool:
	var key := str(attacker)
	var target := str(victim)
	if attacker == victim or not state.counts.has(key) or not state.counts.has(target):
		return false
	if time < float(state.cooldown.get(key, -1)) or time < float(state.stun.get(key, -1)):
		return false
	state.cooldown[key] = time + HIT_COOLDOWN
	state.stun[target] = time + STUN_SECONDS
	stop_stroke(state, victim)
	state.events[target] = {"serial": int(state.events.get(target, {}).get("serial", 0)) + 1,
		"time": time, "direction": [direction.x, direction.y]}
	return true


static func percent(state: Dictionary, id: int) -> float:
	return 100.0 * int(state.counts.get(str(id), 0)) / (GRID_SIZE * GRID_SIZE)


static func ranking(state: Dictionary, ids: Array, alive: Dictionary) -> Array:
	var result := ids.duplicate()
	result.sort_custom(func(a: Variant, b: Variant) -> bool:
		var first := str(int(a))
		var second := str(int(b))
		if (float(alive[first]) < 0) != (float(alive[second]) < 0):
			return float(alive[first]) < 0
		if int(state.counts[first]) != int(state.counts[second]):
			return int(state.counts[first]) > int(state.counts[second])
		return int(a) < int(b))
	return result
