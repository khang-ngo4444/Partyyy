extends RefCounted

const SOURCE_ROOT := "res://asset/KayKit_Character_Animations_1.1_FREE/Animations/gltf/Rig_Medium/"
const CLIPS := {
	"idle": ["General", "Idle_A", true],
	"walk": ["MovementBasic", "Walking_A", true],
	"sprint": ["MovementBasic", "Running_A", true],
	"jump": ["MovementBasic", "Jump_Start", false],
	"fall": ["MovementBasic", "Jump_Idle", true],
	"land": ["MovementBasic", "Jump_Land", false],
	"attack": ["CombatMelee", "Melee_Unarmed_Attack_Punch_A", false],
	"kick": ["CombatMelee", "Melee_Unarmed_Attack_Kick", false],
	"shoot": ["CombatRanged", "Ranged_Magic_Shoot", false],
	"hit": ["General", "Hit_A", false],
	"stun": ["General", "Hit_B", true],
	"knockdown": ["General", "Death_B", false],
	"death": ["General", "Death_A", false],
	"death_pose": ["General", "Death_A_Pose", true],
	"spawn": ["General", "Spawn_Ground", false],
	"get_up": ["Simulation", "Lie_StandUp", false],
	"sit": ["Simulation", "Sit_Chair_Idle", true],
	"crouch": ["MovementAdvanced", "Crouching", true],
	"holding-right": ["Tools", "Holding_A", true],
	"holding-left": ["Tools", "Holding_B", true],
	"holding-both": ["Tools", "Holding_C", true],
}
static var _library: AnimationLibrary


static func bind(player: AnimationPlayer) -> void:
	if player == null or player.has_meta("kaykit_standard"):
		return
	if player.has_animation_library(""):
		player.remove_animation_library("")
	player.add_animation_library("", library())
	player.set_meta("kaykit_standard", true)


static func library() -> AnimationLibrary:
	if _library != null:
		return _library
	_library = AnimationLibrary.new()
	var sources: Dictionary = {}
	for alias: String in CLIPS:
		var specification: Array = CLIPS[alias]
		var category: String = specification[0]
		if not sources.has(category):
			var scene: PackedScene = load(SOURCE_ROOT + "Rig_Medium_" + category + ".glb")
			sources[category] = scene.instantiate()
		var source: Node = sources[category]
		var animator := source.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if animator == null:
			push_error("KayKit source has no AnimationPlayer: " + category)
			continue
		var clip := animator.get_animation(str(specification[1])).duplicate() as Animation
		clip.loop_mode = Animation.LOOP_LINEAR if bool(specification[2]) else Animation.LOOP_NONE
		_normalize_tracks(clip)
		_library.add_animation(alias, clip)
	for source: Node in sources.values():
		source.free()
	return _library


static func _normalize_tracks(clip: Animation) -> void:
	for track: int in range(clip.get_track_count() - 1, -1, -1):
		var path := clip.track_get_path(track)
		if path.get_subname_count() != 1:
			clip.remove_track(track)
			continue
		var bone := str(path.get_subname(0))
		clip.track_set_path(track, NodePath("Rig_Medium/Skeleton3D:" + bone))
		# Physics owns root motion; animations only move the rig inside the avatar.
		if bone == "root" and clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
			for key: int in clip.track_get_key_count(track):
				clip.track_set_key_value(track, key, Vector3.ZERO)
