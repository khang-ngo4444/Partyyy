@tool
extends McpTestSuite


func suite_name() -> String:
	return "gameplay_rules"


func test_default_settings_total_one_hundred() -> void:
	var settings := GameplaySettings.defaults()
	assert_true(GameplaySettings.valid(settings))
	assert_eq(GameplaySettings.percent_total(settings), 100)


func test_every_player_starts_on_same_tile() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22, 33], {}, settings)
	for id in [11, 22, 33]:
		var k := LuatBan.khoa(id)
		assert_eq(int(state["o"][k]), 0)
		assert_eq(int(state["mau"][k]), 10)
		assert_eq(int(state["tien"][k]), 0)


func test_land_money_and_equipment_tax() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	var owner := LuatBan.khoa(11)
	var visitor := LuatBan.khoa(22)
	state["tien"][visitor] = 7
	var tax_money := LuatBan.thu_thue(state, owner, visitor, LuatBan.Thue.TIEN, settings)
	assert_contains(tax_money, "7 vàng")
	assert_eq(int(state["tien"][owner]), 7)
	assert_eq(int(state["tien"][visitor]), 0)

	state["chu_dat"] = {"4": 22}
	var tax_land := LuatBan.thu_thue(state, owner, visitor, LuatBan.Thue.DAT, settings)
	assert_contains(tax_land, "ô 4")
	assert_eq(int(state["chu_dat"]["4"]), 11)

	LuatBan.them_do(state, visitor, "khien")
	var tax_item := LuatBan.thu_thue(state, owner, visitor, LuatBan.Thue.TRANG_BI, settings)
	assert_contains(tax_item, "Khiên")
	assert_contains(state["do"][owner], "khien")


func test_land_tax_choice_survives_next_round() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	state["chu_dat"] = {"4": 11}
	state["thue_dat"] = {"4": LuatBan.Thue.MAU}
	var next_round := LuatBan.trang_thai_moi([22, 11], state, settings)
	assert_eq(int(next_round["chu_dat"]["4"]), 11)
	assert_eq(int(next_round["thue_dat"]["4"]), LuatBan.Thue.MAU)


func test_minigame_rewards_weapon_then_decreasing_gold() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22, 33], {}, settings)
	var reward := LuatBan.thuong_minigame(state, [33, 22, 11], settings)
	assert_contains(reward, "Súng một phát")
	assert_contains(state["do"][LuatBan.khoa(33)], "sung_1_phat")
	assert_eq(int(state["tien"][LuatBan.khoa(22)]), 30)
	assert_eq(int(state["tien"][LuatBan.khoa(11)]), 20)
