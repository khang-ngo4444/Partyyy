class_name KinhTe
extends RefCounted

## Kinh tế ván: số vòng theo số người và vàng/đồ thưởng sau minigame.
## Mỗi người kiếm ~`VANG_CA_VAN` vàng cả ván; hạng nhất hơn trung bình 30%, hạng chót kém 30%.

const VANG_CA_VAN := 250.0
## Một ván ~35 phút: lượt ~20 s, minigame ~90 s + 15 s chuyển cảnh.
const GIAY_MOI_VAN := 2100.0
const GIAY_MINIGAME := 105.0
const GIAY_MOI_LUOT := 20.0
const HE_SO_NHAT := 1.3
const HE_SO_CHOT := 0.7
## Hai vòng cuối vàng minigame ×1,5.
const SO_VONG_CUOI := 2
const NHAN_VONG_CUOI := 1.5


## `so_vong` > 0 = chủ phòng tự đặt; 0 = tự tính.
static func so_vong(n: int, settings: Dictionary) -> int:
	var tu_dat := int(settings.get("so_vong", 0))
	if tu_dat > 0:
		return tu_dat
	return maxi(1, roundi(GIAY_MOI_VAN / (GIAY_MINIGAME + GIAY_MOI_LUOT * n)))


## Vàng minigame trung bình mỗi vòng = phần còn thiếu sau thu nhập từ ô tiền.
static func vang_trung_binh(r: int, settings: Dictionary) -> float:
	var tu_o := int(settings.get("tile_money", 25)) / 100.0 * int(settings.get("money_gain", 15))
	return maxf(0.0, VANG_CA_VAN / maxi(r, 1) - tu_o)


## `hang` tính từ 0, làm tròn tới bội số 5.
static func vang_hang(hang: int, n: int, r: int, settings: Dictionary, nhan := 1.0) -> int:
	var he_so := 1.0 if n <= 1 else HE_SO_NHAT - (HE_SO_NHAT - HE_SO_CHOT) * hang / float(n - 1)
	return int(snappedf(vang_trung_binh(r, settings) * he_so * nhan, 5.0))


## 2–4 người → 1, 5–8 → 2, 9–10 → 3.
static func so_nguoi_nhan_do(n: int) -> int:
	return ceili(n / 4.0)


## Trả thưởng cho cả bàn; trả về dòng sự kiện.
static func thuong_minigame(tt: Dictionary, xep_hang: Array, settings: Dictionary,
		rng: RandomNumberGenerator) -> String:
	var n := xep_hang.size()
	if n == 0:
		return ""
	var r := int(tt.get("so_vong", 1))
	var nhan := NHAN_VONG_CUOI if int(tt.get("vong", 1)) > r - SO_VONG_CUOI else 1.0
	var top := so_nguoi_nhan_do(n)
	var dong := PackedStringArray()
	for i in n:
		var k := LuatBan.khoa(xep_hang[i])
		var vang := vang_hang(i, n, r, settings, nhan)
		var tien: Dictionary = tt.get("tien", {}) as Dictionary
		tien[k] = int(tien.get(k, 0)) + vang
		var mon := ""
		var roi := ""
		if i == 0:
			mon = VatPham.rut_hang_nhat(rng)
		elif i < top or (n >= 3 and i == n - 1):
			mon = VatPham.rut_nhom(VatPham.Hiem.THUONG, rng)
		if not mon.is_empty():
			roi = LuatBan.them_do(tt, k, mon)
		dong.append("Hạng %d +%d vàng%s%s" % [i + 1, vang,
				"" if mon.is_empty() else " +" + VatPham.ten(mon), roi])
	return " · ".join(dong)
