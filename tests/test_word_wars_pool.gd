@tool
extends McpTestSuite

const Pool = preload("res://minigame/pool_minigame.gd")
const Word = preload("res://minigame/word_wars/word_wars.gd")

func suite_name() -> String:
	return "word_wars_pool"

func test_pool_exhausts_without_repeats_and_refills() -> void:
	var codes := PackedStringArray(["crown", "word_wars", "explosive", "laser_leap"])
	for seed_value in range(100):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var state: Dictionary = {}
		var last := ""
		for cycle in range(5):
			var seen: Array[String] = []
			for i in range(codes.size()):
				var code: String = Pool.chon(state, codes, rng)
				assert_false(seen.has(code))
				if i == 0 and cycle > 0:
					assert_ne(code, last)
				seen.append(code)
				state = Pool.da_choi(state, codes, code)
				assert_eq(state["remaining"].size(), codes.size() - i - 1)
				last = code
			assert_eq(seen.size(), codes.size())

func test_preferred_game_cannot_repeat_inside_pool() -> void:
	var codes := PackedStringArray(["crown", "word_wars", "explosive"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var state := Pool.da_choi({}, codes, "crown")
	assert_ne(Pool.chon(state, codes, rng, "crown"), "crown")
	assert_eq(Pool.chon(state, codes, rng, "word_wars"), "word_wars")

func test_empty_single_and_restored_pool() -> void:
	var rng := RandomNumberGenerator.new()
	assert_eq(Pool.chon({}, PackedStringArray(), rng), "")
	var codes := PackedStringArray(["crown"])
	var state := Pool.da_choi({}, codes, "crown")
	assert_eq(Pool.chon(state, codes, rng), "crown")
	var restored: Dictionary = JSON.parse_string(JSON.stringify({"remaining": ["word_wars"], "last": "crown"}))
	assert_eq(Pool.chon(restored, PackedStringArray(["crown", "word_wars"]), rng), "word_wars")

func test_words_remain_deterministic_without_adjacent_repeats() -> void:
	var previous := ""
	for i in range(100):
		var word: String = Word.tu_cua(4242, i)
		assert_ne(word, previous)
		assert_eq(word, Word.tu_cua(4242, i))
		previous = word
	assert_true(Word.TU.has(Word.tu_cua(4242, 1000)))

func test_stale_letter_packet_cannot_advance_next_word() -> void:
	var game: Node = track(Word.new())
	game._chay = true
	game._diem = {1: 1}
	game._tien = {1: 0}
	game._net_tien(1, 0, 1)
	assert_eq(game._tien[1], 0)
	game._net_tien(1, 1, 1)
	assert_eq(game._tien[1], 1)
	game._net_tien(1, 1, 1)
	assert_eq(game._tien[1], 1)

func test_square_arena_letters_and_clear_corridors() -> void:
	var arena: Node3D = track(load("res://minigame/word_wars/san_chu.tscn").instantiate())
	var floor_mesh: BoxMesh = arena.get_node("SanVuong/Mat").mesh
	assert_eq(floor_mesh.size.x, 28.0)
	assert_eq(floor_mesh.size.z, 28.0)
	var letters: Array = arena.get_node("Bang").get_children()
	assert_eq(letters.size(), 26)
	var seen: Array[String] = []
	for letter: Node3D in letters:
		assert_false(seen.has(letter.chu))
		seen.append(letter.chu)
		assert_true(letter.has_node("Than/Hinh"))
		for other: Node3D in letters:
			if other != letter:
				assert_true(letter.position.distance_to(other.position) >= 4.0)

func test_reusable_props_keep_gameplay_wrappers() -> void:
	var crown: Node = track(load("res://minigame/crown/vuong_mien.tscn").instantiate())
	assert_true(crown.has_node("Mat/Band"))
	assert_true(crown.has_node("Vung/Hinh"))
	var bomb: Node = track(load("res://minigame/explosive/bom_chuyen.tscn").instantiate())
	assert_true(bomb.has_node("Mat/Fuse"))
	assert_true(bomb.has_node("Mat/EyeL"))
	assert_true(bomb.has_node("Blast"))

func test_word_wars_runs_full_timer_with_one_player() -> void:
	var game: Node = track(load("res://minigame/word_wars/word_wars.tscn").instantiate())
	assert_false(game.ket_thuc_khi_con_mot)

func test_pool_property_is_replicated() -> void:
	var config: Resource = load("res://net/match_state_replication.tres")
	assert_eq(config.get("properties/10/path"), NodePath(":minigame_pool_json"))

func test_coordinator_and_main_compile() -> void:
	assert_true(load("res://minigame/quan_tro_minigame.gd").can_instantiate())
	assert_true(load("res://main.gd").can_instantiate())
