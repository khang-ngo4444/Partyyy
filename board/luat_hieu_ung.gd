class_name LuatHieuUng
extends RefCounted

## Hiệu ứng kéo dài của vật phẩm: `neo` (Dây thun), `doc` (Mắm tôm), `heo` (Ống heo),
## `quai` (Chó ngao). `ten` = Callable(k) -> tên người.

const NEO_SO_LUOT := 2
const DOC_SO_LUOT := 3
const DOC_SAT_THUONG := 1
const HEO_MOI_VONG := 5
const HEO_TOI_DA := 30
const QUAI_SO_VONG := 3


# ───────────────────────────── Dây thun ─────────────────────────────

static func dat_neo(tt: Dictionary, k: String) -> void:
	var o := int(_bang(tt, "o").get(k, 0))
	_bang_tao(tt, "neo")[k] = {"o": o, "duong": [o], "con": NEO_SO_LUOT}


## Ghi đoạn vừa đi để lúc giật lùi đi đúng đường cũ.
static func ghi_duong(tt: Dictionary, k: String, duong: Array) -> void:
	var neo: Dictionary = _bang(tt, "neo").get(k, {})
	if neo.is_empty() or duong.size() < 2:
		return
	var da_di: Array = neo.get("duong", [])
	for i in range(1, duong.size()):
		da_di.append(int(duong[i]))
	neo["duong"] = da_di


## Đang neo mà trúng đòn thường: giật về ô neo, chịu nửa sát thương.
static func khi_trung_don(tt: Dictionary, k: String, sat_thuong: int) -> int:
	var neo: Dictionary = _bang(tt, "neo").get(k, {})
	if neo.is_empty() or sat_thuong >= LuatBan.GUC:
		return sat_thuong
	var nua := ceili(sat_thuong / 2.0)
	# Nửa đòn vẫn đủ gục thì giữ neo để hồi sinh ở đó.
	if int(_bang(tt, "mau").get(k, 0)) - nua > 0:
		_bang(tt, "o")[k] = int(neo["o"])
		_bang(tt, "neo").erase(k)
	return nua


## Gục: heo vỡ; đang neo thì hồi sinh ở ô neo. Trả về ô hồi sinh.
static func khi_guc(tt: Dictionary, k: String, checkpoint: int) -> int:
	var tui: Array = _bang(tt, "do").get(k, [])
	tui.erase("ong_heo")
	_bang(tt, "heo").erase(k)
	var neo: Dictionary = _bang(tt, "neo").get(k, {})
	if neo.is_empty():
		return checkpoint
	_bang(tt, "neo").erase(k)
	return int(neo["o"])


# ───────────────────────────── Mắm tôm ─────────────────────────────

static func dat_doc(tt: Dictionary, k: String) -> void:
	_bang_tao(tt, "doc")[k] = DOC_SO_LUOT


static func bi_khoa_do(tt: Dictionary, k: String) -> bool:
	return int(_bang(tt, "doc").get(k, 0)) > 0


# ───────────────────────────── Ống heo ─────────────────────────────

static func dap_heo(tt: Dictionary, k: String) -> int:
	var vang := int(_bang(tt, "heo").get(k, 0))
	_bang(tt, "heo").erase(k)
	var tien: Dictionary = _bang(tt, "tien")
	tien[k] = int(tien.get(k, 0)) + vang
	return vang


# ───────────────────────────── Chó ngao ─────────────────────────────

static func tha_quai(tt: Dictionary, k: String) -> void:
	tt["quai"] = {"o": int(_bang(tt, "o").get(k, 0)), "chu": k, "con": QUAI_SO_VONG}


# ───────────────────────────── nhịp lượt / vòng ─────────────────────────────

## Cuối lượt: mắm tôm cắn, Dây thun đếm lùi rồi giật về nửa đường.
static func cuoi_luot(tt: Dictionary, k: String, settings: Dictionary, ten: Callable) -> String:
	var dong := PackedStringArray()
	var doc: Dictionary = _bang(tt, "doc")
	if int(doc.get(k, 0)) > 0:
		doc[k] = int(doc[k]) - 1
		if int(doc[k]) <= 0:
			doc.erase(k)
		if LuatBan.tru_mau(tt, k, DOC_SAT_THUONG):
			LuatBan.chet(tt, k, settings)
			dong.append("mắm tôm -1 máu · gục")
		else:
			dong.append("mắm tôm -1 máu")
	var neo: Dictionary = _bang(tt, "neo").get(k, {})
	if not neo.is_empty():
		neo["con"] = int(neo["con"]) - 1
		if int(neo["con"]) <= 0:
			var da_di: Array = neo.get("duong", [])
			var lui := (da_di.size() - 1) / 2
			_bang(tt, "o")[k] = int(da_di[da_di.size() - 1 - lui])
			_bang(tt, "neo").erase(k)
			dong.append("Dây thun giật lùi %d ô" % lui)
	return "" if dong.is_empty() else "%s: %s" % [ten.call(k), " · ".join(dong)]


## Hết vòng: heo +vàng, chó ngao đi tuần.
static func het_vong(tt: Dictionary, settings: Dictionary, ban: BanDuong, ten: Callable) -> String:
	var dong := PackedStringArray()
	var heo := _bang_tao(tt, "heo")
	for k in _bang(tt, "do"):
		if (_bang(tt, "do")[k] as Array).has("ong_heo"):
			heo[k] = mini(int(heo.get(k, 0)) + HEO_MOI_VONG, HEO_TOI_DA)
	var quai: Dictionary = _bang(tt, "quai")
	if quai.is_empty():
		return ""
	var duong := Array(ban.duong_thang(int(quai["o"]), 1, VatPham.tam("cho_ngao"))).slice(1)
	if not duong.is_empty():
		for k in _bang(tt, "o"):
			if k == str(quai["chu"]) or not duong.has(int(_bang(tt, "o")[k])):
				continue
			if LuatBan.tru_mau(tt, k, LuatBan.GUC):
				LuatBan.chet(tt, k, settings)
				dong.append("Chó ngao cắn gục %s" % ten.call(k))
			else:
				dong.append("%s đỡ được chó ngao" % ten.call(k))
		quai["o"] = int(duong[duong.size() - 1])
	quai["con"] = int(quai["con"]) - 1
	if int(quai["con"]) <= 0:
		tt["quai"] = {}
		dong.append("Chó ngao về chuồng")
	return " · ".join(dong)


static func _bang(tt: Dictionary, ten: String) -> Dictionary:
	return tt.get(ten, {}) as Dictionary


static func _bang_tao(tt: Dictionary, ten: String) -> Dictionary:
	if not (tt.get(ten) is Dictionary):
		tt[ten] = {}
	return tt[ten]
