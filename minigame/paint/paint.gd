extends "res://minigame/machine_playground/objective_game.gd"

const Rules = preload("res://minigame/paint/paint_rules.gd")
const PaintView = preload("res://minigame/paint/paint_view.gd")
const PAINT_HEIGHT := 0.35
const HIT_RANGE := 2.1
const HIT_PUSH := 7.0
const EVENT_GRACE := 2.0
var _view: RefCounted
var _seen_events: Dictionary = {}
var _name_colors: Dictionary = {}


func initial_shared_state(ids: Array, _seed: int) -> Dictionary:
	return Rules.initial(ids)


func _dung_san() -> void:
	_view = PaintView.new()
	_view.attach(san.get_node("Floor"), san.global_position)
	_view.present(str(shared_snapshot.objective.cells))
	var label: Label = san.get_node("HUD/Progress")
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	for index: int in shared_snapshot.ids.size():
		var player: Player = _nguoi(int(shared_snapshot.ids[index]))
		if player != null:
			_name_colors[player.player_id()] = player.name_tag.modulate
			player.name_tag.modulate = PaintView.color(index)


func _present_shared_players() -> void:
	super()
	if san == null or _view == null:
		return
	var state: Dictionary = shared_snapshot.objective
	_view.present(str(state.cells))
	var id := NetManager.local_id()
	var label: Label = san.get_node("HUD/Progress")
	label.text = "Sơn của bạn %.1f%%" % Rules.percent(state, id)
	label.modulate = PaintView.color(maxi(shared_snapshot.ids.find(id), 0))
	_consume_hit(state)


func _consume_hit(state: Dictionary) -> void:
	for key: String in state.events:
		var event: Dictionary = state.events[key]
		var serial := int(event.get("serial", 0))
		if serial <= int(_seen_events.get(key, 0)):
			continue
		_seen_events[key] = serial
		var player: Player = _nguoi(int(key))
		if player == null or gio() - float(event.time) > EVENT_GRACE:
			continue
		player.play_reaction("stun", Rules.STUN_SECONDS)
		var source := _nguoi(int(event.get("attacker", -999)))
		if source != null:
			source.play_action()
		if player.is_mine:
			var direction := Vector3(float(event.direction[0]), 0, float(event.direction[1]))
			player.day(direction * HIT_PUSH + Vector3.UP * 2.0)


func advance_shared_rules(snapshot: Dictionary, elapsed: float) -> void:
	var ids: Array = snapshot.ids
	var state: Dictionary = snapshot.objective
	# Rotate precedence for simultaneous overlap rather than privileging one roster slot.
	var first := int(elapsed * 10) % maxi(ids.size(), 1)
	for offset: int in ids.size():
		var id := int(ids[(first + offset) % ids.size()])
		var player: Player = _nguoi(id)
		if player == null or float(snapshot.alive[str(id)]) >= 0 or elapsed < float(state.stun.get(str(id), -1)):
			Rules.stop_stroke(state, id)
			continue
		var position := player.global_position - san.global_position
		if position.y < -0.1 or position.y > PAINT_HEIGHT:
			Rules.stop_stroke(state, id)
			continue
		Rules.paint(state, ids, id, Vector2(position.x, position.z))


func _luat_moi_nhip() -> void:
	var player: Player = _nguoi(NetManager.local_id())
	if player == null:
		return
	var local := player.global_position - san.global_position
	local.x = clampf(local.x, -13.4, 13.4)
	local.z = clampf(local.z, -13.4, 13.4)
	if local.y < -2:
		local.y = 1
		player.velocity = Vector3.ZERO
	player.global_position = san.global_position + local


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("danh"):
		request_action("hit")


func handle_shared_action(snapshot: Dictionary, id: int, action: String, _payload: Array, elapsed: float) -> bool:
	if action != "hit":
		return false
	var attacker: Player = _nguoi(id)
	if attacker == null or absf(attacker.global_position.y - san.global_position.y) > 4:
		return false
	var target := _hit_target(snapshot, attacker)
	if target == null:
		return false
	var direction := target.global_position - attacker.global_position
	return Rules.hit(snapshot.objective, id, target.player_id(), elapsed,
		Vector2(direction.x, direction.z).normalized())


func _hit_target(snapshot: Dictionary, attacker: Player) -> Player:
	var target: Player = null
	var nearest := HIT_RANGE
	var forward := -attacker.global_basis.z
	for candidate_id: Variant in snapshot.ids:
		if int(candidate_id) == attacker.player_id() or float(snapshot.alive[str(int(candidate_id))]) >= 0:
			continue
		var candidate: Player = _nguoi(int(candidate_id))
		if candidate == null:
			continue
		var delta := candidate.global_position - attacker.global_position
		if absf(delta.y) > 1.5:
			continue
		delta.y = 0
		if delta.length() < 0.01 or delta.length() > nearest or forward.dot(delta.normalized()) < 0.2:
			continue
		nearest = delta.length()
		target = candidate
	return target


func shared_ranking(snapshot: Dictionary) -> Array:
	return Rules.ranking(snapshot.objective, snapshot.ids, snapshot.alive)


func diem_cua(id: int) -> float:
	return Rules.percent(shared_snapshot.get("objective", {"counts": {}}), id)


func chu_diem(id: int) -> String:
	return "%.1f%%" % diem_cua(id)


func mau_cua(id: int) -> Color:
	return PaintView.color(maxi(shared_snapshot.get("ids", []).find(id), 0))


func dung_som() -> void:
	for id: Variant in _name_colors:
		var player: Player = _nguoi(int(id))
		if player != null:
			player.name_tag.modulate = _name_colors[id]
	_name_colors.clear()
	_view = null
	super()
