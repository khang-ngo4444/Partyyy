extends SceneTree

## Compatibility entry point for the focused rule and authored-scene runtime checks.
func _initialize() -> void:
	var runner: Script = load("res://tests/run_falling_floor.gd")
	set_script(runner)
	call_deferred("_run")
