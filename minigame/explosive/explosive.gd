extends MiniGame3D

signal detonation(center: Vector3, radius: float)

@export var blast_radius: float = 3.0
@export var fuse_first: float = 16.0
@export var fuse_last: float = 7.0
@export_range(1, 20) var shorten_rounds: int = 4
@export var fuse_curve: Curve = null
@export var pass_radius: float = 2.2
@export var pass_delay: float = 0.9
@export var holder_speed_bonus: float = 1.6

var _bomb: Node3D = null
var _base_speed: float = -1.0
var _seen_blasts: int = 0
var _position_history: Array[Dictionary] = []
const HISTORY_SECONDS: float = 3.0
const BODY_CENTER_HEIGHT: float = 0.9


func _ready() -> void:
	super()
	ten = "EXPLOSIVE EXCHANGE"
	luat = "WASD chạy · E chuyền bom · tránh bán kính nổ"


func network_parameters() -> Dictionary:
	return {"blast_radius": blast_radius, "fuse_first": fuse_first, "fuse_last": fuse_last,
		"shorten_rounds": shorten_rounds, "fuse_seconds": _fuse_durations(),
		"pass_radius": pass_radius, "pass_delay": pass_delay,
		"holder_speed_bonus": holder_speed_bonus}


func _dung_san() -> void:
	_bomb = san.get_node("Bom")
	detonation.connect(_bomb.detonate)
	var parameters: Dictionary = shared_snapshot.get("parameters", network_parameters())
	for key: Variant in parameters:
		if str(key) != "fuse_seconds":
			set(str(key), parameters[key])


func _luat_moi_nhip() -> void:
	var now: float = Fusion.get_network_time()
	var player: Player = _nguoi(NetManager.local_id())
	if player != null:
		_position_history.append({"time": now, "position": player.global_position})
	while not _position_history.is_empty() and now - float(_position_history[0]["time"]) > HISTORY_SECONDS:
		_position_history.pop_front()
	_consume_blasts(now)
	var holder: int = int(shared_snapshot.get("holder", 0))
	_bomb.present(_nguoi(holder), float(shared_snapshot.get("fuse_end", now)),
		now >= float(shared_snapshot.get("pass_after", now)))
	_set_holder_speed(holder == NetManager.local_id())
	giu_trong_san(11.0)


func _consume_blasts(now: float) -> void:
	var blasts: Array = shared_snapshot.get("blasts", [])
	while _seen_blasts < blasts.size():
		var event: Dictionary = blasts[_seen_blasts]
		_seen_blasts += 1
		var coordinates: Array = event["position"]
		var center := Vector3(float(coordinates[0]), float(coordinates[1]), float(coordinates[2]))
		var time: float = float(event["time"])
		if now - time <= HISTORY_SECONDS:
			detonation.emit(center, blast_radius)
			var position: Vector3 = _position_at(time) + Vector3.UP * BODY_CENTER_HEIGHT
			if position.distance_squared_to(center) <= blast_radius * blast_radius:
				_report_shared_death(time - float(shared_snapshot["start"]))


func _position_at(time: float) -> Vector3:
	var player: Player = _nguoi(NetManager.local_id())
	var result: Vector3 = player.global_position if player != null else Vector3.INF
	var nearest: float = INF
	for sample: Dictionary in _position_history:
		var distance: float = absf(float(sample["time"]) - time)
		if distance < nearest:
			nearest = distance
			result = sample["position"]
	return result


func _set_holder_speed(holding: bool) -> void:
	var player: Player = _nguoi(NetManager.local_id())
	if player == null or not player.sync.has_authority():
		return
	if _base_speed < 0.0:
		_base_speed = player.speed
	player.speed = _base_speed + holder_speed_bonus if holding else _base_speed


func dung_som() -> void:
	_set_holder_speed(false)
	super()


func _unhandled_input(event: InputEvent) -> void:
	if not _chay or not event.is_action_pressed("interact") or gio() < 0.0:
		return
	if int(shared_snapshot.get("holder", 0)) != NetManager.local_id():
		return
	var holder: Player = _nguoi(NetManager.local_id())
	var target: int = 0
	var nearest: float = pass_radius * pass_radius
	for player: Player in get_tree().get_nodes_in_group("players"):
		if player == holder or not con_song(player.player_id()):
			continue
		var distance: float = player.global_position.distance_squared_to(holder.global_position)
		if distance <= nearest:
			target = player.player_id()
			nearest = distance
	if target != 0:
		get_viewport().set_input_as_handled()
		shared_session.request_pass(target)

func _fuse_durations() -> Array[float]:
	var durations: Array[float] = []
	for index: int in range(shorten_rounds + 1):
		var fraction: float = float(index) / maxi(shorten_rounds, 1)
		if fuse_curve != null:
			fraction = clampf(fuse_curve.sample_baked(fraction), 0.0, 1.0)
		var duration: float = lerpf(fuse_first, fuse_last, fraction)
		durations.append(minf(duration, durations.back()) if not durations.is_empty() else duration)
	return durations
