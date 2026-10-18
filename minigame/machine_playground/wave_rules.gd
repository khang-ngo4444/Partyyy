extends RefCounted

const WAVE_COUNT := 6
const CYCLE_SECONDS := 10.0
const WARNING_SECONDS := 2.5
const CROSSING_SECONDS := 5.0
const EXTENT := 24.0
const ROCK_LAYER := 64
const PUSH_RADIUS := 2.0
const PUSH_COOLDOWN := 1.0

static func initial(ids: Array) -> Dictionary:
	var state := {"score": {}, "resolved": {}, "events": {}, "cooldown": {}}
	for id: Variant in ids:
		state.score[str(int(id))] = 0
	return state


static func sample(seed: int, time: float) -> Dictionary:
	var cycle := clampi(int(maxf(time, 0) / CYCLE_SECONDS), 0, WAVE_COUNT - 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + cycle * 7919
	var angle := rng.randf_range(0, TAU)
	var phase := fposmod(maxf(time, 0), CYCLE_SECONDS)
	return {"cycle": cycle, "direction": Vector2(cos(angle), sin(angle)),
		"warning": phase < WARNING_SECONDS,
		"active": phase >= WARNING_SECONDS and phase < WARNING_SECONDS + CROSSING_SECONDS,
		"front": lerpf(-EXTENT, EXTENT, clampf((phase - WARNING_SECONDS) / CROSSING_SECONDS, 0, 1))}


static func resolve(state: Dictionary, id: int, cycle: int, sheltered: bool, time: float) -> bool:
	var key := str(id)
	if int(state.resolved.get(key, -1)) >= cycle:
		return false
	state.resolved[key] = cycle
	if sheltered:
		state.score[key] = int(state.score[key]) + 1
	else:
		event(state, id, "wash", time, Vector2.ZERO)
	return true


static func event(state: Dictionary, id: int, kind: String, time: float, direction: Vector2) -> void:
	var key := str(id)
	state.events[key] = {"serial": int(state.events.get(key, {}).get("serial", 0)) + 1,
		"kind": kind, "time": time, "direction": [direction.x, direction.y]}


static func ranking(state: Dictionary, ids: Array, alive: Dictionary) -> Array:
	var result := ids.duplicate()
	result.sort_custom(func(a: Variant, b: Variant) -> bool:
		var first := str(int(a))
		var second := str(int(b))
		if (float(alive[first]) < 0) != (float(alive[second]) < 0):
			return float(alive[first]) < 0
		if int(state.score[first]) != int(state.score[second]):
			return int(state.score[first]) > int(state.score[second])
		return int(a) < int(b))
	return result
