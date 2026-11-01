extends SceneTree

## Mọi clip khai báo phải nạp được, chạy được trên nhân vật thật và thật sự làm xương cử động.

const KayKitAnimations = preload("res://player/kaykit_animations.gd")
const AnimationState = preload("res://player/animation_state.gd")
const CHARACTER := "res://player/characters/Knight.tscn"
const CLIP_DONG := ["dance", "victory", "defeat", "stun", "hot_feet", "panic_run", "balance", "carry_idle", "carry_run"]
const CLIP_SU_KIEN := ["pickup", "throw", "interact"]
const DO_LECH_TOI_THIEU := 0.05

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var library := KayKitAnimations.library()
	for ten: String in KayKitAnimations.CLIPS:
		check(library.has_animation(ten), "%s loads" % ten)
		if library.has_animation(ten):
			check(library.get_animation(ten).length > 0.0, "%s has a length" % ten)
	var nhan_vat: Node3D = load(CHARACTER).instantiate()
	root.add_child(nhan_vat)
	var animator := CharacterVisual.hoat_anh_cua(nhan_vat)
	var xuong := nhan_vat.find_child("Skeleton3D", true, false) as Skeleton3D
	for ten: String in CLIP_DONG:
		_kiem_tra_cu_dong(animator, xuong, ten)
		check(library.get_animation(ten).loop_mode == Animation.LOOP_LINEAR, "%s loops" % ten)
	for ten: String in CLIP_SU_KIEN:
		_kiem_tra_cu_dong(animator, xuong, ten)
	_kiem_tra_uu_tien(animator)
	print("HOAT ANH: %d failures" % failures)
	quit(failures)


## Clip phải đổi tư thế xương so với idle và mọi track phải trỏ đúng xương.
func _kiem_tra_cu_dong(animator: AnimationPlayer, xuong: Skeleton3D, ten: String) -> void:
	var clip := animator.get_animation(ten)
	for track in clip.get_track_count():
		var bone := str(clip.track_get_path(track).get_subname(0))
		check(xuong.find_bone(bone) >= 0, "%s drives a real bone: %s" % [ten, bone])
	animator.play("idle")
	animator.seek(0.0, true)
	var goc := _tu_the(xuong)
	animator.play(ten)
	animator.seek(clip.length * 0.25, true)
	var lech := 0.0
	var moi := _tu_the(xuong)
	for i in goc.size():
		lech = maxf(lech, goc[i].angle_to(moi[i]))
	check(lech > DO_LECH_TOI_THIEU, "%s visibly moves the rig (%.3f)" % [ten, lech])


func _tu_the(xuong: Skeleton3D) -> Array[Quaternion]:
	var ra: Array[Quaternion] = []
	for i in xuong.get_bone_count():
		ra.append(xuong.get_bone_pose_rotation(i))
	return ra


func _kiem_tra_uu_tien(animator: AnimationPlayer) -> void:
	var trang_thai := AnimationState.new(animator)
	trang_thai.request("defeat", 3.0)
	trang_thai.request("throw")
	trang_thai.tick("idle")
	check(animator.current_animation == "defeat", "Result pose is not interrupted by a late action")
	trang_thai.clear()
	trang_thai.tick("idle")
	check(animator.current_animation == "idle", "Clearing returns to locomotion")
