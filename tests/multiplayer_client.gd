extends Node

## Test-only command adapter. Run this scene with -- --role=alpha --room=<private room>.
var role: String = "alpha"
var room: String = "MCP-MinGames-1012"
var _joined: bool = false
var _last_sequence: int = -1
var _park: Array = []
var _observations: Array[Dictionary] = []
var _previous_phase: String = ""
var _elapsed: float = 0.0
@onready var main: Node = $Main


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--role="):
			role = argument.trim_prefix("--role=")
		if argument.begins_with("--room="):
			room = argument.trim_prefix("--room=")
	NetManager.player_name = "MCP " + role
	process_physics_priority = 100
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/runtime"))


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < 0.1:
		return
	_elapsed = 0.0
	_connect_room()
	_execute_command()
	_write_observation()


func _connect_room() -> void:
	if _joined or Fusion.get_connection_status() != Fusion.STATUS_CONNECTED_TO_PHOTON:
		return
	_joined = true
	if role == "alpha":
		var options := FusionRoomOptions.new()
		options.set_max_players(4)
		options.set_is_visible(false)
		options.set_empty_room_ttl_ms(0)
		Fusion.create_room(room, options)
	else:
		Fusion.join_room(room)


func _execute_command() -> void:
	var path: String = "res://tests/runtime/" + role + "_command.json"
	if not FileAccess.file_exists(path):
		return
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary or int(value.get("sequence", -1)) <= _last_sequence:
		return
	_last_sequence = int(value["sequence"])
	if value.has("park"):
		_park = value["park"]
	var session: Node = main.quan_tro.get_node("Session")
	if value.has("start"):
		session.start_match(str(value["start"]))
	if value.has("patch") and session.authority():
		var snapshot: Dictionary = session.state.duplicate(true)
		snapshot.merge(value["patch"], true)
		session.publish(snapshot)
	if value.get("action", "") == "leave":
		_park.clear()
		Fusion.leave_room()
	if value.get("action", "") == "quit":
		get_tree().quit()


func _physics_process(_delta: float) -> void:
	var ms: Node = get_tree().get_first_node_in_group("match_state")
	if ms != null and ms.sync.has_authority() and not ms.setup_complete:
		ms.min_players = 4
		ms.gameplay_settings_json = GameplaySettings.encode(GameplaySettings.defaults())
		ms.setup_complete = true
	if _park.size() != 3:
		return
	for player: Player in get_tree().get_nodes_in_group("players"):
		if player.sync.has_authority():
			player.global_position = Vector3(float(_park[0]), float(_park[1]), float(_park[2]))
			player.velocity = Vector3.ZERO


func _write_observation() -> void:
	var session: Node = main.quan_tro.get_node("Session")
	var players: Array[Dictionary] = []
	for player: Player in get_tree().get_nodes_in_group("players"):
		players.append({"id": player.player_id(), "owner": player.sync.has_authority(),
			"life": player.minigame_life(), "visible": player.model_root.visible,
			"position": [player.position.x, player.position.y, player.position.z]})
	var phase: String = str(session.state.get("phase", ""))
	if phase != _previous_phase:
		_observations.append({"phase": phase, "time": Fusion.get_network_time(), "round": session.state.get("round", 0), "snapshot": session.state.duplicate(true)})
		_previous_phase = phase
	var game: Node = main.quan_tro._game
	var angles: Array[float] = []
	if is_instance_valid(game) and game.get("san") != null and session.state.get("code", "") == "laser_leap":
		for beam: Node3D in game._beams:
			angles.append(beam.rotation.y)
	var result: Dictionary = {"role": role, "connection": Fusion.get_connection_status(),
		"id": NetManager.local_id(), "master": Fusion.is_master_client(),
		"time": Fusion.get_network_time(), "state": session.state,
		"players": players, "phases": _observations, "angles": angles,
		"clock": session.clock.text, "last_command": _last_sequence,
		"replicated_json": session.match_state().minigame_json if session.match_state() != null else "",
		"replicator_owner": session.match_state().sync.get_owner_id() if session.match_state() != null else 0,
		"arena_camera": is_instance_valid(game) and game.get("san") != null and game._cam_san().current}
	var file := FileAccess.open("res://tests/runtime/" + role + "_state.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
