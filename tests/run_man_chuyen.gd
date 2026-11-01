extends SceneTree

## Kiểm tra runtime của màn chuyển: thứ tự che/lộ và các yêu cầu chồng nhau.
## Chạy: godot --headless --path . --script res://tests/run_man_chuyen.gd

const GIAY_DU_DIEN := ManChuyen.GIAY_CHE + ManChuyen.GIAY_GIU + ManChuyen.GIAY_LO + 0.25

var failures := 0
var man: ManChuyen = null


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	man = root.get_node_or_null("ManChuyenHook")
	check(man != null, "autoload ManChuyenHook chưa được nạp")
	if man != null:
		_kiem_bat_dau_an()
		await _kiem_che_roi_lo()
		await _kiem_mo_som_khi_dang_che()
		await _kiem_che_lai_huy_lich_lo()
		await _kiem_che_lai_khi_dang_lo()
		await _kiem_che_ngay()
		await _kiem_che_ngay_dang_cho()
		await _kiem_doi_chu()
		await _kiem_cac_kieu()
		await _kiem_doi_kieu_khi_da_che()
	print("MAN CHUYEN RUNTIME: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _cho(giay: float) -> void:
	await create_timer(giay).timeout


func _tieu_de() -> String:
	return (man.get_node("%TieuDe") as Label).text


func _kiem_bat_dau_an() -> void:
	check(not man.visible and not ManChuyen.dang_phu(), "màn phải ẩn lúc khởi động")
	check(man.layer > 10, "màn phải nằm trên lớp minigame")


func _kiem_che_roi_lo() -> void:
	await ManChuyen.che("A", "phụ")
	check(man._pha == ManChuyen.Pha.DA_CHE and man.visible, "`await che` phải về khi đã che kín")
	check(man._tien_do() == 1.0, "che kín thì tiến độ phải là 1")
	check(man.get_node("NoiDung").visible, "che kín phải hiện chữ")
	ManChuyen.mo()
	await _cho(ManChuyen.GIAY_GIU * 0.5)
	check(man._pha == ManChuyen.Pha.DA_CHE, "chưa đủ thời gian giữ thì chưa được lộ")
	await _cho(ManChuyen.GIAY_GIU * 0.5 + ManChuyen.GIAY_LO + 0.25)
	check(man._pha == ManChuyen.Pha.MO and not man.visible, "lộ xong phải ẩn màn")
	check(man._tien_do() == 0.0, "lộ xong phải trả tiến độ về 0")


func _kiem_mo_som_khi_dang_che() -> void:
	ManChuyen.che("B")
	ManChuyen.mo()
	check(man._pha == ManChuyen.Pha.DANG_CHE, "`mo` không được cắt ngang lúc đang che")
	await _cho(GIAY_DU_DIEN)
	check(man._pha == ManChuyen.Pha.MO, "`mo` gọi sớm phải có hiệu lực sau khi che xong")


func _kiem_che_lai_huy_lich_lo() -> void:
	await ManChuyen.che("C")
	ManChuyen.mo()
	ManChuyen.che("D")
	await _cho(GIAY_DU_DIEN)
	check(man._pha == ManChuyen.Pha.DA_CHE, "che mới phải huỷ lịch lộ cũ (lobby rồi vào bàn)")
	ManChuyen.mo()
	await _cho(GIAY_DU_DIEN)


func _kiem_che_lai_khi_dang_lo() -> void:
	await ManChuyen.che("E")
	ManChuyen.mo()
	await _cho(ManChuyen.GIAY_GIU + ManChuyen.GIAY_LO * 0.5)
	check(man._pha == ManChuyen.Pha.DANG_LO, "thiếu điều kiện test: phải đang lộ")
	await ManChuyen.che("F")
	check(man._pha == ManChuyen.Pha.DA_CHE and man._tien_do() == 1.0, "che khi đang lộ phải che kín lại")
	ManChuyen.mo()
	await _cho(GIAY_DU_DIEN)


func _kiem_che_ngay() -> void:
	ManChuyen.che_ngay("G")
	check(man._pha == ManChuyen.Pha.DA_CHE and man.visible and man._tien_do() == 1.0, "che_ngay phải kín trong cùng khung")
	ManChuyen.mo()
	await _cho(GIAY_DU_DIEN)
	check(man._pha == ManChuyen.Pha.MO, "che_ngay rồi mo phải lộ lại")


## Máy khách: đang che vì hết vòng thì minigame tới; ai chờ `che` vẫn phải được giải phóng.
func _kiem_che_ngay_dang_cho() -> void:
	var xong := [false]
	var cho := func() -> void:
		await ManChuyen.che("H")
		xong[0] = true
	cho.call()
	await process_frame
	ManChuyen.che_ngay("I")
	await process_frame
	check(xong[0], "che_ngay phải giải phóng người đang `await che`")
	ManChuyen.mo()
	await _cho(GIAY_DU_DIEN)
	check(man._pha == ManChuyen.Pha.MO, "phải lộ lại sau che_ngay chen ngang")


func _so_nen_dang_hien() -> int:
	var dem := 0
	for nen: ColorRect in man._cac_nen.values():
		dem += 1 if nen.visible else 0
	return dem


func _kiem_cac_kieu() -> void:
	check(man._cac_nen.size() == ManChuyen.Kieu.size(), "kiểu nào cũng phải có nền")
	for kieu: ManChuyen.Kieu in ManChuyen.Kieu.values():
		check(ManChuyen.BIEN_THE_THE.has(kieu), "kiểu %d thiếu màu thẻ" % kieu)
		await ManChuyen.che("kiểu", "", kieu)
		check(man._nen == man._cac_nen[kieu] and _so_nen_dang_hien() == 1, "kiểu %d phải hiện đúng một nền" % kieu)
		check(man._tien_do() == 1.0, "kiểu %d phải che kín" % kieu)
		check(man._nen.material is ShaderMaterial and (man._nen.material as ShaderMaterial).shader != null, "kiểu %d thiếu shader" % kieu)
		ManChuyen.mo()
		await _cho(GIAY_DU_DIEN)
		check(man._pha == ManChuyen.Pha.MO and man._tien_do() == 0.0, "kiểu %d phải lộ xong" % kieu)


## Chờ mạng bằng sóng rồi vào sảnh bằng rèm: lúc đổi vẫn phải che kín.
func _kiem_doi_kieu_khi_da_che() -> void:
	await ManChuyen.che("mạng", "", ManChuyen.Kieu.SONG)
	await ManChuyen.che("sảnh", "", ManChuyen.Kieu.REM)
	check(man._nen == man._cac_nen[ManChuyen.Kieu.REM], "phải đổi sang kiểu mới")
	check(man._tien_do() == 1.0 and man._pha == ManChuyen.Pha.DA_CHE, "đổi kiểu không được hở cảnh")
	ManChuyen.mo()
	await _cho(GIAY_DU_DIEN)


func _kiem_doi_chu() -> void:
	await ManChuyen.che("J", "có phụ đề")
	check(_tieu_de() == "J" and man.get_node("%Phu").visible, "chữ che sai")
	await ManChuyen.che("K")
	check(_tieu_de() == "K" and not man.get_node("%Phu").visible, "che lại phải đổi chữ, phụ đề rỗng thì ẩn")
	ManChuyen.mo()
	await _cho(GIAY_DU_DIEN)
