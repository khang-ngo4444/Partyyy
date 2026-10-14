extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var runner: RefCounted = load("res://addons/godot_ai/testing/test_runner.gd").new()
	runner.run_suite(load("res://tests/test_word_wars_pool.gd").new())
	runner.run_suite(load("res://tests/test_gameplay_rules.gd").new())
	runner.run_suite(load("res://tests/test_shared_minigames.gd").new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	var pool_ok: bool = _check_pool_decode()
	var physics_ok: bool = await _check_corridors()
	quit(1 if int(results.get("failed", 0)) > 0 or not physics_ok or not pool_ok else 0)

func _check_corridors() -> bool:
	var arena: Node3D = load("res://minigame/word_wars/san_chu.tscn").instantiate()
	root.add_child(arena)
	var body := CharacterBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	body.add_child(collision)
	root.add_child(body)
	body.position = Vector3(-13, 0.21, -8)
	await physics_frame
	await physics_frame
	var hit := body.move_and_collide(Vector3(4, 0, 0))
	var blocks_path := hit != null and hit.get_collider() == arena.get_node("Bang/OA/Than")
	body.position = Vector3(-11.55, 0.21, -8)
	await physics_frame
	await physics_frame
	var button_reachable: bool = arena.get_node("Bang/OA/Vung").overlaps_body(body)
	body.position = Vector3(-8, 0.21, -11)
	await physics_frame
	var corridor_clear := body.move_and_collide(Vector3(0, 0, 22)) == null
	var oa: Node3D = arena.get_node("Bang/OA")
	oa.nhan()
	await create_timer(0.35).timeout
	var button_recovers := is_equal_approx(oa.get_node("Mat").position.y, 1.6)
	var labels_ready: bool = arena.get_node("Bang/OZ/Chu").text == "Z"
	print(JSON.stringify({"blocks_path": blocks_path, "button_reachable": button_reachable,
		"corridor_clear": corridor_clear, "button_recovers": button_recovers, "labels_ready": labels_ready}))
	body.free()
	arena.free()
	return blocks_path and button_reachable and corridor_clear and button_recovers and labels_ready

func _check_pool_decode() -> bool:
	var state: Node = load("res://net/match_state.tscn").instantiate()
	root.add_child(state)
	state.set_process(false)
	var controller: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	root.add_child(controller)
	var passed := true
	for encoded: String in ["", "   ", "{broken", "null", "[]"]:
		state.minigame_pool_json = encoded
		passed = passed and controller._pool_state().is_empty()
	state.minigame_pool_json = '{"played":["paint"]}'
	passed = passed and controller._pool_state() == {"played": ["paint"]}
	controller.free()
	state.free()
	print("POOL DECODE: ", passed)
	return passed
