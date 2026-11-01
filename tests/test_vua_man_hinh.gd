@tool
extends McpTestSuite


func suite_name() -> String:
	return "vua_man_hinh"


func test_window_that_fits_keeps_its_size() -> void:
	assert_eq(UINav.co_vua_man_hinh(Vector2i(1600, 900), Vector2i(1920, 1040)), Vector2i(1600, 900))


func test_window_taller_than_laptop_screen_shrinks_inside_it() -> void:
	var moi := UINav.co_vua_man_hinh(Vector2i(1600, 900), Vector2i(1366, 728))
	assert_true(moi.x <= 1366 and moi.y <= 728 - UINav.CAO_THANH_TIEU_DE)


func test_shrinking_keeps_aspect_ratio() -> void:
	var moi := UINav.co_vua_man_hinh(Vector2i(1600, 900), Vector2i(1280, 680))
	assert_true(absf(float(moi.x) / moi.y - 16.0 / 9.0) < 0.01)


func test_title_bar_counts_against_available_height() -> void:
	var moi := UINav.co_vua_man_hinh(Vector2i(1920, 1080), Vector2i(1920, 1080))
	assert_eq(moi.y, 1080 - UINav.CAO_THANH_TIEU_DE)
