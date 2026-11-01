extends SceneTree

## Kiểm tra runtime: autoload phát đúng bộ nhạc, chuyển bài, gom bus, thanh trượt Cài đặt.
## Chạy: godot --headless --path . --script res://tests/run_am_thanh.gd

const GIAY_CHO_CHUYEN_NHAC := 0.9
const SAI_SO_DB := 0.1

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var runner: RefCounted = load("res://addons/godot_ai/testing/test_runner.gd").new()
	runner.run_suite(load("res://tests/test_am_thanh.gd").new())
	var results: Dictionary = runner.get_results()
	print(JSON.stringify(results))
	var am_thanh: AmThanh = root.get_node_or_null("AmThanhHook")
	check(am_thanh != null, "autoload AmThanhHook chưa được nạp")
	if am_thanh != null:
		_kiem_bus()
		_kiem_du_ma_minigame()
		await _kiem_nhac(am_thanh)
		await _kiem_sfx(am_thanh)
		_kiem_gom_bus()
		await _kiem_nut_bam(am_thanh)
		await _kiem_cai_dat()
		await _kiem_roi_cua_so(am_thanh)
	print("AM THANH RUNTIME: %d failures" % failures)
	quit(1 if failures > 0 or int(results.get("failed", 0)) > 0 else 0)


func _kiem_bus() -> void:
	for bus: StringName in [AmThanh.BUS_NHAC, AmThanh.BUS_SFX, AmThanh.BUS_LOA_SANH]:
		check(AudioServer.get_bus_index(bus) >= 0, "thiếu bus %s" % bus)


## Thêm minigame mới vào quản trò mà quên bộ nhạc thì báo ở đây.
func _kiem_du_ma_minigame() -> void:
	var quan_tro: Node = load("res://minigame/quan_tro_minigame.tscn").instantiate()
	for ma: String in quan_tro.danh_sach():
		var duong_dan := BangAmThanh.tim_file(BangAmThanh.ung_vien_nhac("%s/%s" % [ma, BangAmThanh.PHA_CHOI]))
		check(not duong_dan.is_empty(), "minigame %s chưa có nhạc" % ma)
	quan_tro.free()


func _loa_dang_phat(am_thanh: AmThanh) -> Array[AudioStreamPlayer]:
	var ra: Array[AudioStreamPlayer] = []
	for ten: String in ["NhacA", "NhacB"]:
		var loa: AudioStreamPlayer = am_thanh.get_node(ten)
		if loa.playing:
			ra.append(loa)
	return ra


func _kiem_nhac(am_thanh: AmThanh) -> void:
	var loa_sanh := AudioServer.get_bus_index(AmThanh.BUS_LOA_SANH)
	AmThanh.dat_nhac("ban_co/choi")
	await create_timer(GIAY_CHO_CHUYEN_NHAC).timeout
	var dang_phat := _loa_dang_phat(am_thanh)
	check(dang_phat.size() == 1, "bàn cờ phải có đúng một loa phát")
	if dang_phat.size() == 1:
		var loa := dang_phat[0]
		check(loa.stream.resource_path == "res://asset/audio/nhac/ban_co/choi.ogg", "sai bài bàn cờ: %s" % loa.stream.resource_path)
		check(loa.stream.get("loop") == true, "nhạc bàn cờ phải lặp")
		check(loa.bus == AmThanh.BUS_NHAC, "nhạc phải vào bus Nhac")
		check(is_equal_approx(loa.volume_linear, 1.0), "nhạc chưa lên hết âm lượng")
	check(AudioServer.is_bus_mute(loa_sanh), "có nhạc thì loa sảnh phải tắt tiếng")

	AmThanh.dat_nhac("paint/ket_qua")
	await create_timer(GIAY_CHO_CHUYEN_NHAC).timeout
	dang_phat = _loa_dang_phat(am_thanh)
	check(dang_phat.size() == 1, "chuyển xong phải còn một loa phát")
	if dang_phat.size() == 1:
		check(dang_phat[0].stream.resource_path == "res://asset/audio/nhac/paint/ket_qua.ogg", "sai bài kết quả")
		check(dang_phat[0].stream.get("loop") == false, "nhạc kết quả không được lặp")

	# Đổi bài liên tiếp không được để sót loa cũ.
	AmThanh.dat_nhac("crown/dem_nguoc")
	AmThanh.dat_nhac("crown/choi")
	await create_timer(GIAY_CHO_CHUYEN_NHAC).timeout
	dang_phat = _loa_dang_phat(am_thanh)
	check(dang_phat.size() == 1 and dang_phat[0].stream.resource_path.ends_with("crown/choi.ogg"), "đổi bài nhanh sót loa cũ")

	AmThanh.dat_nhac("")
	await create_timer(GIAY_CHO_CHUYEN_NHAC).timeout
	check(_loa_dang_phat(am_thanh).is_empty(), "khóa rỗng phải dừng nhạc")
	check(not AudioServer.is_bus_mute(loa_sanh), "hết nhạc thì trả tiếng cho loa sảnh")


func _kiem_sfx(am_thanh: AmThanh) -> void:
	for ten: StringName in BangAmThanh.TAT_CA_SFX:
		AmThanh.phat(ten)
		await process_frame
	var be: Array[Node] = am_thanh.get_node("Sfx").get_children()
	var so_loa_phat := 0
	for loa: AudioStreamPlayer in be:
		check(loa.bus == AmThanh.BUS_SFX, "loa SFX phải vào bus SFX")
		so_loa_phat += 1 if loa.playing else 0
	check(so_loa_phat > 0, "SFX không kêu")


func _kiem_gom_bus() -> void:
	var tieng_3d := AudioStreamPlayer3D.new()
	root.add_child(tieng_3d)
	check(tieng_3d.bus == AmThanh.BUS_SFX, "tiếng đặt sẵn trong scene phải được gom về SFX")
	tieng_3d.free()
	var loa_rieng := AudioStreamPlayer3D.new()
	loa_rieng.bus = AmThanh.BUS_LOA_SANH
	root.add_child(loa_rieng)
	check(loa_rieng.bus == AmThanh.BUS_LOA_SANH, "không được đè bus đã chọn sẵn")
	loa_rieng.free()


func _so_loa_keu_bam_nut(am_thanh: AmThanh) -> int:
	var dem := 0
	for loa: AudioStreamPlayer in am_thanh.get_node("Sfx").get_children():
		if loa.playing and loa.stream != null and loa.stream.resource_path.ends_with("bam_nut.ogg"):
			dem += 1
	return dem


func _kiem_nut_bam(am_thanh: AmThanh) -> void:
	var nut := Button.new()
	var tab := TabContainer.new()
	var danh_sach := ItemList.new()
	for dieu_khien: Control in [nut, tab, danh_sach]:
		root.add_child(dieu_khien)
	for ten_trang: String in ["A", "B"]:
		var trang := Control.new()
		trang.name = ten_trang
		tab.add_child(trang)
	danh_sach.add_item("A")
	await process_frame
	await _cho_het_tieng_bam(am_thanh)

	nut.pressed.emit()
	await process_frame
	check(_so_loa_keu_bam_nut(am_thanh) > 0, "nút bấm không có tiếng")
	await _cho_het_tieng_bam(am_thanh)

	tab.current_tab = 1
	await process_frame
	check(_so_loa_keu_bam_nut(am_thanh) > 0, "tab không có tiếng")
	await _cho_het_tieng_bam(am_thanh)

	danh_sach.item_clicked.emit(0, Vector2.ZERO, MOUSE_BUTTON_LEFT)
	await process_frame
	check(_so_loa_keu_bam_nut(am_thanh) > 0, "danh sách không có tiếng")
	await _cho_het_tieng_bam(am_thanh)

	# Nút gọi thêm `_play_click` như menu chính: cùng khung chỉ được kêu một lần.
	AmThanh.phat(BangAmThanh.SFX_BAM_NUT)
	nut.pressed.emit()
	await process_frame
	check(_so_loa_keu_bam_nut(am_thanh) == 1, "bấm một lần kêu hai tiếng")
	for dieu_khien: Control in [nut, tab, danh_sach]:
		dieu_khien.free()


func _cho_het_tieng_bam(am_thanh: AmThanh) -> void:
	for loa: AudioStreamPlayer in am_thanh.get_node("Sfx").get_children():
		loa.stop()
	await create_timer(AmThanh.GIAY_CHONG_LAP_SFX * 2.0).timeout


func _kiem_roi_cua_so(am_thanh: AmThanh) -> void:
	var master := AudioServer.get_bus_index(AmThanh.BUS_MASTER)
	var bang: Control = load("res://ui/bang_cai_dat.tscn").instantiate()
	root.add_child(bang)
	await process_frame
	# Không ghi đè cài đặt thật của người chạy test.
	bang._dang_nap = true
	var tuy_chon: CheckButton = bang.tat_tieng_check
	var ban_dau := tuy_chon.button_pressed
	var am_luong_cu: float = bang.volume_slider.value
	bang.volume_slider.value = 80.0

	tuy_chon.button_pressed = true
	am_thanh.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(AudioServer.is_bus_mute(master), "bật tùy chọn thì rời cửa sổ phải tắt tiếng")
	am_thanh.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not AudioServer.is_bus_mute(master), "quay lại phải bật tiếng")

	tuy_chon.button_pressed = false
	am_thanh.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not AudioServer.is_bus_mute(master), "tắt tùy chọn thì rời cửa sổ vẫn có tiếng")
	tuy_chon.button_pressed = true
	check(AudioServer.is_bus_mute(master), "bật tùy chọn lúc đang ở ngoài phải có hiệu lực ngay")
	am_thanh.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)

	bang.volume_slider.value = 0.0
	am_thanh.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	am_thanh.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(AudioServer.is_bus_mute(master), "thanh tổng về 0 thì quay lại vẫn im")

	bang.volume_slider.value = am_luong_cu
	tuy_chon.button_pressed = ban_dau
	bang.queue_free()
	await process_frame


func _kiem_cai_dat() -> void:
	var bang: Control = load("res://ui/bang_cai_dat.tscn").instantiate()
	root.add_child(bang)
	await process_frame
	var nhac_truoc: float = bang.nhac_slider.value
	var sfx_truoc: float = bang.sfx_slider.value
	bang.nhac_slider.value = 50.0
	bang.sfx_slider.value = 25.0
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(AmThanh.BUS_NHAC)) - linear_to_db(0.5)) < SAI_SO_DB, "thanh nhạc không chỉnh bus Nhac")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(AmThanh.BUS_SFX)) - linear_to_db(0.25)) < SAI_SO_DB, "thanh SFX không chỉnh bus SFX")
	check(bang.nhac_value.text == "50%" and bang.sfx_value.text == "25%", "nhãn âm lượng sai")
	bang.sfx_slider.value = 0.0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(AmThanh.BUS_SFX)), "kéo về 0 phải tắt tiếng")
	bang.nhac_slider.value = nhac_truoc
	bang.sfx_slider.value = sfx_truoc
	bang.queue_free()
	await process_frame
