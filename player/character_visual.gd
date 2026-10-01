class_name CharacterVisual
extends RefCounted

## One visual pipeline for the menu preview, lobby picker and replicated Player.
## All five archetypes share KayKit's Rig_Medium skeleton, so one animation library
## can drive every model without maintaining five copies of the same clips.

const ARCHETYPE_NAMES: PackedStringArray = [
	"VỆ BINH", "PHÁP SƯ", "XẠ THỦ", "KẺ LỪA ĐẢO", "CHIẾN BINH XƯƠNG",
]

const ARCHETYPE_SCENES: Array[PackedScene] = [
	preload("res://player/characters/Knight.tscn"),
	preload("res://player/characters/Mage.tscn"),
	preload("res://player/characters/Ranger.tscn"),
	preload("res://player/characters/Rogue_Hooded.tscn"),
	preload("res://player/characters/Skeleton_Warrior.tscn"),
]

const MOVEMENT_SOURCE := preload(
		"res://asset/KayKit_Adventurers_2.0_FREE/Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb")
const GENERAL_SOURCE := preload(
		"res://asset/KayKit_Adventurers_2.0_FREE/Animations/gltf/Rig_Medium/Rig_Medium_General.glb")

const ANIMATION_MAP := {
	"idle": [GENERAL_SOURCE, "Idle_A"],
	"walk": [MOVEMENT_SOURCE, "Walking_A"],
	"sprint": [MOVEMENT_SOURCE, "Running_A"],
	"jump": [MOVEMENT_SOURCE, "Jump_Full_Short"],
	"fall": [MOVEMENT_SOURCE, "Jump_Idle"],
	"crouch": [GENERAL_SOURCE, "PickUp"],
	"holding-right": [GENERAL_SOURCE, "Idle_A"],
	"holding-left": [GENERAL_SOURCE, "Idle_A"],
	"holding-both": [GENERAL_SOURCE, "Idle_A"],
}

const ACCESSORY_WORDS: PackedStringArray = [
	"cape", "cloak", "helmet", "visor", "hat", "quiver", "mask",
]
const ACCENT_WORDS: PackedStringArray = [
	"cape", "cloak", "helmet", "visor", "hat", "quiver", "mask", "eyes",
]


static func archetype_count() -> int:
	return ARCHETYPE_SCENES.size()


static func instantiate_archetype(index: int) -> Node3D:
	return ARCHETYPE_SCENES[posmod(index, ARCHETYPE_SCENES.size())].instantiate() as Node3D


## Attach the shared animation clips to the raw glTF root inside a wrapper scene.
## Track paths in KayKit begin at Rig_Medium, so the AnimationPlayer must be a sibling
## of Rig_Medium rather than a child of the wrapper node.
static func attach_animations(wrapper: Node3D) -> AnimationPlayer:
	var rig := wrapper.find_child("Rig_Medium", true, false) as Node3D
	if rig == null:
		return null
	var raw_root := rig.get_parent()
	var existing := raw_root.get_node_or_null("PartyAnimationPlayer") as AnimationPlayer
	if existing != null:
		return existing

	var player := AnimationPlayer.new()
	player.name = "PartyAnimationPlayer"
	player.root_node = NodePath("..")
	raw_root.add_child(player)
	var library := AnimationLibrary.new()
	player.add_animation_library("", library)

	for target_name: String in ANIMATION_MAP:
		var spec: Array = ANIMATION_MAP[target_name]
		var source_scene := spec[0] as PackedScene
		var source_name := spec[1] as String
		var source_root := source_scene.instantiate()
		var source_player := source_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if source_player != null and source_player.has_animation(source_name):
			library.add_animation(target_name,
					source_player.get_animation(source_name).duplicate(true) as Animation)
		source_root.free()

	# KayKit Free does not ship a chair clip. Build a stable chair pose from Idle_A:
	# lower the hips, rotate thighs forward and bend both knees to ninety-ish degrees.
	var pose_source_root := GENERAL_SOURCE.instantiate()
	var pose_player := pose_source_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if pose_player != null and pose_player.has_animation("Idle_A"):
		library.add_animation("sit", _seated_pose(pose_player.get_animation("Idle_A")))
	pose_source_root.free()

	return player


static func _seated_pose(source: Animation) -> Animation:
	var pose := Animation.new()
	pose.length = 1.0
	pose.loop_mode = Animation.LOOP_LINEAR
	for source_track in source.get_track_count():
		var type := source.track_get_type(source_track)
		var path := source.track_get_path(source_track)
		var path_text := str(path)
		var value: Variant
		match type:
			Animation.TYPE_POSITION_3D:
				value = source.position_track_interpolate(source_track, 0.0)
				if path_text.ends_with(":hips"):
					value = Vector3(0.0, 0.20, -0.10)
			Animation.TYPE_ROTATION_3D:
				var rotation := source.rotation_track_interpolate(source_track, 0.0)
				if path_text.contains(":upperleg."):
					rotation *= Quaternion(Vector3.RIGHT, deg_to_rad(-72.0))
				elif path_text.contains(":lowerleg."):
					rotation *= Quaternion(Vector3.RIGHT, deg_to_rad(82.0))
				value = rotation
			Animation.TYPE_SCALE_3D:
				value = source.scale_track_interpolate(source_track, 0.0)
			Animation.TYPE_VALUE:
				value = source.value_track_interpolate(source_track, 0.0)
			_:
				continue
		var track := pose.add_track(type)
		pose.track_set_path(track, path)
		pose.track_insert_key(track, 0.0, value)
		pose.track_insert_key(track, 1.0, value)
	return pose


static func apply_customization(root: Node3D, primary: Color, accent: Color,
		accessory_enabled: bool) -> void:
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_name := String(mesh.name).to_lower()
		mesh.visible = accessory_enabled or not _contains_any(mesh_name, ACCESSORY_WORDS)
		var tint := accent if _contains_any(mesh_name, ACCENT_WORDS) else primary
		# Keep faces/skin readable. Skeleton heads remain bone-white; only outfit parts tint.
		if "head" in mesh_name or "jaw" in mesh_name:
			continue
		for surface in mesh.get_surface_override_material_count():
			var source := mesh.get_active_material(surface)
			if source == null:
				continue
			var material := source.duplicate(true)
			if material is BaseMaterial3D:
				(material as BaseMaterial3D).albedo_color = tint
				mesh.set_surface_override_material(surface, material)


static func set_accessory_enabled(root: Node3D, enabled: bool) -> void:
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if _contains_any(String(mesh.name).to_lower(), ACCESSORY_WORDS):
			mesh.visible = enabled


static func _contains_any(value: String, words: PackedStringArray) -> bool:
	for word in words:
		if word in value:
			return true
	return false
