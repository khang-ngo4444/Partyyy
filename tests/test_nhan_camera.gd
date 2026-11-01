@tool
extends McpTestSuite


func suite_name() -> String:
	return "nhan_camera"


func test_free_camera_tells_whose_turn_it_is() -> void:
	var thong_tin := NhanCamera.tu_do("An")
	assert_eq(thong_tin["tieu_de"], "CAM TỰ DO")
	assert_eq(thong_tin["chi_tiet"], "Lượt của An")


func test_free_camera_before_first_turn() -> void:
	assert_eq(NhanCamera.tu_do("")["chi_tiet"], "Chưa tới lượt ai")


func test_following_turn_names_who_is_watched() -> void:
	assert_eq(NhanCamera.theo_luot("An")["chi_tiet"], "Đang xem An")


func test_following_a_player_shows_watched_and_turn() -> void:
	var thong_tin := NhanCamera.theo_nguoi("An", "Bình")
	assert_eq(thong_tin["tieu_de"], "THEO · An")
	assert_eq(thong_tin["chi_tiet"], "Lượt của Bình")


func test_each_mode_has_its_own_colour() -> void:
	var mau := [NhanCamera.MAU_TU_DO, NhanCamera.MAU_THEO_LUOT,
			NhanCamera.MAU_THEO_NGUOI, NhanCamera.MAU_NGAM_DO]
	for i in mau.size():
		assert_eq(mau.find(mau[i]), i)
