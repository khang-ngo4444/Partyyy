class_name CharacterVisual
extends RefCounted

const KayAnimations = preload("res://player/kaykit_animations.gd")

## Hình nhân vật dùng chung (preview menu, chọn nhân vật, Player): nhuộm màu, phụ kiện,
## lấy AnimationPlayer. Năm nhân vật dùng chung clip KayKit Rig Medium đã chuẩn hoá.

const ARCHETYPE_NAMES: PackedStringArray = [
	"VỆ BINH", "PHÁP SƯ", "XẠ THỦ", "KẺ LỪA ĐẢO", "MAN DI",
]

const ACCESSORY_WORDS: PackedStringArray = [
	"cape", "cloak", "helmet", "visor", "hat", "quiver", "mask",
]
const ACCENT_WORDS: PackedStringArray = [
	"cape", "cloak", "helmet", "visor", "hat", "quiver", "mask", "eyes",
]


static func hoat_anh_cua(wrapper: Node3D) -> AnimationPlayer:
	var animator := wrapper.find_child("PartyAnimationPlayer", true, false) as AnimationPlayer
	KayAnimations.bind(animator)
	return animator


static func apply_customization(root: Node3D, primary: Color, accent: Color,
		accessory_enabled: bool) -> void:
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_name := String(mesh.name).to_lower()
		mesh.visible = accessory_enabled or not _contains_any(mesh_name, ACCESSORY_WORDS)
		var tint := accent if _contains_any(mesh_name, ACCENT_WORDS) else primary
		# Giữ màu da/mặt; chỉ nhuộm trang phục.
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
