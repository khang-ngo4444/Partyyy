class_name VatPham
extends RefCounted

## Danh mục vật phẩm: tên, độ hiếm, trọng số rơi, cách nhắm, tầm. Thêm món = thêm dòng vào `TEN`
## và `BANG`. Luật dùng ở `LuatDo`.

enum Hiem { THUONG, HIEM, HUYEN_THOAI }

## TU_DONG = không bấm dùng (Úp thúng tự đỡ đòn).
enum Nham { TAI_CHO, TIA, NON, CHON_NGUOI, CHON_O, CHON_MINIGAME, TU_DONG }

const TUI_TOI_DA := 3
const TY_LE_HUYEN_THOAI := 0.15
## Một ô ≈ 5 m.
const MET_MOI_O := 5.0
const TEN := {
	"sung_1_phat": "Ná cao su",
	"khien": "Úp thúng",
	"chao_hanh": "Bát cháo hành",
	"vo_sau_rieng": "Vỏ sầu riêng",
	"phao_day": "Pháo dây",
	"rao_tre": "Rào tre",
	"hai_hot": "Hai hột xí ngầu",
	"can_cau": "Cần câu",
	"vot_luoi": "Vợt bắt cá",
	"xe_phao": "Xe đồ chơi chở pháo",
	"dua_roi": "Dừa rơi",
	"bua_hoan_doi": "Bùa hoán đổi",
	"trau_dien": "Trâu điên",
	"ong_heo": "Ống heo đất",
	"coi_trong_tai": "Còi trọng tài",
	"day_thun": "Dây thun",
	"dep_to_ong": "Dép tổ ong",
	"mam_tom": "Nồi mắm tôm",
	"kinh_lup": "Kính lúp hội tụ",
	"cho_ngao": "Chó ngao xổng chuồng",
}

## id -> [độ hiếm, trọng số rơi, cách nhắm, tầm theo ô (0 = vô hạn/không có)].
const BANG := {
	"sung_1_phat": [Hiem.THUONG, 9, Nham.TIA, 7],
	"khien": [Hiem.THUONG, 9, Nham.TU_DONG, 0],
	"chao_hanh": [Hiem.THUONG, 9, Nham.TAI_CHO, 0],
	"vo_sau_rieng": [Hiem.THUONG, 9, Nham.TAI_CHO, 0],
	"phao_day": [Hiem.THUONG, 9, Nham.TAI_CHO, 2],
	"rao_tre": [Hiem.THUONG, 9, Nham.TAI_CHO, 0],
	"hai_hot": [Hiem.THUONG, 9, Nham.TAI_CHO, 0],
	"can_cau": [Hiem.HIEM, 4, Nham.TIA, 6],
	"vot_luoi": [Hiem.HIEM, 4, Nham.NON, 4],
	"xe_phao": [Hiem.HIEM, 4, Nham.CHON_O, 5],
	"dua_roi": [Hiem.HIEM, 4, Nham.CHON_NGUOI, 0],
	"bua_hoan_doi": [Hiem.HIEM, 4, Nham.CHON_NGUOI, 0],
	"trau_dien": [Hiem.HIEM, 4, Nham.TAI_CHO, 8],
	"ong_heo": [Hiem.HIEM, 4, Nham.TAI_CHO, 0],
	"coi_trong_tai": [Hiem.HIEM, 4, Nham.CHON_MINIGAME, 0],
	"day_thun": [Hiem.HIEM, 4, Nham.TAI_CHO, 0],
	"dep_to_ong": [Hiem.HIEM, 1, Nham.TIA, 5],
	"mam_tom": [Hiem.HUYEN_THOAI, 0, Nham.CHON_NGUOI, 0],
	"kinh_lup": [Hiem.HUYEN_THOAI, 0, Nham.TIA, 0],
	"cho_ngao": [Hiem.HUYEN_THOAI, 0, Nham.TAI_CHO, 4],
}


static func ten(mon: String) -> String:
	return str(TEN.get(mon, mon))


static func nham(mon: String) -> int:
	return int(BANG[mon][2]) if BANG.has(mon) else Nham.TU_DONG


## 0 = không giới hạn.
static func tam(mon: String) -> int:
	return int(BANG[mon][3]) if BANG.has(mon) else 0


static func la_ngam(mon: String) -> bool:
	var n := nham(mon)
	return n == Nham.TIA or n == Nham.NON


static func la_chon(mon: String) -> bool:
	var n := nham(mon)
	return n == Nham.CHON_NGUOI or n == Nham.CHON_O or n == Nham.CHON_MINIGAME


static func rut_o(rng: RandomNumberGenerator) -> String:
	var tong := 0
	for mon in BANG:
		tong += int(BANG[mon][1])
	if tong <= 0:
		return ""
	var r := rng.randi_range(1, tong)
	for mon in BANG:
		r -= int(BANG[mon][1])
		if r <= 0:
			return mon
	return ""


## Rút đều trong nhóm; nhóm rỗng thì hạ xuống nhóm thấp hơn.
static func rut_nhom(hiem: int, rng: RandomNumberGenerator) -> String:
	for muc in range(hiem, -1, -1):
		var ds: Array = []
		for mon in BANG:
			if int(BANG[mon][0]) == muc:
				ds.append(mon)
		if not ds.is_empty():
			return str(ds[rng.randi_range(0, ds.size() - 1)])
	return ""


static func rut_hang_nhat(rng: RandomNumberGenerator) -> String:
	return rut_nhom(Hiem.HUYEN_THOAI if rng.randf() < TY_LE_HUYEN_THOAI else Hiem.HIEM, rng)
