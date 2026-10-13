extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var visual: Script = load("res://player/character_visual.gd")
	var states: Script = load("res://player/animation_state.gd")
	var clips: Script = load("res://player/kaykit_animations.gd")
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var arena: Node3D = load("res://minigame/machine_playground/toy_factory_arena.tscn").instantiate()
	fixture.add_child(arena)
	var models: Array = []
	var names := ["Knight", "Mage", "Ranger", "Rogue_Hooded", "Barbarian", "Rogue",
		"Skeleton_Warrior", "Skeleton_Mage", "Skeleton_Minion", "Skeleton_Rogue"]
	for index in names.size():
		var name: String = names[index]
		var model: Node3D = load("res://player/characters/%s.tscn" % name).instantiate()
		fixture.add_child(model)
		model.position = Vector3((index % 5 - 2) * 3.0, 0, (index / 5) * 3.0)
		models.append(model)
		var animator: AnimationPlayer = visual.hoat_anh_cua(model)
		var skeleton: Skeleton3D = model.get_node("Model/Rig_Medium/Skeleton3D")
		for alias: String in clips.CLIPS:
			check(animator.has_animation(alias), name + " missing " + alias)
			var clip: Animation = animator.get_animation(alias)
			for track in clip.get_track_count():
				var path := clip.track_get_path(track)
				check(skeleton.find_bone(str(path.get_subname(0))) >= 0, name + " unresolved bone " + str(path))
		var state: RefCounted = states.new(animator)
		state.tick("walk")
		animator.advance(0.3)
		var walking: Quaternion = skeleton.get_bone_pose_rotation(skeleton.find_bone("upperleg.l"))
		state.tick("idle")
		animator.advance(0.3)
		check(not walking.is_equal_approx(skeleton.get_bone_pose_rotation(skeleton.find_bone("upperleg.l"))), name + " walking must move the rig")
		state.request("stun", 0.9)
		state.request("attack")
		state.tick("sprint")
		check(animator.current_animation == "stun", "Attack and movement cannot override stun")
		state.request("death")
		state.request("hit")
		state.tick("sprint")
		check(state.dying() and animator.current_animation == "death", "Death has priority over damage and movement")
		state._until = -1
		state.tick("idle")
		check(animator.current_animation == "spawn", "Death transitions to respawn")
		state._until = -1
		state.tick("sprint")
		check(animator.current_animation == "sprint", "Movement resumes after reactions")
		animator.play("idle")
		animator.advance(0.3)
	var rules: Script = load("res://board/luat_ban.gd")
	var settings: Dictionary = GameplaySettings.defaults()
	var data: Dictionary = rules.trang_thai_moi([1], {}, settings)
	check(not rules.tru_mau(data, "1", 2), "Nonlethal damage")
	check(data.animation_events["1"].kind == "hit", "Nonlethal damage emits hit")
	check(rules.tru_mau(data, "1", 100), "Lethal damage")
	rules.chet(data, "1", settings)
	check(data.mau["1"] == 10 and data.animation_events["1"].kind == "death", "Death must remain visible despite instant HP restoration")
	var next: Dictionary = rules.trang_thai_moi([1], data, settings)
	check(next.animation_events["1"].serial == data.animation_events["1"].serial, "Reaction serial survives new board rounds")
	rules.them_do(next, "1", "khien")
	var serial: int = next.animation_events["1"].serial
	rules.tru_mau(next, "1", 3)
	check(next.animation_events["1"].serial == serial, "Blocked damage should not produce a hit")
	var board: Node = load("res://board/pha_ban_co.gd").new()
	check(board._take_reactions(data.animation_events).is_empty(), "Joining a board does not replay historical reactions")
	rules.animation_event(data, "1", "hit")
	check(board._take_reactions(data.animation_events).get("1") == "hit", "Fresh replicated hit is presented")
	check(board._take_reactions(data.animation_events).is_empty(), "Snapshots cannot repeat the same reaction")
	board.free()
	await _check_phase_reactions(fixture, states, visual, rules, settings)
	if OS.get_cmdline_user_args().has("--capture"):
		for model: Node3D in models:
			model.rotation.y = PI
		arena.get_node("Cam").position = Vector3(0, 6, 11)
		arena.get_node("Cam").look_at(Vector3(0, 1, 0))
		arena.get_node("Cam").make_current()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/runtime/kaykit_preview.png")
	fixture.free()
	print("KAYKIT ANIMATION: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _check_phase_reactions(fixture: Node3D, states: Script, visual: Script, rules: Script, settings: Dictionary) -> void:
	var id: int = root.get_node("NetManager").local_id()
	var actors: Array = []
	for actor_id: int in [id, id + 1]:
		var actor: Node3D = load("res://player/player.tscn").instantiate()
		actor.set_script(load("res://tests/fixtures/spot_player.gd"))
		actor.test_id = actor_id
		fixture.add_child(actor)
		actor._anim = visual.hoat_anh_cua(actor.model_root.get_child(0))
		actor._animation_state = states.new(actor._anim)
		actors.append(actor)
	var game: Node = load("res://minigame/chung/mini_game_3d.gd").new()
	fixture.add_child(game)
	game._chay = true
	game._song = {id: -1, id + 1: -1}
	game.set_process(false)
	game._net_danh(id + 1, id, Vector3.RIGHT, 0)
	actors[0]._animation_state.tick("sprint")
	actors[1]._animation_state.tick("idle")
	check(actors[0]._anim.current_animation == "stun", "Phase 3 hit applies stun animation to victim")
	check(actors[1]._anim.current_animation == "attack", "Phase 3 attack animates the source on all clients")
	game.free()
	var board: Node = load("res://board/pha_ban_co.gd").new()
	fixture.add_child(board)
	board.tt = rules.trang_thai_moi([id], {}, settings)
	board.ban = load("res://board/ban_party.tscn").instantiate()
	fixture.add_child(board.ban)
	actors[0].play_reaction("death")
	actors[0]._animation_state.tick("idle")
	var before: Vector3 = actors[0].global_position
	board._dat_len_o(id, 0)
	check(actors[0].global_position == before, "Phase 2 death pose remains at impact before checkpoint warp")
	# Headless frames run faster than wall time; reaction deadlines use wall time.
	OS.delay_msec(850)
	await create_timer(0.9).timeout
	check(actors[0].global_position.distance_to(board.vi_tri_dung(id, 0)) < 0.01, "Phase 2 returns avatar to checkpoint after death clip")
	board.ban.free()
	board.free()
	for actor: Node in actors:
		actor.free()
