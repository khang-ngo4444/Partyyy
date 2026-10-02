class_name DuongVet
extends RefCounted

## HÌNH của vệt sáng Temporal Trails — hàm thuần, không đụng node, không đụng mạng.
##
## Tách riêng để `kiem_luat.gd` chạy được bằng `godot --headless -s` (lệnh đó không nạp autoload,
## file nào chạm `NetManager` là không biên dịch nổi).
##
## ## Một vệt là gì
##
## Một đường cong LIỀN, lấy mẫu đều mỗi `BUOC` mét trên mặt sàn (toạ độ xz, tâm sân là gốc). Ghép
## từ các đoạn: thẳng · cong · chữ S · vòng tròn. Mỗi đoạn là một cung có độ cong không đổi, nên
## đường luôn trơn — không có góc gãy, không có ô lưới.
##
## Cùng `(hạt giống, vòng, thứ tự người)` thì mọi máy ra cùng một đường: 0 gói tin cho cả vệt.

## Khoảng cách giữa hai điểm mẫu, mét.
const BUOC := 0.25
## Vệt không được ra xa tâm hơn chừng này. Sàn bán kính 11,5; trừ nửa bề rộng hợp lệ (1,25) và
## chỗ thở cho thân người, để đi đúng vệt không bao giờ phải chạm mép.
const R_MAX := 9.6
## Nửa bề rộng ĐƯỜNG HỢP LỆ, mét. Thân người rộng ~0,8 m; 1,25 cho phép lệch hơn một thân người
## mà chưa bị phạt — đi theo trí nhớ, không phải đi dây.
const BE_RONG := 1.25
## Vòng nhỏ nhất. Đường kính phải lớn hơn hẳn bề rộng hợp lệ (2,5 m), không thì vòng tròn chỉ là
## một vết loang và chẳng ai phân biệt được đâu là đi vòng, đâu là đi thẳng.
const R_VONG_MIN := 2.0

## Độ khó theo vòng, chỉ số 0..3. Vòng sau dài hơn, cong gắt hơn, có vòng tròn.
const DAI := [16.0, 24.0, 32.0, 40.0]
## Bán kính cong nhỏ nhất của đoạn cong thường.
const R_CONG_MIN := [4.5, 3.2, 2.6, 2.2]
## Góc quay lớn nhất của một đoạn cong, radian.
const GOC_MAX := [1.4, 2.1, 2.5, 2.7]
## Mỗi người có một "nhà" — vùng sân quanh góc xuất phát của mình — và vệt bị uốn về nhà khi đi
## xa quá `XA_NHA`. Không có nó thì mọi vệt cùng dồn vào giữa sân và rối thành một nắm. Nhà gần
## tâm dần theo vòng: vòng sau các vệt chồng lên nhau nhiều hơn, khó phân biệt hơn.
const NHA := [5.0, 4.4, 3.7, 3.0]
const XA_NHA := 3.8
## Xác suất mỗi loại đoạn: [thẳng, cong, chữ S, vòng tròn].
const TI_LE := [
	[0.40, 0.60, 0.00, 0.00],
	[0.25, 0.45, 0.30, 0.00],
	[0.18, 0.37, 0.25, 0.20],
	[0.12, 0.38, 0.25, 0.25],
]

enum { THANG, CONG, CHU_S, VONG }


static func so_vong() -> int:
	return DAI.size()


## Vệt của người thứ `i` (trong `so_nguoi` người) ở vòng `vong`.
static func tao(giong: int, vong: int, i: int, so_nguoi: int) -> PackedVector2Array:
	var v := clampi(vong, 0, DAI.size() - 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([giong, v, i])
	var xa_nhat := INF
	var tot := PackedVector2Array()
	# Thử lại tới khi cả vệt nằm trong sàn. Hầu hết lần thử đầu đã đạt; cùng hạt giống thì cùng
	# chuỗi lần thử, nên mọi máy vẫn ra một kết quả.
	for thu in 60:
		var ds := _thu_mot_lan(rng, v, i, so_nguoi)
		var r := _xa_tam_nhat(ds)
		if r <= R_MAX:
			return ds
		if r < xa_nhat:
			xa_nhat = r
			tot = ds
	# Lưới đỡ: co lần thử gọn nhất vào trong sàn. Cong gắt lên một chút, vẫn liền và trơn.
	var k := R_MAX / xa_nhat
	for j in tot.size():
		tot[j] *= k
	return tot


## Chiều dài thật của vệt, mét.
static func dai(ds: PackedVector2Array) -> float:
	return float(ds.size() - 1) * BUOC


## Tiến độ mới trên vệt và khoảng cách tới vệt.
##
## Chỉ xét phần vệt trong cửa sổ `[tien - LUI, tien + TOI]` quanh tiến độ hiện tại. Không có cửa
## sổ thì ở chỗ vệt tự cắt mình (vòng tròn) người chơi đi tắt qua tâm vòng là "tới" luôn phần sau
## — và ở chỗ vệt của hai người cắt nhau thì đi nhầm nhánh cũng không bị phạt.
##
## Trả về `Vector2(tien_moi, khoang_cach)`. Tiến độ chỉ tăng khi đang ở TRONG đường hợp lệ.
static func tien_do(ds: PackedVector2Array, tien: float, cho: Vector2) -> Vector2:
	const LUI := 2.0
	const TOI := 3.0
	var a := clampi(int((tien - LUI) / BUOC), 0, ds.size() - 1)
	var b := clampi(int((tien + TOI) / BUOC), 0, ds.size() - 1)
	var gan := INF
	var gan_j := a
	for j in range(a, b + 1):
		var d := ds[j].distance_squared_to(cho)
		if d < gan:
			gan = d
			gan_j = j
	var kc := sqrt(gan)
	var moi := tien
	if kc <= BE_RONG:
		moi = maxf(tien, float(gan_j) * BUOC)
	return Vector2(moi, kc)


## Hướng đi ở đầu vệt — để quay mặt người chơi đúng chiều lúc xuất phát.
static func huong_dau(ds: PackedVector2Array) -> Vector2:
	if ds.size() < 2:
		return Vector2.UP
	return (ds[mini(4, ds.size() - 1)] - ds[0]).normalized()


# ─────────────────────────────── bên trong ───────────────────────────────

static func _thu_mot_lan(rng: RandomNumberGenerator, v: int, i: int,
		so_nguoi: int) -> PackedVector2Array:
	# Xuất phát rải quanh sàn theo thứ tự người, hướng vào trong — mỗi người một góc sân, nên đi
	# theo người khác là đi sai đường ngay từ bước đầu.
	var goc := TAU * float(i) / float(maxi(so_nguoi, 1)) + rng.randf_range(-0.35, 0.35)
	var nha := Vector2(cos(goc), sin(goc)) * float(NHA[v])
	var cho := Vector2(cos(goc), sin(goc)) * rng.randf_range(6.5, 8.0)
	var huong := (nha - cho).normalized().rotated(rng.randf_range(-0.9, 0.9))
	var ds := PackedVector2Array([cho])
	var can := int(float(DAI[v]) / BUOC)
	var tri_truoc := 0.0
	while ds.size() <= can:
		for doan in _chon_doan(rng, v, cho, huong, tri_truoc, nha):
			var cong: float = doan.x
			var n := maxi(int(doan.y / BUOC), 1)
			for k in n:
				huong = huong.rotated(cong * BUOC)
				cho += huong * BUOC
				ds.append(cho)
				if ds.size() > can:
					return ds
			tri_truoc = signf(cong) if cong != 0.0 else tri_truoc
	return ds


## Một đoạn (hoặc hai, với chữ S) dưới dạng `Vector2(độ cong, chiều dài)`. Độ cong = ±1/bán kính.
##
## Hướng rẽ không hoàn toàn ngẫu nhiên: xa tâm thì ưu tiên rẽ VÀO trong. Đó là thứ giữ vệt ở trong
## sàn mà không phải bẻ lái gắt ở mép — đường vẫn trơn, chỉ là "uốn" về phía có chỗ.
static func _chon_doan(rng: RandomNumberGenerator, v: int, cho: Vector2, huong: Vector2,
		tri_truoc: float, nha: Vector2) -> Array[Vector2]:
	var ti: Array = TI_LE[v]
	var x := rng.randf()
	var loai := THANG
	var cong_don := 0.0
	for k in ti.size():
		cong_don += float(ti[k])
		if x < cong_don:
			loai = k
			break
	# Phía nào là "về nhà": dấu của tích có hướng giữa hướng đi và hướng về nhà. Gần mép sân thì
	# về TÂM thay vì về nhà — giữ vệt trong sàn trước đã.
	var dich := -cho if cho.length() > R_MAX - 2.5 else nha - cho
	var vao := signf(huong.cross(dich))
	if vao == 0.0:
		vao = 1.0
	var xa := cho.length() > R_MAX - 2.5 or cho.distance_to(nha) > XA_NHA
	var tri := vao if xa or rng.randf() < 0.35 else -vao
	# Hai đoạn cong liên tiếp cùng chiều là thành vòng tròn không chủ đích; đổi chiều cho đường
	# có nhịp trái-phải dễ nhớ.
	if tri == tri_truoc and rng.randf() < 0.5 and not xa:
		tri = -tri
	match loai:
		THANG:
			var d := rng.randf_range(2.0, 4.5)
			if (cho + huong * d).length() > R_MAX - 1.0:
				# Thẳng ra mép thì thay bằng một khúc cong vào trong.
				return [Vector2(vao / R_CONG_MIN[v], rng.randf_range(1.2, 2.0) * R_CONG_MIN[v])]
			return [Vector2(0.0, d)]
		CONG:
			var r := rng.randf_range(R_CONG_MIN[v], R_CONG_MIN[v] * 1.8)
			var g := rng.randf_range(0.6, GOC_MAX[v])
			return [Vector2(tri / r, r * g)]
		CHU_S:
			var r := rng.randf_range(R_CONG_MIN[v], R_CONG_MIN[v] * 1.5)
			var g := rng.randf_range(0.8, 1.4)
			return [Vector2(tri / r, r * g), Vector2(-tri / r, r * g)]
		_:
			var r := rng.randf_range(R_VONG_MIN, R_VONG_MIN * 1.35)
			# Hơn một vòng một chút để đường ra khỏi vòng lệch đi, không trùng đường vào.
			return [Vector2(tri / r, r * (TAU + rng.randf_range(0.3, 0.8)))]


static func _xa_tam_nhat(ds: PackedVector2Array) -> float:
	var r := 0.0
	for p in ds:
		r = maxf(r, p.length())
	return r
