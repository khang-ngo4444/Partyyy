extends RefCounted

const PRIORITY := {"attack": 10, "kick": 10, "shoot": 10, "land": 10,
	"spawn": 20, "get_up": 20, "hit": 30, "knockdown": 40, "stun": 40, "death": 50}
var animator: AnimationPlayer
var _event := ""
var _until := -1.0
var _playing := ""


func _init(player: AnimationPlayer) -> void:
	animator = player


func request(kind: String, duration: float = 0.0) -> void:
	if animator == null or not animator.has_animation(kind):
		return
	if active() and int(PRIORITY.get(kind, 0)) < int(PRIORITY.get(_event, 0)):
		return
	_event = kind
	_until = now() + (duration if duration > 0 else animator.get_animation(kind).length)
	_playing = ""


func active() -> bool:
	return not _event.is_empty() and now() < _until


func dying() -> bool:
	return _event == "death" and active()


func remaining() -> float:
	return maxf(_until - now(), 0)


func clear() -> void:
	_event = ""
	_until = -1.0
	_playing = ""


func tick(locomotion: String) -> void:
	if not active() and _event == "death":
		request("spawn")
	var wanted := _event if active() else locomotion
	if wanted == _playing or not animator.has_animation(wanted):
		return
	_playing = wanted
	animator.play(wanted, 0.08)


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0
