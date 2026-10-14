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
	assert_contains(tax_item, "Úp thúng")
	assert_contains(state["do"][owner], "khien")


func test_land_tax_choice_survives_next_round() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	state["chu_dat"] = {"4": 11}
	state["thue_dat"] = {"4": LuatBan.Thue.MAU}
	var next_round := LuatBan.trang_thai_moi([22, 11], state, settings)
	assert_eq(int(next_round["chu_dat"]["4"]), 11)
	assert_eq(int(next_round["thue_dat"]["4"]), LuatBan.Thue.MAU)


func test_round_count_and_gold_scale_with_players() -> void:
	var settings := GameplaySettings.defaults()
	assert_eq(KinhTe.so_vong(4, settings), 14)
	assert_eq(KinhTe.so_vong(10, settings), 8)
	settings["so_vong"] = 5
	assert_eq(KinhTe.so_vong(10, settings), 5)
	settings = GameplaySettings.defaults()
	var tien: Array = []
	for hang in 4:
		tien.append(KinhTe.vang_hang(hang, 4, 14, settings))
	assert_eq(tien, [15, 15, 10, 10])


func test_minigame_reward_gold_and_items_survive_new_round() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22, 33], {}, settings)
	state["so_vong"] = KinhTe.so_vong(3, settings)
	var rng := RandomNumberGenerator.new()
	var reward := KinhTe.thuong_minigame(state, [33, 22, 11], settings, rng)
	assert_contains(reward, "Hạng 1 +15 vàng")
	assert_eq(int(state["tien"][LuatBan.khoa(22)]), 10)
	assert_eq((state["do"][LuatBan.khoa(33)] as Array).size(), 1)
	assert_eq((state["do"][LuatBan.khoa(11)] as Array).size(), 1)
	var next_round := LuatBan.trang_thai_moi([33, 22, 11], state, settings)
	assert_eq((next_round["do"][LuatBan.khoa(33)] as Array).size(), 1)


func test_chest_gives_cup_and_most_cups_wins() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	state["tien"][LuatBan.khoa(11)] = 99
	assert_eq(LuatRuong.mo(state, LuatBan.khoa(11), settings), "")
	state["tien"][LuatBan.khoa(22)] = 130
	assert_contains(LuatRuong.mo(state, LuatBan.khoa(22), settings), "+1 Cúp")
	assert_eq(int(state["tien"][LuatBan.khoa(22)]), 30)
	var next_round := LuatBan.trang_thai_moi([11, 22], state, settings)
	assert_eq(int(next_round["coc"][LuatBan.khoa(22)]), 1)
	assert_eq(LuatRuong.nguoi_thang(next_round), 22)


func test_slingshot_miss_shield_and_hit() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	var ten := func(k: String) -> String: return k
	assert_contains(LuatTanCong.ban_tia(state, "11", "sung_1_phat", "", settings, ten), "trượt")
	LuatBan.them_do(state, "22", "khien")
	assert_contains(LuatTanCong.ban_tia(state, "11", "sung_1_phat", "22", settings, ten), "Úp thúng")
	assert_eq(int(state["mau"]["22"]), 10)
	assert_contains(LuatTanCong.ban_tia(state, "11", "sung_1_phat", "22", settings, ten), "-4 máu")
	assert_eq(int(state["mau"]["22"]), 6)


func test_trap_halves_remaining_steps_and_barrier_stops() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	var ten := func(k: String) -> String: return k
	state["bay"] = {"3": "22"}
	var bay := LuatBay.giam_bay(state, "11", 3, 3, settings, ten)
	assert_eq(int(bay["con"]), 2)
	assert_eq(int(state["mau"]["11"]), 8)
	assert_true(LuatBay.giam_bay(state, "11", 3, 3, settings, ten).is_empty())
	state["rao"] = {"2": "22"}
	assert_contains(LuatBay.vuong_rao(state, "11", 2, ten), "rào")
	assert_eq(LuatBay.vuong_rao(state, "11", 2, ten), "")


func test_rubber_band_halves_damage_and_snaps_back() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	state["o"]["11"] = 4
	LuatHieuUng.dat_neo(state, "11")
	state["o"]["11"] = 9
	LuatBan.tru_mau(state, "11", 4)
	assert_eq(int(state["mau"]["11"]), 8)
	assert_eq(int(state["o"]["11"]), 4)


func test_bag_limit_and_one_item_per_turn() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	for mon in ["chao_hanh", "rao_tre", "hai_hot", "ong_heo"]:
		LuatBan.them_do(state, "11", mon)
	assert_eq(state["do"]["11"], ["chao_hanh", "rao_tre", "hai_hot", "ong_heo"])
	var ten := func(k: String) -> String: return k
	LuatDo.dung(state, "11", 2, {}, null, settings, ten)
	assert_eq(str(state["hai_hot"]), "11")
	# Dùng xong ô thành trống, các ô khác giữ nguyên chỗ.
	assert_eq(state["do"]["11"], ["chao_hanh", "rao_tre", "", "ong_heo"])
	assert_contains(LuatDo.ly_do_khong_dung(state, "11", 0), "đã dùng")
	# Món mới lấp ô trống đầu tiên.
	LuatBan.them_do(state, "11", "khien")
	assert_eq(state["do"]["11"], ["chao_hanh", "rao_tre", "khien", "ong_heo"])


func test_bag_slots_full_storage_and_swap() -> void:
	var settings := GameplaySettings.defaults()
	var state := LuatBan.trang_thai_moi([11, 22], {}, settings)
	for i in VatPham.TUI_TOI_DA:
		assert_eq(LuatBan.them_do(state, "11", "rao_tre"), "")
	assert_contains(LuatBan.them_do(state, "11", "hai_hot"), "túi đầy")
	assert_eq((state["do"]["11"] as Array).size(), VatPham.TUI_TOI_DA)
	# Món trong kho không dùng trực tiếp được.
	assert_contains(LuatDo.ly_do_khong_dung(state, "11", VatPham.SO_O_NHANH), "kho")
	# Đổi chỗ kho <-> ô nhanh, kể cả ô trống.
	var state2 := LuatBan.trang_thai_moi([11, 22], {}, settings)
	LuatBan.them_do(state2, "11", "chao_hanh")
	assert_true(LuatBan.doi_cho(state2, "11", 0, 7))
	assert_eq(state2["do"]["11"], ["", "", "", "", "", "", "", "chao_hanh"])
	assert_true(LuatBan.doi_cho(state2, "11", 7, 2))
	assert_eq(state2["do"]["11"], ["", "", "chao_hanh"])
	assert_false(LuatBan.doi_cho(state2, "11", 0, VatPham.TUI_TOI_DA))
	# Thuế đồ lấy món đầu tiên có thật, bỏ qua ô trống.
	assert_eq(LuatBan.lay_mon_dau(state2, "11"), "chao_hanh")
	assert_eq(state2["do"]["11"], [])

func test_budget_includes_final_round_bonus_for_all_room_sizes() -> void:
	var settings := GameplaySettings.defaults()
	var tile_gold: float = settings.tile_money / 100.0 * settings.money_gain
	for players: int in range(1, 11):
		var rounds := KinhTe.so_vong(players, settings)
		var expected_total: float = tile_gold * rounds
		for round_number: int in range(1, rounds + 1):
			var multiplier := KinhTe.NHAN_VONG_CUOI if round_number > rounds - KinhTe.SO_VONG_CUOI else 1.0
			var previous := 999999
			for rank: int in players:
				var gold := KinhTe.vang_hang(rank, players, rounds, settings, multiplier)
				assert_true(gold >= 0 and gold <= previous)
				previous = gold
				expected_total += gold / float(players)
		assert_true(absf(expected_total - KinhTe.VANG_CA_VAN) <= 40.0)
		assert_true(absf(rounds * (KinhTe.GIAY_MINIGAME + players * KinhTe.GIAY_MOI_LUOT) - KinhTe.GIAY_MOI_VAN) <= 150.0)
	# A custom one-round match has only one boosted round, never two.
	assert_true(is_equal_approx(KinhTe.vang_trung_binh(1, settings) * 1.5 + tile_gold, KinhTe.VANG_CA_VAN))
