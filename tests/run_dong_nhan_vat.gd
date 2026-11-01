extends SceneTree

## Nhân vật di chuyển theo nhịp vật lý 60Hz, màn hình vẽ 120Hz: clip chạy phải chạy liền mạch.
## Trước đây khung không có bước vật lý bị coi là đứng yên, clip bị chơi lại từ đầu liên tục.

const AnimationState = preload("res://player/animation_state.gd")
const GIAY_MOI_KHUNG_VE := 1.0 / 120.0
const KHUNG_VE_MOI_BUOC_VAT_LY := 2
const TOC_CHAY := 6.0
const SO_KHUNG := 240
const DO_XOAY_TOI_THIEU := 0.3

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var nguoi: Node3D = load("res://player/player.tscn").instantiate()
	nguoi.set_script(load("res://tests/fixtures/spot_player.gd"))
	nguoi.test_id = 1
	fixture.add_child(nguoi)
	await process_frame
	nguoi.set_process(false)
	nguoi.set_physics_process(false)
	var animator: AnimationPlayer = CharacterVisual.hoat_anh_cua(nguoi.model_root.get_child(0))
	nguoi._anim = animator
	nguoi._animation_state = AnimationState.new(animator)
	var xuong := nguoi.model_root.get_child(0).find_child("Skeleton3D", true, false) as Skeleton3D
	var dui := xuong.find_bone("upperleg.l")
	var so_lan_doi := 0
	var truoc := ""
	var it_nhat := Quaternion.IDENTITY
	var goc_lon_nhat := 0.0
	for khung in SO_KHUNG:
		if khung % KHUNG_VE_MOI_BUOC_VAT_LY == 0:
			nguoi.global_position += Vector3.FORWARD * TOC_CHAY * GIAY_MOI_KHUNG_VE * KHUNG_VE_MOI_BUOC_VAT_LY
		nguoi._process(GIAY_MOI_KHUNG_VE)
		animator.advance(GIAY_MOI_KHUNG_VE)
		if khung < 30:
			continue
		if animator.current_animation != truoc:
			if truoc != "":
				so_lan_doi += 1
			truoc = animator.current_animation
		if it_nhat == Quaternion.IDENTITY:
			it_nhat = xuong.get_bone_pose_rotation(dui)
		goc_lon_nhat = maxf(goc_lon_nhat, it_nhat.angle_to(xuong.get_bone_pose_rotation(dui)))
	check(truoc == "sprint", "Runs with the sprint clip, got %s" % truoc)
	check(so_lan_doi == 0, "Clip must not restart while running: %d switches" % so_lan_doi)
	check(goc_lon_nhat > DO_XOAY_TOI_THIEU, "Legs really swing: %.3f rad" % goc_lon_nhat)
	print("DONG NHAN VAT: %d failures" % failures)
	quit(failures)
