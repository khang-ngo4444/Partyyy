class_name LuatTanCong
extends RefCounted

## Các món gây sát thương / dời chỗ / cướp đồ. Ai trúng do `NgamMucTieu` tính.
## Mọi đòn qua `ap_don` → `LuatBan.tru_mau`.

const CAN_CAU_SAT_THUONG := 2
const VOT_CUOP_VANG := 15
const PHAO_DAY_SAT_THUONG := 2
const XE_PHAO_BAC := [5, 2]
const DUA_SAT_THUONG := 3
const TRAU_SAT_THUONG := 4
const CHAO_HOI_MAU := 5


## Một đòn lên `k`; gục thì hồi sinh luôn. Trả về mẩu sự kiện.
static func ap_don(tt: Dictionary, k: String, sat_thuong: int, settings: Dictionary,
		ten: Callable) -> String:
	var co_khien := LuatBan.co_khien(tt, k)
	var mau: Dictionary = tt.get("mau", {}) as Dictionary
	var truoc := int(mau.get(k, 0))
	var o_truoc := int((tt.get("o", {}) as Dictionary).get(k, 0))
	if LuatBan.tru_mau(tt, k, sat_thuong):
		LuatBan.chet(tt, k, settings)
		return "%s gục" % ten.call(k)
	if co_khien:
		return "%s đỡ bằng Úp thúng" % ten.call(k)
	var su := "%s -%d máu" % [ten.call(k), truoc - int(mau.get(k, 0))]
	if int((tt.get("o", {}) as Dictionary).get(k, 0)) != o_truoc:
		su += " · Dây thun giật về"
	return su


## Ná cao su, Dép tổ ong, Kính lúp, Cần câu. `km` rỗng = trượt.
static func ban_tia(tt: Dictionary, k: String, mon: String, km: String, settings: Dictionary,
		ten: Callable) -> String:
	if km.is_empty() or km == k:
		return "trượt"
	match mon:
		"sung_1_phat":
			return ap_don(tt, km, int(settings.get("weapon_damage", 4)), settings, ten)
		"can_cau":
			var bi_chan := LuatBan.co_khien(tt, km)
			var su := ap_don(tt, km, CAN_CAU_SAT_THUONG, settings, ten)
			if not bi_chan:
				var o: Dictionary = tt["o"]
				o[km] = int(o.get(k, 0))
				su += " · bị kéo về"
			return su
		_:
			return ap_don(tt, km, LuatBan.GUC, settings, ten)


## Cướp món đầu trong túi; túi rỗng thì cướp vàng.
static func vot(tt: Dictionary, k: String, km: String, ten: Callable) -> String:
	if km.is_empty() or km == k:
		return "trượt"
	var tui: Array = (tt["do"] as Dictionary).get(km, [])
	if not tui.is_empty():
		var mon := str(tui.pop_front())
		LuatBan.them_do(tt, k, mon)
		return "cướp %s của %s" % [VatPham.ten(mon), ten.call(km)]
	var tien: Dictionary = tt["tien"]
	var lay := mini(VOT_CUOP_VANG, int(tien.get(km, 0)))
	tien[km] = int(tien.get(km, 0)) - lay
	tien[k] = int(tien.get(k, 0)) + lay
	return "cướp %d vàng của %s" % [lay, ten.call(km)]


static func chao(tt: Dictionary, k: String, settings: Dictionary) -> String:
	var mau: Dictionary = tt["mau"]
	var truoc := int(mau.get(k, 0))
	mau[k] = mini(truoc + CHAO_HOI_MAU, int(settings.get("max_health", 10)))
	return "+%d máu" % (int(mau[k]) - truoc)


## Đánh mọi người (trừ `k`) trên các ô của `bac` ({ô: sát thương}).
static func danh_vung(tt: Dictionary, k: String, bac: Dictionary, settings: Dictionary,
		ten: Callable) -> String:
	var dong := PackedStringArray()
	var o: Dictionary = tt["o"]
	for km in o.keys():
		if km != k and bac.has(int(o[km])):
			dong.append(ap_don(tt, km, int(bac[int(o[km])]), settings, ten))
	return "không trúng ai" if dong.is_empty() else ", ".join(dong)


static func bac_phao_day() -> Array:
	var bac := []
	for _i in VatPham.tam("phao_day") + 1:
		bac.append(PHAO_DAY_SAT_THUONG)
	return bac


static func phao_day(tt: Dictionary, k: String, ban: BanDuong, settings: Dictionary,
		ten: Callable) -> String:
	return danh_vung(tt, k, ban.o_trung_bom(int(tt["o"][k]), bac_phao_day()), settings, ten)


## Các ô bị nổ của món nổ vùng (`o_tam`: ô người dùng với Pháo dây, ô được chọn với Xe pháo);
## rỗng nếu món không nổ vùng. Gói hiệu ứng gửi danh sách này để mọi máy nổ đúng ô.
static func vung_no(mon: String, o_tam: int, ban: BanDuong) -> Array:
	match mon:
		"phao_day":
			return ban.o_trung_bom(o_tam, bac_phao_day()).keys()
		"xe_phao":
			return ban.o_trung_bom(o_tam, XE_PHAO_BAC).keys()
	return []


static func xe_phao(tt: Dictionary, k: String, o_tam: int, ban: BanDuong, settings: Dictionary,
		ten: Callable) -> String:
	return danh_vung(tt, k, ban.o_trung_bom(o_tam, XE_PHAO_BAC), settings, ten)


## Úp thúng của mục tiêu chặn được.
static func bua(tt: Dictionary, k: String, km: String, ten: Callable) -> String:
	if LuatBan.co_khien(tt, km):
		LuatBan.tieu_khien(tt, km)
		return "%s đỡ bằng Úp thúng" % ten.call(km)
	var o: Dictionary = tt["o"]
	var tam := int(o[k])
	o[k] = int(o[km])
	o[km] = tam
	return "đổi chỗ với %s" % ten.call(km)


## Lao thẳng theo chiều đi, húc người trên đường. Trả về {"su", "duong"}.
## ponytail: ngã rẽ lấy hướng đầu.
static func trau(tt: Dictionary, k: String, ban: BanDuong, settings: Dictionary,
		ten: Callable) -> Dictionary:
	var chieu := int((tt.get("chieu", {}) as Dictionary).get(k, 1))
	var duong := Array(ban.duong_thang(int(tt["o"][k]), chieu, VatPham.tam("trau_dien")))
	if duong.size() < 2:
		return {"su": "không có đường", "duong": []}
	var bac := {}
	for i in range(1, duong.size()):
		bac[int(duong[i])] = TRAU_SAT_THUONG
	var su := danh_vung(tt, k, bac, settings, ten)
	tt["o"][k] = int(duong[duong.size() - 1])
	return {"su": su, "duong": duong}
