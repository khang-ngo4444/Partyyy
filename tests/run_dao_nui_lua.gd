extends SceneTree

## Kiểm tra đảo mới không đổi đồ thị bàn và đủ thành phần trang trí.

const SO_O := 56
const SO_VAT_CHUYEN_DONG_TOI_THIEU := 13
const O_RE_NHANH := 4
const O_DAU_DUONG_TAT := 40

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
	var board: BanDuong = load("res://board/ban_party.tscn").instantiate()
	fixture.add_child(board)
	check(board.so_luong() == SO_O, "Board keeps every tile")
	check(board.ke(O_RE_NHANH).has(O_DAU_DUONG_TAT), "Shortcut edge stays connected")
	var map_model := board.get_node("MapModel")
	check(map_model.get_node_or_null("RumbleReefEnvironment") != null, "Island brings its environment")
	check(map_model.find_children("*", "VatChuyenDong", true, false).size() >= SO_VAT_CHUYEN_DONG_TOI_THIEU,
			"Decorative movers are authored")
	var dia_hinh := map_model.get_node("DiaHinh")
	check(dia_hinh.get_child_count() > 0, "Terrain meshes are imported")
	for mesh_node: MeshInstance3D in dia_hinh.get_children():
		check(mesh_node.mesh != null and mesh_node.mesh.resource_path.begins_with("res://asset/generated/dao_lon/mesh/"),
				"Terrain chunk uses its extracted mesh")
	print("DAO NUI LUA: %d failures" % failures)
	quit(failures)
