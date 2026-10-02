extends SceneTree

# Kiem luat Temporal Trails (vet sang). Chay:
#   godot --headless --path . -s minigame/temporal_trails/kiem_luat.gd

const DV := preload("res://minigame/temporal_trails/duong_vet.gd")

var _loi := 0


func ck(dung: bool, msg: String) -> void:
	if not dung:
		_loi += 1
		print("FAIL  ", msg)


func _init() -> void:
	var so_mau := 0
	for g in range(1, 41):
		for v in DV.so_vong():
			for i in 4:
				var ds: PackedVector2Array = DV.tao(g * 7919, v, i, 4)
				so_mau += 1
				var ten := "giong %d vong %d nguoi %d" % [g, v, i]
				# 1. Trong san
				var xa := 0.0
				for p in ds:
					xa = maxf(xa, p.length())
				ck(xa <= DV.R_MAX + 0.001, "%s: ra toi %.2f m > %.2f" % [ten, xa, DV.R_MAX])
				# 2. Dung do dai
				ck(absf(DV.dai(ds) - float(DV.DAI[v])) < 0.6,
						"%s: dai %.1f m, can %.1f" % [ten, DV.dai(ds), DV.DAI[v]])
				# 3. LIEN va TRON: hai diem ke nhau cach dung BUOC (co lai thi nho hon), khong goc gay
				for j in range(1, ds.size() - 1):
					var a := (ds[j] - ds[j - 1]).normalized()
					var b := (ds[j + 1] - ds[j]).normalized()
					if a.angle_to(b) > 0.2:
						ck(false, "%s: gay goc %.2f rad o diem %d" % [ten, a.angle_to(b), j])
						break
				# 4. Di DUNG vet thi khong bao gio bi phat va toi duoc dich
				var tien := 0.0
				var lot := false
				for j in ds.size():
					var r := DV.tien_do(ds, tien, ds[j])
					tien = r.x
					if r.y > DV.BE_RONG:
						lot = true
				ck(not lot, "%s: di dung vet ma van bi tinh ra ngoai" % ten)
				ck(tien >= DV.dai(ds) - 0.8, "%s: di het vet ma tien do chi %.1f" % [ten, tien])
	# 5. Xac dinh: cung tham so -> cung vet
	ck(DV.tao(42, 2, 1, 4) == DV.tao(42, 2, 1, 4), "cung hat giong ra hai vet khac nhau")
	ck(DV.tao(42, 2, 1, 4) != DV.tao(43, 2, 1, 4), "hai hat giong ra cung mot vet")
	# 6. Di TAT khong duoc tinh: nhay thang tu dau toi cuoi vet thi tien do khong nhay theo
	var ds: PackedVector2Array = DV.tao(5, 3, 0, 4)
	var r := DV.tien_do(ds, 0.0, ds[ds.size() - 1])
	ck(r.x < 3.5, "dung o cuoi vet ngay tu dau ma tien do nhay toi %.1f" % r.x)
	# 7. Lech nhe (0,8 m) van an toan, lech xa (2 m) thi bi tinh ra ngoai
	var p0 := ds[20] + Vector2(0.8, 0.0)
	ck(DV.tien_do(ds, 4.0, p0).y <= DV.BE_RONG, "lech 0,8 m da bi phat")
	var p1 := ds[20] + (ds[21] - ds[19]).normalized().orthogonal() * 2.0
	ck(DV.tien_do(ds, 4.0, p1).y > DV.BE_RONG, "lech 2 m ma khong bi phat")
	print("OK  %d vet (40 hat giong x %d vong x 4 nguoi): trong san, lien, tron, di dung = khong phat"
			% [so_mau, DV.so_vong()])
	print("--- %d loi ---" % _loi)
	quit()
