extends SceneTree

## Kiểm tra dự báo đường đi ở ngã rẽ trên bàn thật: đủ ô, đúng ô dừng, theo rào/bẫy và các nhánh.
## Chạy: godot --headless --path . --script res://tests/run_du_bao_duong.gd

const NGUOI := "1"
const NGUOI_KHAC := "2"
const O_NGA_RE := 14
const O_NHANH_THUONG := 15
const O_NHANH_TAT := 44
const O_TRUOC_NGA_RE := 13

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _tt(rao := {}, bay := {}) -> Dictionary:
	return {"chieu": {NGUOI: 1}, "o": {NGUOI: O_NGA_RE}, "rao": rao, "bay": bay}


func _kiem_du_bao(ban: BanDuong, tt: Dictionary, o: int, toi: int, con: int, mong_doi: Dictionary, ten: String) -> void:
	var ra := LuatBay.du_bao_duong(tt, NGUOI, ban, o, toi, con)
	check(ra == mong_doi, "%s: mong %s, nhận %s" % [ten, mong_doi, ra])


## Gói đi tới ngã rẽ phải làm sáng cả đoạn trên máy người chọn, đổi hướng thì đoạn đổi theo.
func _kiem_luong_nga_re(ban: BanDuong) -> void:
	var pha: Node = load("res://board/pha_ban_co.gd").new()
	current_scene.add_child(pha)
	pha.ban = ban
	var toi: int = root.get_node("NetManager").local_id()
	var khoa_toi := LuatBan.khoa(toi)
	pha.tt = {"luot": 0, "thu_tu": [toi], "o": {khoa_toi: O_NGA_RE}, "chieu": {khoa_toi: 1}}
	pha._id_dang_tung = toi
	pha._dice_ready = true
	var goi := {"doan": [O_NGA_RE], "huong": [O_NHANH_THUONG, O_NHANH_TAT], "con": 3}
	await pha._net_di_doan(toi, JSON.stringify(goi))
	check(pha._dang_chon, "dừng ở ngã rẽ phải chờ chọn")
	check(ban.nut_o(17).scale.x > ban.nut_o(16).scale.x, "ô dừng phải nổi hơn ô đi qua")
	check(ban.nut_o(16).scale.x > 1.0, "ô đi qua phải sáng")
	check(is_equal_approx(ban.nut_o(45).scale.x, 1.0), "nhánh chưa chọn không sáng cả đoạn")

	pha._lua_chon = 1
	pha._cap_nhat_lua_chon()
	check(ban.nut_o(46).scale.x > ban.nut_o(45).scale.x, "đổi hướng phải đổi ô dừng")
	check(is_equal_approx(ban.nut_o(16).scale.x, 1.0), "đổi hướng phải tắt đoạn cũ")

	pha._id_dang_tung = toi + 1
	pha._cap_nhat_lua_chon()
	check(is_equal_approx(ban.nut_o(45).scale.x, 1.0), "máy khác chỉ thấy mũi tên")
	pha.free()


func _run() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	current_scene = fixture
	var ban: BanDuong = load("res://board/ban_party.tscn").instantiate()
	fixture.add_child(ban)

	_kiem_du_bao(ban, _tt(), O_NGA_RE, O_NHANH_THUONG, 3, {15: false, 16: false, 17: true}, "nhánh thường")
	_kiem_du_bao(ban, _tt(), O_NGA_RE, O_NHANH_TAT, 3, {44: false, 45: false, 46: true}, "nhánh tắt")
	_kiem_du_bao(ban, _tt(), O_NGA_RE, O_NHANH_THUONG, 1, {15: true}, "một bước")
	_kiem_du_bao(ban, _tt(), O_TRUOC_NGA_RE, O_NGA_RE, 2, {14: false, 15: true, 44: true}, "gặp ngã rẽ nữa")
	_kiem_du_bao(ban, _tt({"17": NGUOI_KHAC}), O_NGA_RE, O_NHANH_THUONG, 5, {15: false, 16: true}, "vướng rào giữa đường")
	_kiem_du_bao(ban, _tt({"15": NGUOI_KHAC}), O_NGA_RE, O_NHANH_THUONG, 5, {14: true}, "rào ngay ô đầu")
	_kiem_du_bao(ban, _tt({"17": NGUOI}), O_NGA_RE, O_NHANH_THUONG, 3, {15: false, 16: false, 17: true}, "rào của mình")
	_kiem_du_bao(ban, _tt({}, {"15": NGUOI_KHAC}), O_NGA_RE, O_NHANH_THUONG, 5, {15: false, 16: false, 17: true}, "bẫy chia đôi bước")
	_kiem_du_bao(ban, _tt({}, {"15": NGUOI}), O_NGA_RE, O_NHANH_THUONG, 3, {15: false, 16: false, 17: true}, "bẫy của mình")

	var dau_van := _tt()
	dau_van["chieu"] = {}
	_kiem_du_bao(ban, dau_van, O_NGA_RE, O_NHANH_THUONG, 2, {15: false, 16: true}, "đầu ván chưa có chiều")
	check((dau_van["chieu"] as Dictionary).is_empty(), "dự báo không được đổi trạng thái")

	var rao_giu := _tt({"15": NGUOI_KHAC})
	LuatBay.du_bao_duong(rao_giu, NGUOI, ban, O_NGA_RE, O_NHANH_THUONG, 3)
	check((rao_giu["rao"] as Dictionary).has("15"), "dự báo không được gỡ rào")

	await _kiem_luong_nga_re(ban)

	print("DU BAO DUONG: %d failures" % failures)
	quit(failures)
