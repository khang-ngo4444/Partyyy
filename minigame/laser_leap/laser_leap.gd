extends MiniGame3D

@export var clearance_height: float = 0.9
@export var floor_height: float = 0.2
@export var telegraph_seconds: float = 1.1
@export var sweep_first: float = 6.5
@export var sweep_last: float = 4.5
@export var sweep_gap: float = 0.6
const WALL_EXTENT := 17.0

var _beams: Array[Node3D] = []
var _schedule: Array[Dictionary] = []
var _wave := -1


func _ready() -> void:
	super()
	ten = "LASER LEAP"
	luat = "WASD chạy · Space nhảy qua laser"


func allows_jump() -> bool:
	return true


func network_parameters() -> Dictionary:
	return {"clearance_height": clearance_height, "floor_height": floor_height,
		"telegraph_seconds": telegraph_seconds, "sweep_first": sweep_first,
		"sweep_last": sweep_last, "sweep_gap": sweep_gap}


func _dung_san() -> void:
	_beams.assign(san.find_children("Tia*", "Node3D", false, false))
	var parameters: Dictionary = shared_snapshot.get("parameters", network_parameters())
	_schedule = build_schedule(hat_giong, giay_van, parameters)
	clearance_height = float(parameters["clearance_height"])
	floor_height = float(parameters["floor_height"])
	telegraph_seconds = float(parameters["telegraph_seconds"])


func _luat_moi_nhip() -> void:
	var elapsed := gio()
	while _wave + 1 < _schedule.size() and elapsed >= float(_schedule[_wave + 1].start) - telegraph_seconds:
		_wave += 1
	if _wave < 0:
		return
	var wave: Dictionary = _schedule[_wave]
	if elapsed >= float(wave.end):
		_beams[0].deactivate()
		return
	var progress := clampf((elapsed - float(wave.start)) / (float(wave.end) - float(wave.start)), 0.0, 1.0)
	var offset := lerpf(-WALL_EXTENT, WALL_EXTENT, progress) * float(wave.direction)
	_beams[0].present(int(wave.axis), offset, elapsed >= float(wave.start))


func _toi_thua() -> bool:
	if super():
		return true
	var player := _nguoi(NetManager.local_id())
	if player == null or not player.sync.has_authority():
		return false
	if player.global_position.y - san.global_position.y - floor_height > clearance_height:
		return false
	return _beams[0].hits(player)


static func build_schedule(seed_value: int, duration: float, parameters: Dictionary) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array[Dictionary] = []
	var start := float(parameters.telegraph_seconds)
	var axis := rng.randi_range(0, 1)
	while start < duration:
		var length := lerpf(float(parameters.sweep_first), float(parameters.sweep_last), clampf(start / duration, 0, 1))
		if start + length > duration:
			break
		result.append({"start": start, "end": start + length, "axis": axis,
			"direction": -1 if rng.randf() < 0.5 else 1})
		axis = 1 - axis
		start += length + float(parameters.sweep_gap) + float(parameters.telegraph_seconds)
	return result
