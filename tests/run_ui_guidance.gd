extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var quick: Script = load("res://ui/huong_dan_nhanh.gd")
	var guide: Control = load("res://ui/bang_huong_dan.tscn").instantiate()
	root.add_child(guide)
	var controller: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	root.add_child(controller)
	for code: String in controller.danh_sach():
		check(quick.tom_tat(code).split("\n").size() == 2, "Missing concise instructions: " + code)
		guide.open_for_game(code)
		var page: Resource = guide.trang[guide._current]
		check(page.resource_path.get_file().get_basename() == quick.trang_chi_tiet(code), "Missing contextual guide: " + code)
	guide.open_overview()
	check(guide._current == 0 and guide.get_node("%HowToCloseBtn").text == "TIẾP TỤC", "Overview should be the first page")
	guide.close()
	check(not guide.visible, "Guide should close")
	check(quick.hang_gon([1, 2, 3, 4, 5, 6], 6) == [1, 2, 6], "Keep leaders and local rank")
	check(quick.hang_gon([1, 2, 3], 1) == [1, 2], "Do not duplicate local leader")
	var crown: Node = load("res://minigame/crown/crown.tscn").instantiate()
	root.add_child(crown)
	controller._game = crown
	var local: int = root.get_node("NetManager").local_id()
	controller._ids = [local, local + 1, local + 2, local + 3]
	crown._diem = {local: 0.0, local + 1: 3.0, local + 2: 2.0, local + 3: 1.0}
	controller._dung_bang_diem()
	check(controller._bang_diem.get_child_count() == 3, "Scoreboard should have at most three cards")
	crown._diem[local] = 4.0
	controller._ve_bang_diem()
	check(not controller._bang_diem.get_child(2).visible, "Hide stale third card when local player leads")
	controller._game = null
	crown.free()
	var hud: Control = load("res://ui/hud.tscn").instantiate()
	root.add_child(hud)
	hud._cap_nhat_hien_thi()
	check(not hud.hint_row.visible and not hud.get_node("%CamHint").visible, "Permanent notes should be hidden")
	controller._dang_chay = true
	hud._nhac_bai()
	hud._nhac_poker()
	check(hud.card_prompt.text.is_empty() and not hud.poker_bar.visible, "Lobby prompts should not leak into minigames")
	controller._dang_chay = false
	var status: Control = hud.trang_thai_ca_nhan
	status._tt = {"do": {}, "su_kien": "Test event"}
	status._ve_thanh_duoi()
	check(not status._thanh_duoi.visible, "Empty bag should not occupy the screen")
	status._ve_su_kien()
	check(status._su_kien.visible, "New event should appear")
	status._su_kien_toi = 0.0
	status._process(0.0)
	status._ve_su_kien()
	check(not status._su_kien.visible, "Repeated state should not resurrect expired event")
	var tank: Node = load("res://minigame/tank/tank_battle.tscn").instantiate()
	root.add_child(tank)
	check(tank.giay_con_lai() < 0.0, "Inactive tank clock should be hidden")
	tank._chay = true
	tank._het_luc = tank._gio() + 75.0
	check(tank.giay_con_lai() > 74.0, "Tank should expose the common clock")
	tank.free()
	hud.free()
	controller.free()
	guide.free()
	print("UI GUIDANCE: %d failures" % failures)
	quit(0 if failures == 0 else 1)
