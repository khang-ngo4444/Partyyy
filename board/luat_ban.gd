class_name LuatBan
extends RefCounted

## Luật thuần của bàn party (không đụng scene/mạng).

enum Thue { DAT, MAU, TIEN, TRANG_BI }
const TEN_THUE := ["đất", "máu", "tiền", "trang bị"]
## Sát thương của món "gục ngay".
const GUC := 1000
## Bảng trạng thái giữ nguyên khi sang vòng mới.
const BANG_GIU_QUA_VONG := ["bay", "rao", "neo", "doc", "heo", "quai", "chieu", "animation_events"]


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


## Túi là mảng ô cố định ("" = trống; xem `VatPham.SO_O_NHANH`). Món mới vào ô trống đầu tiên
## (ô dùng nhanh trước, rồi tới kho). Túi đầy thì món mới rơi mất. Trả về lời báo ("" = không mất gì).
static func them_do(tt: Dictionary, k: String, mon: String) -> String:
	if mon.is_empty():
		return ""
	var tui: Array = _bang(tt, "do").get(k, [])
	var trong := tui.find("")
	if trong >= 0:
		tui[trong] = mon
	elif tui.size() < VatPham.TUI_TOI_DA:
		tui.append(mon)
	else:
		return " (túi đầy, mất %s)" % VatPham.ten(mon)
	_bang(tt, "do")[k] = tui
	return ""


## Lấy món ở ô `chi_so` ra khỏi túi (ô thành trống). "" = ô trống / sai chỉ số.
static func rut_do(tt: Dictionary, k: String, chi_so: int) -> String:
	var tui: Array = _bang(tt, "do").get(k, [])
	if chi_so < 0 or chi_so >= tui.size():
		return ""
	var mon := str(tui[chi_so])
	tui[chi_so] = ""
	_bang(tt, "do")[k] = _gon_duoi(tui)
	return mon


## Bỏ một món theo tên (ô đầu tiên có món đó). Không xô lệch các ô khác.
static func xoa_mon(tt: Dictionary, k: String, mon: String) -> bool:
	var tui: Array = _bang(tt, "do").get(k, [])
	var i := tui.find(mon)
	if i < 0:
		return false
	rut_do(tt, k, i)
	return true


## Lấy món đầu tiên có trong túi (thuế đồ, vợt cướp). "" = túi rỗng.
static func lay_mon_dau(tt: Dictionary, k: String) -> String:
	var tui: Array = _bang(tt, "do").get(k, [])
	for i in tui.size():
		if str(tui[i]) != "":
			return rut_do(tt, k, i)
	return ""


static func so_mon(tui: Array) -> int:
	return tui.reduce(func(n, mon) -> int: return n + (0 if str(mon) == "" else 1), 0)


## Đổi chỗ hai ô (ô trống cũng được). Sai chỉ số thì bỏ qua.
static func doi_cho(tt: Dictionary, k: String, a: int, b: int) -> bool:
	if a == b or a < 0 or b < 0 or a >= VatPham.TUI_TOI_DA or b >= VatPham.TUI_TOI_DA:
		return false
	var tui: Array = _bang(tt, "do").get(k, [])
	while tui.size() <= maxi(a, b):
		tui.append("")
	var tam = tui[a]
	tui[a] = tui[b]
	tui[b] = tam
	_bang(tt, "do")[k] = _gon_duoi(tui)
	return true


## Cắt các ô trống ở cuối cho gói mạng gọn.
static func _gon_duoi(tui: Array) -> Array:
	while not tui.is_empty() and str(tui.back()) == "":
		tui.pop_back()
	return tui


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
	if sat_thuong > 0:
		animation_event(tt, k, "hit")
	return con <= 0


static func co_khien(tt: Dictionary, k: String) -> bool:
	return (_bang(tt, "do").get(k, []) as Array).has("khien")


static func tieu_khien(tt: Dictionary, k: String) -> void:
	xoa_mon(tt, k, "khien")


## Hồi đầy máu, về checkpoint (hoặc ô neo). Không mất vàng, không mất Cúp.
static func chet(tt: Dictionary, k: String, settings: Dictionary) -> void:
	animation_event(tt, k, "death")
	_bang(tt, "mau")[k] = int(settings.get("max_health", 10))
	_bang(tt, "o")[k] = LuatHieuUng.khi_guc(tt, k, int(_bang(tt, "hoi_sinh").get(k, 0)))


## HP is restored in the same snapshot on death, so replicate an explicit reaction.
static func animation_event(tt: Dictionary, key: String, kind: String) -> void:
	if not tt.has("animation_events"):
		tt.animation_events = {}
	var previous: Dictionary = tt.animation_events.get(key, {})
	tt.animation_events[key] = {"serial": int(previous.get("serial", 0)) + 1, "kind": kind}


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
			var mon := lay_mon_dau(tt, khach)
			if mon != "":
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
