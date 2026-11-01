extends SceneTree

## Bảng phím phải gọn, đúng góc màn hình và mỗi minigame phải nói được phím của mình.

const KICH_THUOC_MAN := Vector2i(1280, 720)
const CAO_TOI_DA := 260.0
const RONG_TOI_DA := 240.0
const SO_KHUNG_BO_CUC := 3
const THU_MUC_MINIGAME := "res://minigame/"

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	root.size = KICH_THUOC_MAN
	var hud: Control = load("res://ui/hud.tscn").instantiate()
	root.add_child(hud)
	var bang: DaiPhim = hud.get_node("DaiPhim")
	for ds: Array in [DaiPhim.PHIM_SANH, DaiPhim.PHIM_BAN, DaiPhim.PHIM_CAM_DO, DaiPhim.PHIM_CHON_HUONG]:
		await _kiem_tra_gon(bang, ds)
	bang.hien([])
	check(not bang.visible, "Empty list hides the panel")
	_kiem_tra_moi_tro()
	print("DAI PHIM: %d failures" % failures)
	quit(failures)


func _kiem_tra_gon(bang: DaiPhim, ds: Array) -> void:
	bang.hien(ds)
	for _khung in SO_KHUNG_BO_CUC:
		await process_frame
	var khung := bang.get_global_rect()
	check(khung.size.x <= RONG_TOI_DA and khung.size.y <= CAO_TOI_DA, "Panel stays compact: %s" % khung.size)
	check(khung.end.x <= KICH_THUOC_MAN.x and khung.end.y <= KICH_THUOC_MAN.y, "Panel stays on screen: %s" % khung)


## Mọi trò đăng ký trong quản trò đều phải kê được phím.
func _kiem_tra_moi_tro() -> void:
	var quan_tro: Node = load(THU_MUC_MINIGAME + "quan_tro_minigame.tscn").instantiate()
	check(not quan_tro.tro_choi.is_empty(), "Registry has minigames")
	for canh: PackedScene in quan_tro.tro_choi:
		var tro: Node = canh.instantiate()
		check(not tro.phim_cua_tro().is_empty(), "%s lists its controls" % canh.resource_path)
		tro.free()
	quan_tro.free()
