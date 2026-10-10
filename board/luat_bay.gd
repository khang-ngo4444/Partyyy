class_name LuatBay
extends RefCounted

## Bẫy (Vỏ sầu riêng) và Rào tre trên ô. `bay`/`rao`: "ô" -> k chủ. Mỗi người 1 cái, chủ miễn nhiễm.

const BAY_SAT_THUONG := 2


static func dat_bay(tt: Dictionary, k: String) -> void:
	_dat(tt, "bay", k)


static func dat_rao(tt: Dictionary, k: String) -> void:
	_dat(tt, "rao", k)


## Trước khi bước sang ô `o`: vướng rào thì gỡ rào, trả sự kiện (người đi dừng lại).
static func vuong_rao(tt: Dictionary, k: String, o: int, ten: Callable) -> String:
	var rao := _bang(tt, "rao")
	var ko := str(o)
	if not rao.has(ko) or str(rao[ko]) == k:
		return ""
	var chu := str(rao[ko])
	rao.erase(ko)
	return "vướng rào tre của %s" % ten.call(chu)


## Sau khi bước lên ô `o`: dính bẫy → −2 máu, số bước còn lại chia đôi.
## Trả về {} hoặc {"con", "su", "o_cuoi"} (`o_cuoi` ≥ 0 = gục/giật về, dừng lượt).
static func giam_bay(tt: Dictionary, k: String, o: int, con: int, settings: Dictionary,
		ten: Callable) -> Dictionary:
	var bay := _bang(tt, "bay")
	var ko := str(o)
	if not bay.has(ko) or str(bay[ko]) == k:
		return {}
	var chu := str(bay[ko])
	bay.erase(ko)
	var vi_tri: Dictionary = _bang(tt, "o")
	var o_truoc := int(vi_tri.get(k, 0))
	vi_tri[k] = o
	var guc := LuatBan.tru_mau(tt, k, BAY_SAT_THUONG)
	var su := "giẫm vỏ sầu riêng của %s" % ten.call(chu)
	var o_cuoi := -1
	if guc:
		LuatBan.chet(tt, k, settings)
		su += " · gục"
		o_cuoi = int(vi_tri[k])
	elif int(vi_tri[k]) != o:
		su += " · Dây thun giật về"
		o_cuoi = int(vi_tri[k])
	vi_tri[k] = o_truoc
	return {"con": ceili(con / 2.0), "su": su, "o_cuoi": o_cuoi}


static func _dat(tt: Dictionary, ten: String, k: String) -> void:
	if not (tt.get(ten) is Dictionary):
		tt[ten] = {}
	var bang: Dictionary = tt[ten]
	for o in bang.keys():
		if str(bang[o]) == k:
			bang.erase(o)
	bang[str(int(_bang(tt, "o").get(k, 0)))] = k


static func _bang(tt: Dictionary, ten: String) -> Dictionary:
	return tt.get(ten, {}) as Dictionary
