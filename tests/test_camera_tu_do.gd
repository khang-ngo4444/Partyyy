@tool
extends McpTestSuite

const SAI_SO := 0.0001
const GOC_BAT_KY := 1.2


func suite_name() -> String:
	return "camera_tu_do"


func test_up_and_down_follow_world_axis_at_any_yaw() -> void:
	assert_true(CameraTuDo.huong_bay(GOC_BAT_KY, 0.0, 0.0, 1.0).is_equal_approx(Vector3.UP))
	assert_true(CameraTuDo.huong_bay(GOC_BAT_KY, 0.0, 0.0, -1.0).is_equal_approx(Vector3.DOWN))


func test_forward_stays_level() -> void:
	assert_true(absf(CameraTuDo.huong_bay(GOC_BAT_KY, 1.0, 0.0, 0.0).y) < SAI_SO)


func test_combined_input_does_not_fly_faster() -> void:
	assert_true(absf(CameraTuDo.huong_bay(GOC_BAT_KY, 1.0, 1.0, 1.0).length() - 1.0) < SAI_SO)


func test_opposite_keys_cancel_to_no_vertical_motion() -> void:
	var huong := CameraTuDo.huong_bay(0.0, 1.0, 0.0, 1.0 - 1.0)
	assert_true(absf(huong.y) < SAI_SO)


func test_fly_keys_do_not_use_dice_roll_keys() -> void:
	for phim: Key in [CameraTuDo.PHIM_BAY_LEN, CameraTuDo.PHIM_BAY_XUONG]:
		assert_false(phim == KEY_SPACE or phim == KEY_E)
