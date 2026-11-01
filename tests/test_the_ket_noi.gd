@tool
extends McpTestSuite


func suite_name() -> String:
	return "the_ket_noi"


func test_unmeasured_ping_lights_no_bars() -> void:
	assert_eq(TheKetNoi.so_vach_ping(0), 0)


func test_ping_thresholds_map_to_bars() -> void:
	assert_eq(TheKetNoi.so_vach_ping(TheKetNoi.PING_TOT_MS), 3)
	assert_eq(TheKetNoi.so_vach_ping(TheKetNoi.PING_TOT_MS + 1), 2)
	assert_eq(TheKetNoi.so_vach_ping(TheKetNoi.PING_VUA_MS), 2)
	assert_eq(TheKetNoi.so_vach_ping(TheKetNoi.PING_VUA_MS + 1), 1)


func test_ping_colour_follows_bar_count() -> void:
	assert_eq(TheKetNoi.mau_ping(3), UIKit.LA)
	assert_eq(TheKetNoi.mau_ping(1), UIKit.DO)


func test_no_rooms_has_its_own_message() -> void:
	assert_eq(TheKetNoi.mo_ta_phong([]), "Chưa có phòng mở")


func test_room_summary_totals_players() -> void:
	var rooms := [{"players": 3}, {"players": 9}]
	assert_eq(TheKetNoi.mo_ta_phong(rooms), "2 phòng mở · 12 người")
