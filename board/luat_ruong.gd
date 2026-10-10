class_name LuatRuong
extends RefCounted

## Rương báu và Cúp: đi qua rương đủ vàng → +1 Cúp, rương dời đi. Hết vòng, nhiều Cúp nhất thắng.

const CACH_TOI_THIEU := 10


## Mở nếu đủ vàng; rỗng = không mở.
## ponytail: tự mở, không hỏi — thêm hộp Có/Không khi vàng có chỗ tiêu khác.
static func mo(tt: Dictionary, k: String, settings: Dictionary) -> String:
	var gia := int(settings.get("chest_cost", 100))
	var tien: Dictionary = tt.get("tien", {}) as Dictionary
	if int(tien.get(k, 0)) < gia:
		return ""
	tien[k] = int(tien[k]) - gia
	var coc: Dictionary = tt.get("coc", {}) as Dictionary
	coc[k] = int(coc.get(k, 0)) + 1
	tt["coc"] = coc
	return "MỞ RƯƠNG BÁU +1 Cúp (-%d vàng)" % gia


## Ô mới cho rương: xa ô cũ, không có người; hết ô hợp lệ thì nới điều kiện.
static func cho_moi(so_o: int, cu: int, gan: Dictionary, co_nguoi: Array,
		rng: RandomNumberGenerator) -> int:
	var tot: Array = []
	var tam: Array = []
	for i in range(1, so_o):
		if i == cu:
			continue
		tam.append(i)
		if not gan.has(i) and not co_nguoi.has(i):
			tot.append(i)
	var ds := tot if not tot.is_empty() else tam
	return int(ds[rng.randi_range(0, ds.size() - 1)]) if not ds.is_empty() else cu


## Nhiều Cúp → nhiều vàng → đứng trước trong thứ tự lượt.
static func nguoi_thang(tt: Dictionary) -> int:
	var coc: Dictionary = tt.get("coc", {}) as Dictionary
	var tien: Dictionary = tt.get("tien", {}) as Dictionary
	var tot := -1
	var tot_diem := Vector2i(-1, -1)
	for id in tt.get("thu_tu", []) as Array:
		var k := LuatBan.khoa(id)
		var diem := Vector2i(int(coc.get(k, 0)), int(tien.get(k, 0)))
		if diem > tot_diem:
			tot_diem = diem
			tot = int(id)
	return tot
