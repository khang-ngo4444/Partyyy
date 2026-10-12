extends Node

## Persistent rules live in MatchState; this node only derives time and presents them.
const COUNTDOWN := "COUNTDOWN"
const RUNNING := "RUNNING"
const ENDED := "ENDED"
const SUPPORTED: Array[String] = ["explosive", "laser_leap"]

@export var countdown_seconds: float = 3.0
@export var result_seconds: float = 5.0
@export var settlement_seconds: float = 0.8
var state: Dictionary = {}
var _seen_round: int = 0
var _last_json: String = ""
var _migration_snapshot: Dictionary = {}
var _migration_deadline: float = 0.0
var _migration_republish: bool = false

@onready var host: Node = get_parent()
## Quản trò vẽ đồng hồ; giữ tham chiếu cho công cụ kiểm tra multiplayer.
@onready var clock: Label = $"../Lop/Clock"
@onready var fuse: ProgressBar = $"../Lop/Fuse"
@onready var refresh: Timer = $Refresh


func _ready() -> void:
	add_to_group("minigame_session")
	Fusion.register_broadcast_receiver(self)
	tree_exiting.connect(func() -> void: Fusion.unregister_broadcast_receiver(self))
	NetManager.room_left.connect(_clear_session)
	NetManager.master_changed.connect(_master_changed)
	refresh.timeout.connect(_refresh_state)


func supports(code: String) -> bool:
	return SUPPORTED.has(code)


func match_state() -> Node:
	return get_tree().get_first_node_in_group("match_state")


func authority() -> bool:
	var ms: Node = match_state()
	return ms != null and ms.sync.has_authority()


func publish(snapshot: Dictionary) -> void:
	if not authority():
		return
	_migration_republish = false
	state = snapshot.duplicate(true)
	if not state.is_empty():
		state["revision"] = int(state.get("revision", 0)) + 1
	if not _migration_snapshot.is_empty():
		_migration_snapshot = state.duplicate(true)
	match_state().minigame_json = JSON.stringify(state)


func start_match(code: String) -> void:
	if not authority() or not state.is_empty() or host.dang_chay():
		return
	var template: Node = host._tim(code).instantiate()
	var ids: Array[int] = []
	for player: Player in get_tree().get_nodes_in_group("players"):
		ids.append(player.player_id())
	ids.sort()
	var alive: Dictionary = {}
	for id: int in ids:
		alive[str(id)] = -1.0
	var previous: Variant = match_state().get_meta("last_minigame_round", 0)
	var round_id: int = maxi(int(previous) + 1, int(Fusion.get_network_time() * 1000.0))
	match_state().set_meta("last_minigame_round", round_id)
	publish({"round": round_id, "code": code, "seed": randi(), "ids": ids,
		"alive": alive, "start": Fusion.get_network_time() + countdown_seconds,
		"duration": template.giay_van, "phase": COUNTDOWN,
		"parameters": template.network_parameters(), "blasts": []})
	template.free()


func _process(_delta: float) -> void:
	var ms: Node = match_state()
	if ms == null:
		return
	var encoded: String = ms.minigame_json
	if _recover_migration(encoded):
		return
	if encoded != _last_json:
		_read_snapshot(encoded)
	if state.is_empty():
		return
	_show_clock()


func _read_snapshot(encoded: String) -> void:
	_last_json = encoded
	var decoded: Variant = JSON.parse_string(encoded) if not encoded.is_empty() else {}
	state = decoded if decoded is Dictionary else {}
	if state.is_empty():
		_seen_round = 0
		fuse.visible = false
		return
	var round_id: int = int(state["round"])
	if round_id != _seen_round:
		_seen_round = round_id
		host.begin_shared_game(state)
	if is_instance_valid(host._game):
		host._game.apply_shared_state(state)


func _show_clock() -> void:
	var now: float = Fusion.get_network_time()
	var start: float = float(state["start"])
	var phase: String = ENDED if state["phase"] == ENDED or now >= start + float(state["duration"]) else (COUNTDOWN if now < start else RUNNING)
	host._huong_dan.visible = now < start and phase != ENDED
	host._dem.text = str(ceili(maxf(start - now, 0.0)))
	fuse.visible = state["code"] == "explosive" and phase == RUNNING
	fuse.value = 100.0 * clampf((float(state.get("fuse_end", now)) - now)
		/ maxf(float(state.get("fuse_duration", 1.0)), 0.01), 0.0, 1.0)


func _refresh_state() -> void:
	if not authority() or state.is_empty():
		return
	var next: Dictionary = state.duplicate(true)
	var now: float = Fusion.get_network_time()
	if next["phase"] == ENDED:
		if now >= float(next["ended"]) + result_seconds:
			publish({})
		return
	_collect_deaths(next, now)
	if now >= float(next["start"]):
		next["phase"] = RUNNING
		_update_rules(next, now)
	if JSON.stringify(next) != JSON.stringify(state):
		publish(next)


func _collect_deaths(snapshot: Dictionary, now: float) -> void:
	var alive: Dictionary = snapshot["alive"]
	for player: Player in get_tree().get_nodes_in_group("players"):
		var life: Dictionary = player.minigame_life()
		var key: String = str(player.player_id())
		if alive.has(key) and int(life.get("round", 0)) == int(snapshot["round"]):
			if float(alive[key]) < 0.0 and float(life.get("death", -1.0)) >= 0.0:
				alive[key] = minf(float(life["death"]), float(snapshot["duration"]))
	_collect_departures(snapshot, now)


func _collect_departures(snapshot: Dictionary, now: float) -> void:
	var room: FusionRoom = Fusion.get_room()
	if room == null:
		return
	var present: Array[int] = []
	for player: FusionPlayer in room.get_players():
		present.append(player.get_number())
	var alive: Dictionary = snapshot["alive"]
	for id: Variant in snapshot["ids"]:
		if not present.has(int(id)) and float(alive[str(int(id))]) < 0.0:
			alive[str(int(id))] = maxf(now - float(snapshot["start"]), 0.0)



func _update_rules(snapshot: Dictionary, now: float) -> void:
	var survivors: Array[int] = living_ids(snapshot)
	var deadline: float = float(snapshot["start"]) + float(snapshot["duration"])
	if now >= deadline or survivors.size() <= 1:
		if not snapshot.has("settle_end"):
			snapshot["settle_end"] = now + settlement_seconds
		if now >= float(snapshot["settle_end"]):
			_finish(snapshot, minf(now, deadline))
		return
	snapshot.erase("settle_end")
	if snapshot["code"] == "explosive":
		_update_bomb(snapshot, survivors, now)


func living_ids(snapshot: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var alive: Dictionary = snapshot["alive"]
	for id: Variant in snapshot["ids"]:
		if float(alive.get(str(int(id)), 0.0)) < 0.0:
			result.append(int(id))
	return result


func _update_bomb(snapshot: Dictionary, survivors: Array[int], now: float) -> void:
	var holder: int = int(snapshot.get("holder", 0))
	if holder == 0:
		if now >= float(snapshot.get("next_fuse", 0.0)):
			_assign_bomb(snapshot, survivors, now, true)
	elif not survivors.has(holder):
		_assign_bomb(snapshot, survivors, now, false)
	elif now >= float(snapshot["fuse_end"]):
		_detonate(snapshot, holder, now)


func _assign_bomb(snapshot: Dictionary, survivors: Array[int], now: float, reset_fuse: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(snapshot["seed"]) + int(snapshot.get("bomb_round", 0)) * 7919
	snapshot["holder"] = survivors[rng.randi_range(0, survivors.size() - 1)]
	snapshot["pass_after"] = now + float(snapshot["parameters"]["pass_delay"])
	if reset_fuse:
		var parameters: Dictionary = snapshot["parameters"]
		var durations: Array = parameters["fuse_seconds"]
		var index: int = mini(int(snapshot.get("bomb_round", 0)), durations.size() - 1)
		var duration: float = float(durations[index])
		snapshot["fuse_duration"] = duration
		snapshot["fuse_end"] = now + duration


func _detonate(snapshot: Dictionary, holder: int, now: float) -> void:
	var player: Player = host._nguoi(holder)
	if player == null:
		return
	var pos: Vector3 = player.global_position
	var blasts: Array = snapshot["blasts"]
	blasts.append({"position": [pos.x, pos.y + 0.9, pos.z],
		"time": float(snapshot["fuse_end"]), "holder": holder})
	snapshot["holder"] = 0
	snapshot["bomb_round"] = int(snapshot.get("bomb_round", 0)) + 1
	snapshot["next_fuse"] = now + settlement_seconds


func _finish(snapshot: Dictionary, now: float) -> void:
	var ranking: Array = snapshot["ids"].duplicate()
	var alive: Dictionary = snapshot["alive"]
	ranking.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: float = float(alive[str(int(a))])
		var db: float = float(alive[str(int(b))])
		if da == db:
			return int(a) < int(b)
		return (INF if da < 0.0 else da) > (INF if db < 0.0 else db))
	snapshot["ranking"] = ranking
	snapshot["ended"] = now
	snapshot["phase"] = ENDED


func request_pass(target: int) -> void:
	Fusion.rpc_to(Fusion.TARGET_MASTER, _request_pass, int(state.get("round", 0)), target)


@rpc("any_peer", "call_local")
func _request_pass(round_id: int, target: int) -> void:
	if not authority() or int(state.get("round", 0)) != round_id or state.get("phase", "") != RUNNING:
		return
	var sender: int = Fusion.get_rpc_sender()
	if sender == 0:
		sender = NetManager.local_id()
	if sender != int(state.get("holder", 0)) or not living_ids(state).has(target) or target == sender:
		return
	var now: float = Fusion.get_network_time()
	if now < float(state.get("pass_after", 0.0)) or now >= float(state.get("fuse_end", 0.0)):
		return
	var source: Player = host._nguoi(sender)
	var victim: Player = host._nguoi(target)
	if source == null or victim == null:
		return
	if source.global_position.distance_to(victim.global_position) > float(state["parameters"]["pass_radius"]):
		return
	var next: Dictionary = state.duplicate(true)
	next["holder"] = target
	next["pass_after"] = now + float(state["parameters"]["pass_delay"])
	publish(next)

func _clear_session() -> void:
	state.clear()
	_last_json = ""
	_seen_round = 0
	_migration_snapshot.clear()
	_migration_republish = false
	fuse.visible = false

func _master_changed(_new_id: int, _old_id: int) -> void:
	_migration_snapshot = state.duplicate(true)
	_migration_deadline = Fusion.get_network_time() + 2.0
	_migration_republish = not state.is_empty()


func _recover_migration(encoded: String) -> bool:
	if _migration_republish and authority():
		_migration_republish = false
		publish(_migration_snapshot)
		return true
	if _migration_snapshot.is_empty() or Fusion.get_network_time() >= _migration_deadline:
		_migration_snapshot.clear()
		return false
	if encoded.is_empty() or encoded == "{}":
		if authority():
			publish(_migration_snapshot)
		return true
	return false
