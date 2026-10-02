extends SceneTree

# Kiem luat Sidestep Slope (lich xe). Chay:
#   godot --headless --path . -s minigame/sidestep/kiem_luat.gd

const XE := preload("res://minigame/sidestep/xe_doc.gd")
const GIAY_VAN := 35.0
## Xe dai 4,86 m, rong 1,8 m; nguoi rong 0,8 m.
const DAI_XE := 4.86
const RONG_XE := 1.8
const RONG_NGUOI := 0.8
## Long duong di duoc: tuong o +-7,3 day 0,6 -> mep trong +-7,0.
const MEP := 7.0
## Camera nhin thay chung nay met phia truoc nguoi choi.
const TAM_NHIN := 35.0

var _loi := 0


func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)


func _init() -> void:
	var hep_nhat := INF
	var hep_tai := ""
	for g in range(1, 31):
		var ds: Array = XE.lich(g * 7919, GIAY_VAN)
		ck(ds.size() > 20, "giong %d: chi %d xe" % [g, ds.size()])
		# 1. Khong xe nao o gan vach luc van mo
		for m in ds:
			var z0: float = XE.vi_tri(m["toc"], m["toi_vach"], 0.0)
			ck(z0 <= -XE.CACH_LUC_DAU + 0.001, "giong %d: xe o %.1f m luc van mo" % [g, z0])
		# 2. Moi luc, moi dai doc: phan duong con trong rong nhat phai du cho mot nguoi di qua
		var t := 0.0
		while t < GIAY_VAN:
			for z in range(-200, 1, 2):
				var bi_chiem: Array = []
				for m in ds:
					var zx: float = XE.vi_tri(m["toc"], m["toi_vach"], t)
					if absf(zx - float(z)) <= DAI_XE * 0.5 + 0.4:
						var x: float = m["x"]
						bi_chiem.append(Vector2(x - RONG_XE * 0.5, x + RONG_XE * 0.5))
				var khe := _khe_rong_nhat(bi_chiem)
				if khe < hep_nhat:
					hep_nhat = khe
					hep_tai = "giong %d, giay %.1f, z %d" % [g, t, z]
			t += 0.25
		# 3. Toc do khong bao gio vuot nguong thay-duoc-va-ne-duoc, va chi tang
		var truoc := 0.0
		for m in ds:
			ck(float(m["toc"]) >= truoc - 0.001, "giong %d: toc do giam" % g)
			truoc = float(m["toc"])
	ck(hep_nhat >= RONG_NGUOI + 1.5,
			"khe thoat hep nhat %.2f m (%s) - qua hep de lach" % [hep_nhat, hep_tai])
	var phan_ung := TAM_NHIN / XE.TOC_CUOI
	ck(phan_ung >= 1.8, "xe nhanh nhat chi cho %.2f s tu luc thay toi luc toi" % phan_ung)
	# 4. Xac dinh
	ck(str(XE.lich(5, GIAY_VAN)) == str(XE.lich(5, GIAY_VAN)), "cung hat giong ra hai lich khac nhau")
	print("OK  30 hat giong: khe thoat hep nhat %.2f m (%s)" % [hep_nhat, hep_tai])
	print("OK  xe nhanh nhat %.0f m/s cho %.1f s phan ung" % [XE.TOC_CUOI, phan_ung])
	print("--- %d loi ---" % _loi)
	quit()


## Khoang trong rong nhat giua cac doan bi chiem, trong long duong [-MEP, MEP].
func _khe_rong_nhat(ds: Array) -> float:
	ds.sort_custom(func(a, b) -> bool: return a.x < b.x)
	var tu := -MEP
	var rong := 0.0
	for d in ds:
		rong = maxf(rong, d.x - tu)
		tu = maxf(tu, d.y)
	return maxf(rong, MEP - tu)
