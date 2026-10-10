class_name LuatBan
extends RefCounted

## Luật thuần của bàn party (không đụng scene/mạng).

enum Thue { DAT, MAU, TIEN, TRANG_BI }
const TEN_THUE := ["đất", "máu", "tiền", "trang bị"]
## Sát thương của món "gục ngay".
const GUC := 1000
## Bảng trạng thái giữ nguyên khi sang vòng mới.
const BANG_GIU_QUA_VONG := ["bay", "rao", "neo", "doc", "heo", "quai", "chieu"]


static func khoa(id) -> String:
	return str(int(id))


## Trạng thái vòng mới, giữ tài nguyên của người còn trong phòng. `cu` rỗng = ván mới.
static func trang_thai_moi(ds: Array, cu: Dictionary, settings: Dictionary) -> Dictionary:
	var max_health := int(settings.get("max_health", 10))
	var start_gold := int(settings.get("start_gold", 0))
	var moi := {
		"luot": 0,
		"thu_tu": ds.duplicate(),
		"o": {},
		"mau": {},
		"tien": {},
		"do": {},
		"buoc": {},
		"hoi_sinh": {},
		"chu_dat": (_bang(cu, "chu_dat").duplicate() if not cu.is_empty() else {}),
		"thue_dat": (_bang(cu, "thue_dat").duplicate() if not cu.is_empty() else {}),
		"loai_o": (cu.get("loai_o", []) as Array).duplicate(),
		"coc": {},
		"ruong_o": int(cu.get("ruong_o", -1)),
		"vong": int(cu.get("vong", 1)),
		"so_vong": int(cu.get("so_vong", 1)),
	}
	for ten in BANG_GIU_QUA_VONG:
		moi[ten] = _bang(cu, ten).duplicate(true)
	for id in ds:
		var k := khoa(id)
		moi["o"][k] = int(_bang(cu, "o").get(k, 0))
		moi["mau"][k] = int(_bang(cu, "mau").get(k, max_health))
		moi["tien"][k] = int(_bang(cu, "tien").get(k, start_gold))
		moi["do"][k] = (_bang(cu, "do").get(k, []) as Array).duplicate()
		moi["buoc"][k] = int(_bang(cu, "buoc").get(k, 0))
		moi["hoi_sinh"][k] = int(_bang(cu, "hoi_sinh").get(k, 0))
		moi["coc"][k] = int(_bang(cu, "coc").get(k, 0))
	return moi


## Túi đầy thì bỏ món cũ nhất. Trả về lời báo mất món ("" = không mất gì).
static func them_do(tt: Dictionary, k: String, mon: String) -> String:
	if mon.is_empty():
		return ""
	var tui: Array = _bang(tt, "do").get(k, [])
	tui.append(mon)
	var roi := PackedStringArray()
	while tui.size() > VatPham.TUI_TOI_DA:
		roi.append(VatPham.ten(str(tui.pop_front())))
	_bang(tt, "do")[k] = tui
	return "" if roi.is_empty() else " (túi đầy, mất %s)" % ", ".join(roi)


static func rut_do(tt: Dictionary, k: String, chi_so: int) -> String:
	var tui: Array = _bang(tt, "do").get(k, [])
	if chi_so < 0 or chi_so >= tui.size():
		return ""
	var mon := str(tui[chi_so])
	tui.remove_at(chi_so)
	_bang(tt, "do")[k] = tui
	return mon


## Hiệu ứng ô Máu và ô Tiền.
static func hieu_ung_o(tt: Dictionary, k: String, loai: int, settings: Dictionary) -> String:
	match loai:
		BanDuong.Loai.MAU:
			var bang: Dictionary = _bang(tt, "mau")
			var truoc := int(bang.get(k, 0))
			var sau := mini(truoc + int(settings.get("health_gain", 3)),
					int(settings.get("max_health", 10)))
			bang[k] = sau
			return "+%d máu" % (sau - truoc) if sau > truoc else "máu đã đầy"
		BanDuong.Loai.TIEN:
			var tien: Dictionary = _bang(tt, "tien")
			var them := int(settings.get("money_gain", 15))
			tien[k] = int(tien.get(k, 0)) + them
			return "+%d vàng" % them
	return ""


## MỌI sát thương đi qua đây (Úp thúng, Dây thun). true = hết máu, người gọi phải `chet()`.
static func tru_mau(tt: Dictionary, k: String, sat_thuong: int) -> bool:
	if sat_thuong <= 0:
		return false
	if co_khien(tt, k):
		tieu_khien(tt, k)
		return false
	sat_thuong = LuatHieuUng.khi_trung_don(tt, k, sat_thuong)
	var mau: Dictionary = _bang(tt, "mau")
	var con := int(mau.get(k, 0)) - sat_thuong
	mau[k] = maxi(con, 0)
	return con <= 0


static func co_khien(tt: Dictionary, k: String) -> bool:
	return (_bang(tt, "do").get(k, []) as Array).has("khien")


static func tieu_khien(tt: Dictionary, k: String) -> void:
	var tui: Array = _bang(tt, "do").get(k, [])
	tui.erase("khien")
	_bang(tt, "do")[k] = tui


## Hồi đầy máu, về checkpoint (hoặc ô neo). Không mất vàng, không mất Cúp.
static func chet(tt: Dictionary, k: String, settings: Dictionary) -> void:
	_bang(tt, "mau")[k] = int(settings.get("max_health", 10))
	_bang(tt, "o")[k] = LuatHieuUng.khi_guc(tt, k, int(_bang(tt, "hoi_sinh").get(k, 0)))


## Áp một loại thuế; không có đất/đồ để lấy thì thu tiền.
static func thu_thue(tt: Dictionary, chu: String, khach: String, loai: int,
		settings: Dictionary) -> String:
	match loai:
		Thue.DAT:
			var dat: Dictionary = _bang(tt, "chu_dat")
			var cac_o := dat.keys()
			cac_o.sort_custom(func(a, b): return int(a) < int(b))
			for o in cac_o:
				if khoa(dat[o]) == khach:
					dat[o] = int(chu)
					return "thuế đất: chuyển ô %d" % int(o)
			return thu_thue(tt, chu, khach, Thue.TIEN, settings)
		Thue.MAU:
			var muc := int(settings.get("tax_health", 2))
			var bang_mau: Dictionary = _bang(tt, "mau")
			var truoc := int(bang_mau.get(khach, 0))
			var chet_roi := tru_mau(tt, khach, muc)
			var da_mat := 0 if int(bang_mau.get(khach, 0)) == truoc else mini(muc, truoc)
			bang_mau[chu] = mini(int(bang_mau.get(chu, 0)) + da_mat,
					int(settings.get("max_health", 10)))
			return "thuế máu: -%d máu%s" % [da_mat, " (gục)" if chet_roi else ""]
		Thue.TRANG_BI:
			var tui_khach: Array = _bang(tt, "do").get(khach, [])
			if not tui_khach.is_empty():
				var mon := str(tui_khach.pop_front())
				_bang(tt, "do")[khach] = tui_khach
				them_do(tt, chu, mon)
				return "thuế trang bị: %s" % VatPham.ten(mon)
			return thu_thue(tt, chu, khach, Thue.TIEN, settings)
		_:
			var bang_tien: Dictionary = _bang(tt, "tien")
			var lay := mini(int(settings.get("tax_money", 10)), int(bang_tien.get(khach, 0)))
			bang_tien[khach] = int(bang_tien.get(khach, 0)) - lay
			bang_tien[chu] = int(bang_tien.get(chu, 0)) + lay
			return "thuế tiền: %d vàng" % lay


static func _bang(tt: Dictionary, ten: String) -> Dictionary:
	return tt.get(ten, {}) as Dictionary
