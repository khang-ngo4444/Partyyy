class_name LuatDo
extends RefCounted

## Dùng một món: kiểm điều kiện, tiêu món, chuyển cho file luật của nhóm món.
## `du_lieu`: TIA/NON/CHON_NGUOI → {"muc_tieu": k}, CHON_O → {"o"}, CHON_MINIGAME → {"minigame"}.


## Lý do không dùng được; rỗng = dùng được.
static func ly_do_khong_dung(tt: Dictionary, k: String, chi_so: int) -> String:
	var tui: Array = (tt.get("do", {}) as Dictionary).get(k, [])
	if chi_so < 0 or chi_so >= tui.size():
		return "không có món đó"
	if VatPham.nham(str(tui[chi_so])) == VatPham.Nham.TU_DONG:
		return "món tự động"
	if (tt.get("da_dung", {}) as Dictionary).has(k):
		return "lượt này đã dùng đồ"
	if LuatHieuUng.bi_khoa_do(tt, k):
		return "đang dính mắm tôm"
	return ""


## Kiểm mục tiêu cho món chọn người/chọn ô (món ngắm do master raycast).
static func muc_tieu_hop_le(tt: Dictionary, k: String, mon: String, du_lieu: Dictionary,
		ban: BanDuong) -> bool:
	match VatPham.nham(mon):
		VatPham.Nham.CHON_NGUOI:
			var km := str(du_lieu.get("muc_tieu", ""))
			return km != k and (tt.get("o", {}) as Dictionary).has(km)
		VatPham.Nham.CHON_O:
			var bac := []
			bac.resize(VatPham.tam(mon) + 1)
			bac.fill(0)
			return ban.o_trung_bom(int(tt["o"][k]), bac).has(int(du_lieu.get("o", -1)))
	return true


## Tiêu món và áp hiệu ứng. Trả về {"su", "het_luot", "duong"}.
static func dung(tt: Dictionary, k: String, chi_so: int, du_lieu: Dictionary, ban: BanDuong,
		settings: Dictionary, ten: Callable) -> Dictionary:
	var mon := LuatBan.rut_do(tt, k, chi_so)
	if not (tt.get("da_dung") is Dictionary):
		tt["da_dung"] = {}
	tt["da_dung"][k] = true
	var km := str(du_lieu.get("muc_tieu", ""))
	var ra := {"su": "", "het_luot": false, "duong": []}
	match mon:
		"sung_1_phat", "dep_to_ong", "kinh_lup", "can_cau":
			ra["su"] = LuatTanCong.ban_tia(tt, k, mon, km, settings, ten)
		"vot_luoi":
			ra["su"] = LuatTanCong.vot(tt, k, km, ten)
		"chao_hanh":
			ra["su"] = LuatTanCong.chao(tt, k, settings)
		"vo_sau_rieng":
			LuatBay.dat_bay(tt, k)
			ra["su"] = "đặt bẫy tại ô %d" % int(tt["o"][k])
		"rao_tre":
			LuatBay.dat_rao(tt, k)
			ra["su"] = "dựng rào tại ô %d" % int(tt["o"][k])
		"phao_day":
			ra["su"] = LuatTanCong.phao_day(tt, k, ban, settings, ten)
		"hai_hot":
			tt["hai_hot"] = k
			ra["su"] = "lượt này tung 2 xúc xắc"
		"xe_phao":
			ra["su"] = "nổ ô %d: %s" % [int(du_lieu["o"]),
					LuatTanCong.xe_phao(tt, k, int(du_lieu["o"]), ban, settings, ten)]
		"dua_roi":
			ra["su"] = LuatTanCong.ap_don(tt, km, LuatTanCong.DUA_SAT_THUONG, settings, ten)
		"bua_hoan_doi":
			ra["su"] = LuatTanCong.bua(tt, k, km, ten) + " · hết lượt"
			ra["het_luot"] = true
		"trau_dien":
			var trau := LuatTanCong.trau(tt, k, ban, settings, ten)
			ra["su"] = str(trau["su"])
			ra["duong"] = trau["duong"]
		"ong_heo":
			ra["su"] = "đập heo +%d vàng" % LuatHieuUng.dap_heo(tt, k)
		"coi_trong_tai":
			tt["coi"] = str(du_lieu.get("minigame", ""))
			ra["su"] = "chọn minigame vòng này"
		"day_thun":
			LuatHieuUng.dat_neo(tt, k)
			ra["su"] = "neo tại ô %d" % int(tt["o"][k])
		"mam_tom":
			LuatHieuUng.dat_doc(tt, km)
			ra["su"] = "%s dính mắm tôm %d lượt" % [ten.call(km), LuatHieuUng.DOC_SO_LUOT]
		"cho_ngao":
			LuatHieuUng.tha_quai(tt, k)
			ra["su"] = "thả chó ngao tại ô %d" % int(tt["o"][k])
	return ra
