@tool
extends McpTestSuite

const CAC_MA_MINIGAME: Array[String] = [
	"tank_battle", "breaking_blocks", "laser_leap", "spotlights", "explosive", "magma", "crown",
	"word_wars", "dem_thu", "lo_da", "toy_factory", "wave_hide", "minefield", "paint",
]


func suite_name() -> String:
	return "am_thanh"


func test_lobby_yields_to_the_music_box() -> void:
	assert_eq(BangAmThanh.khoa_nhac(false, false, false, "", ""), "")


func test_idle_lobby_plays_its_own_music() -> void:
	assert_eq(BangAmThanh.khoa_nhac(false, true, false, "", ""), "sanh/choi")


func test_menu_plays_its_own_music() -> void:
	assert_eq(BangAmThanh.khoa_nhac(true, false, false, "", ""), "menu/choi")


func test_board_plays_its_own_music() -> void:
	assert_eq(BangAmThanh.khoa_nhac(false, false, true, "", ""), "ban_co/choi")


func test_board_overrides_lobby_music() -> void:
	assert_eq(BangAmThanh.khoa_nhac(false, true, true, "", ""), "ban_co/choi")


func test_minigame_overrides_board_music() -> void:
	assert_eq(BangAmThanh.khoa_nhac(false, false, true, "paint", BangAmThanh.PHA_CHOI), "paint/choi")


func test_minigame_started_from_lobby_has_music() -> void:
	assert_eq(BangAmThanh.khoa_nhac(false, true, false, "crown", BangAmThanh.PHA_DEM_NGUOC), "crown/dem_nguoc")


func test_only_result_sting_does_not_loop() -> void:
	assert_true(BangAmThanh.co_lap("paint/choi"))
	assert_true(BangAmThanh.co_lap("paint/dem_nguoc"))
	assert_false(BangAmThanh.co_lap("paint/ket_qua"))


func test_missing_phase_falls_back_to_gameplay_track() -> void:
	var ung_vien := BangAmThanh.ung_vien_nhac("paint/ket_qua")
	assert_eq(ung_vien[0], "res://asset/audio/nhac/paint/ket_qua.ogg")
	assert_true(ung_vien.has("res://asset/audio/nhac/paint/choi.ogg"))
	assert_eq(ung_vien.find("res://asset/audio/nhac/paint/choi.ogg"), BangAmThanh.DUOI_FILE.size())


func test_replacement_formats_are_searched() -> void:
	var ung_vien := BangAmThanh.ung_vien_sfx(BangAmThanh.SFX_NO)
	assert_true(ung_vien.has("res://asset/audio/sfx/no.mp3"))
	assert_true(ung_vien.has("res://asset/audio/sfx/no.wav"))


func test_missing_file_resolves_to_empty_path() -> void:
	assert_eq(BangAmThanh.tim_file(PackedStringArray(["res://asset/audio/khong_co.ogg"])), "")


func test_every_minigame_has_a_full_music_set() -> void:
	for ma: String in CAC_MA_MINIGAME:
		for pha: String in [BangAmThanh.PHA_DEM_NGUOC, BangAmThanh.PHA_CHOI, BangAmThanh.PHA_KET_QUA]:
			var khoa := "%s/%s" % [ma, pha]
			assert_eq(BangAmThanh.tim_file(BangAmThanh.ung_vien_nhac(khoa)), "res://asset/audio/nhac/%s.ogg" % khoa)


func test_board_menu_and_lobby_have_music() -> void:
	assert_eq(BangAmThanh.tim_file(BangAmThanh.ung_vien_nhac("sanh/choi")), "res://asset/audio/nhac/sanh/choi.ogg")
	assert_eq(BangAmThanh.tim_file(BangAmThanh.ung_vien_nhac("ban_co/choi")), "res://asset/audio/nhac/ban_co/choi.ogg")
	assert_eq(BangAmThanh.tim_file(BangAmThanh.ung_vien_nhac("menu/choi")), "res://asset/audio/nhac/menu/choi.ogg")


func test_every_sfx_has_a_file() -> void:
	for ten: StringName in BangAmThanh.TAT_CA_SFX:
		assert_eq(BangAmThanh.tim_file(BangAmThanh.ung_vien_sfx(ten)), "res://asset/audio/sfx/%s.ogg" % ten)


func test_leaving_window_mutes_only_when_option_is_on() -> void:
	assert_true(BangAmThanh.tat_master(false, true, true))
	assert_false(BangAmThanh.tat_master(false, false, true))
	assert_false(BangAmThanh.tat_master(false, true, false))


func test_returning_to_window_keeps_zero_volume_muted() -> void:
	assert_true(BangAmThanh.tat_master(true, true, false))
	assert_true(BangAmThanh.tat_master(true, false, false))


func test_first_board_state_is_silent() -> void:
	assert_eq(BangAmThanh.su_kien_ban({}, {"luot": 0, "tien": {"p1": 5}}), [] as Array[StringName])


func test_board_state_changes_map_to_sfx() -> void:
	var cu := {"luot": 0, "tien": {"p1": 5, "p2": 5}, "coc": {"p1": 0}, "mau": {"p1": 10}}
	var chi_doi_luot := {"luot": 1, "tien": cu.tien, "coc": cu.coc, "mau": cu.mau}
	assert_eq(BangAmThanh.su_kien_ban(cu, chi_doi_luot), [BangAmThanh.SFX_LUOT_MOI] as Array[StringName])
	var doi_het := {"luot": 0, "tien": {"p1": 5, "p2": 9}, "coc": {"p1": 1}, "mau": {"p1": 7}}
	assert_eq(BangAmThanh.su_kien_ban(cu, doi_het),
		[BangAmThanh.SFX_NHAN_TIEN, BangAmThanh.SFX_NHAN_CUP, BangAmThanh.SFX_MAT_MAU] as Array[StringName])


func test_spending_gold_and_healing_are_silent() -> void:
	var cu := {"luot": 0, "tien": {"p1": 5}, "mau": {"p1": 3}}
	var moi := {"luot": 0, "tien": {"p1": 2}, "mau": {"p1": 10}}
	assert_eq(BangAmThanh.su_kien_ban(cu, moi), [] as Array[StringName])


func test_player_joining_does_not_count_as_a_gain() -> void:
	var cu := {"luot": 0, "tien": {"p1": 5}}
	var moi := {"luot": 0, "tien": {"p1": 5, "p2": 50}}
	assert_eq(BangAmThanh.su_kien_ban(cu, moi), [] as Array[StringName])
