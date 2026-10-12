extends MiniGame3D

@export var clearance_height: float = 0.9
@export var floor_height: float = 0.2
@export var speed_first: float = 0.55
@export var speed_last: float = 1.9
@export var speed_ramp_seconds: float = 60.0
@export var telegraph_seconds: float = 1.1
@export var spawn_duration: Vector2 = Vector2(2.0, 3.6)
@export var spawn_gap: Vector2 = Vector2(0.5, 1.5)
@export var speed_multiplier: Vector2 = Vector2(0.75, 1.35)
@export_range(1, 3) var max_beams: int = 3

var _beams: Array[Node3D] = []
var _schedule: Array[Dictionary] = []
var _wave: int = -1


func _ready() -> void:
	super()
	ten = "LASER LEAP"
	luat = "WASD chạy · Space nhảy qua tia · tránh ánh sáng cảnh báo"


func network_parameters() -> Dictionary:
	return {"clearance_height": clearance_height, "floor_height": floor_height,
		"speed_first": speed_first, "speed_last": speed_last, "speed_ramp_seconds": speed_ramp_seconds,
		"telegraph_seconds": telegraph_seconds, "spawn_duration": [spawn_duration.x, spawn_duration.y],
		"spawn_gap": [spawn_gap.x, spawn_gap.y], "speed_multiplier": [speed_multiplier.x, speed_multiplier.y],
		"max_beams": max_beams}


func _dung_san() -> void:
	_beams.assign(san.find_children("Tia*", "Node3D", false, false))
	var parameters: Dictionary = shared_snapshot.get("parameters", network_parameters())
	_schedule = build_schedule(hat_giong, giay_van, parameters)
	clearance_height = float(parameters["clearance_height"])
	floor_height = float(parameters["floor_height"])
	speed_first = float(parameters["speed_first"])
	speed_last = float(parameters["speed_last"])
	speed_ramp_seconds = float(parameters["speed_ramp_seconds"])
	telegraph_seconds = float(parameters["telegraph_seconds"])


func _luat_moi_nhip() -> void:
	var elapsed: float = gio()
	while _wave + 1 < _schedule.size() and elapsed >= float(_schedule[_wave + 1]["start"]) - telegraph_seconds:
		_wave += 1
	if _wave < 0:
		return
	var wave: Dictionary = _schedule[_wave]
	var patterns: Array = wave["beams"]
	for index: int in _beams.size():
		if index >= patterns.size() or elapsed >= float(wave["end"]):
			_beams[index].deactivate()
		else:
			_present_beam(index, wave, patterns[index], elapsed)


func _present_beam(index: int, wave: Dictionary, pattern: Dictionary, elapsed: float) -> void:
	var start: float = float(wave["start"])
	var sweep: float = goc_quay(0.0, maxf(elapsed, start), speed_first, speed_last, speed_ramp_seconds)
	sweep -= goc_quay(0.0, start, speed_first, speed_last, speed_ramp_seconds)
	var angle: float = float(pattern["angle"]) + float(pattern["direction"]) * float(pattern["speed"]) * sweep
	_beams[index].present(angle, elapsed >= start)


func _toi_thua() -> bool:
	if super():
		return true
	var player: Player = _nguoi(NetManager.local_id())
	if player == null or not player.sync.has_authority():
		return false
	var height: float = player.global_position.y - san.global_position.y - floor_height
	if height > clearance_height:
		return false
	for beam: Node3D in _beams:
		if beam.hits(player):
			return true
	return false


static func build_schedule(seed_value: int, duration: float, parameters: Dictionary) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array[Dictionary] = []
	var start: float = float(parameters["telegraph_seconds"])
	while start < duration:
		var beams: Array[Dictionary] = []
		for _index: int in rng.randi_range(1, int(parameters["max_beams"])):
			beams.append(_random_beam(rng, parameters["speed_multiplier"]))
		var lengths: Array = parameters["spawn_duration"]
		var gaps: Array = parameters["spawn_gap"]
		var length: float = rng.randf_range(float(lengths[0]), float(lengths[1]))
		result.append({"start": start, "end": start + length, "beams": beams})
		start += length + rng.randf_range(float(gaps[0]), float(gaps[1])) + float(parameters["telegraph_seconds"])
	return result


static func _random_beam(rng: RandomNumberGenerator, multipliers: Array) -> Dictionary:
	return {"angle": rng.randf() * TAU, "direction": -1.0 if rng.randf() < 0.5 else 1.0,
		"speed": rng.randf_range(float(multipliers[0]), float(multipliers[1]))}
