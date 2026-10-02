class_name LuatBan
extends RefCounted

## Luật thuần của bàn party. File này không đụng scene hay mạng; master áp luật rồi
## PhaBanCo phát nguyên Dictionary trạng thái cho cả phòng.

const TEN_DO := {
	"khien": "Khiên",
	"sung_1_phat": "Súng một phát",
}

enum Thue { DAT, MAU, TIEN, TRANG_BI }
const TEN_THUE := ["đất", "máu", "tiền", "trang bị"]


static func khoa(id) -> String:
	return str(int(id))


## Tạo trạng thái vòng mới và giữ tài nguyên của người còn trong phòng.
## Khi `cu` rỗng, tất cả cùng đứng ô 0.
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
		"ruong": (cu.get("ruong", []) as Array).duplicate(),
		"ruong_that": int(cu.get("ruong_that", -1)),
	}
	for id in ds:
		var k := khoa(id)
		moi["o"][k] = int(_bang(cu, "o").get(k, 0))
		moi["mau"][k] = int(_bang(cu, "mau").get(k, max_health))
		moi["tien"][k] = int(_bang(cu, "tien").get(k, start_gold))
		moi["do"][k] = (_bang(cu, "do").get(k, []) as Array).duplicate()
		moi["buoc"][k] = int(_bang(cu, "buoc").get(k, 0))
		moi["hoi_sinh"][k] = int(_bang(cu, "hoi_sinh").get(k, 0))
	return moi


static func them_do(tt: Dictionary, k: String, mon: String) -> void:
	var tui: Array = _bang(tt, "do").get(k, [])
	tui.append(mon)
	_bang(tt, "do")[k] = tui


static func rut_do(tt: Dictionary, k: String, chi_so: int) -> String:
	var tui: Array = _bang(tt, "do").get(k, [])
	if chi_so < 0 or chi_so >= tui.size():
		return ""
	var mon := str(tui[chi_so])
	tui.remove_at(chi_so)
	_bang(tt, "do")[k] = tui
	return mon


## Ô hồi máu và ô tiền là luật thuần. Ô đất/rương/trang bị cần thông tin scene hoặc RNG
## nên PhaBanCo xử lý ở lớp điều phối.
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


## Khiên chặn trọn một lần mất máu. Trả về true nếu người chơi hết máu.
static func tru_mau(tt: Dictionary, k: String, sat_thuong: int) -> bool:
	if sat_thuong <= 0:
		return false
	var tui: Array = _bang(tt, "do").get(k, [])
	if tui.has("khien"):
		tui.erase("khien")
		_bang(tt, "do")[k] = tui
		return false
	var mau: Dictionary = _bang(tt, "mau")
	var con := int(mau.get(k, 0)) - sat_thuong
	mau[k] = maxi(con, 0)
	return con <= 0


## Chết chỉ hồi máu và về checkpoint. Không xóa vàng/trang bị nếu phòng chưa bật luật đó.
static func chet(tt: Dictionary, k: String, settings: Dictionary) -> void:
	_bang(tt, "mau")[k] = int(settings.get("max_health", 10))
	_bang(tt, "o")[k] = int(_bang(tt, "hoi_sinh").get(k, 0))


## Thưởng sau minigame: hạng 1 nhận súng một phát; các hạng sau nhận vàng giảm dần.
static func thuong_minigame(tt: Dictionary, xep_hang: Array, settings: Dictionary) -> String:
	if xep_hang.is_empty():
		return ""
	them_do(tt, khoa(xep_hang[0]), "sung_1_phat")
	var thuong := PackedStringArray(["Hạng 1 nhận Súng một phát"])
	var moc := int(settings.get("minigame_second_gold", 30))
	var giam := int(settings.get("minigame_reward_drop", 10))
	var toi_thieu := int(settings.get("minigame_min_gold", 5))
	for i in range(1, xep_hang.size()):
		var vang := maxi(toi_thieu, moc - (i - 1) * giam)
		var k := khoa(xep_hang[i])
		_bang(tt, "tien")[k] = int(_bang(tt, "tien").get(k, 0)) + vang
		thuong.append("Hạng %d +%d vàng" % [i + 1, vang])
	return " · ".join(thuong)


## Áp một lựa chọn thuế. Đất = chuyển một ô của khách cho chủ; nếu khách không có đất thì
## tự rơi về thu tiền. Trang bị chuyển món đầu tiên trong túi.
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
				return "thuế trang bị: %s" % TEN_DO.get(mon, mon)
			return thu_thue(tt, chu, khach, Thue.TIEN, settings)
		_:
			var bang_tien: Dictionary = _bang(tt, "tien")
			var lay := mini(int(settings.get("tax_money", 10)), int(bang_tien.get(khach, 0)))
			bang_tien[khach] = int(bang_tien.get(khach, 0)) - lay
			bang_tien[chu] = int(bang_tien.get(chu, 0)) + lay
			return "thuế tiền: %d vàng" % lay


static func _bang(tt: Dictionary, ten: String) -> Dictionary:
	return tt.get(ten, {}) as Dictionary
