class_name LuatBan
extends RefCounted

## LUẬT bàn party — máu, chìa, cốc, vật phẩm, tầm nổ.
##
## Cả file này là **hàm thuần**: không đụng node, không đụng Fusion, không đụng autoload. Nó
## chỉ đọc và ghi một `Dictionary` trạng thái. `PhaBanCo` lo phần mạng và phần scene, ở đây
## chỉ có luật chơi.
##
## Tách ra vì hai lý do, cả hai đều đã trả giá rồi:
##
## 1. **Kiểm được bằng `assert` mà không cần dựng phòng.** File phụ thuộc `NetManager` thì
##    `godot --script` không biên dịch nổi — `--script` KHÔNG nạp autoload.
## 2. Luật chơi và luật mạng đổi vì những lý do khác nhau, nên không nên nằm chung một file.
##
## ## ⚠️ Khoá của mọi bảng theo người chơi là CHUỖI
##
## `JSON.parse_string()` trả về Dictionary khoá CHUỖI. Master ghi `tt["mau"][5]` còn máy nhận
## đọc `tt["mau"]["5"]` thì tra không thấy và trả về null — không lỗi, không cảnh báo. Mọi chỗ
## đụng tới bảng theo người chơi đều phải đi qua `khoa()`.

const MAU_TOI_DA := 10

## Sát thương theo KHOẢNG CÁCH Ô tính từ tâm vụ nổ; chỉ số 0 là ô tâm.
## Đổi tầm nổ = sửa đúng mảng này. Thuật toán không cần biết tầm là bao nhiêu.
const BAC_BOM := {
	"bom": [4, 2],
	"bom_lon": [5, 3, 1],
}
## Giá ở ô Cửa hàng, tính bằng CHÌA KHOÁ. Cả game chỉ có MỘT loại tiền: tiêu thứ dùng để thắng
## để đổi lấy sức mạnh. Rẻ hơn nguyên một hệ thống xu, và là một quyết định khó thật sự.
const GIA := {"bom": 1, "khien": 2, "bom_lon": 3}
const TEN_DO := {"bom": "Bom", "bom_lon": "Bom lớn", "khien": "Khiên"}


## Khoá của một người trong các bảng. Luôn là CHUỖI, xem ghi chú đầu file.
static func khoa(id) -> String:
	return str(int(id))


## Trạng thái khởi đầu cho một danh sách người chơi, giữ lại giá trị cũ của ai đã có.
static func trang_thai_moi(ds: Array, cu: Dictionary) -> Dictionary:
	var moi := {"luot": 0, "thu_tu": ds.duplicate(),
			"o": {}, "mau": {}, "chia": {}, "coc": {}, "do": {},
			# Ô rương HIỆN TẠI. -1 = chưa ai mở lần nào, cứ để rương ở chỗ bản đồ vẽ sẵn.
			# Phải mang qua vòng mới, không thì hết mỗi minigame là rương nhảy về chỗ cũ.
			"o_ruong": int(cu.get("o_ruong", -1))}
	for id in ds:
		var k := khoa(id)
		moi["o"][k] = int(_bang(cu, "o").get(k, 0))
		moi["mau"][k] = int(_bang(cu, "mau").get(k, MAU_TOI_DA))
		moi["chia"][k] = int(_bang(cu, "chia").get(k, 0))
		moi["coc"][k] = int(_bang(cu, "coc").get(k, 0))
		moi["do"][k] = (_bang(cu, "do").get(k, []) as Array).duplicate()
	return moi


## Sát thương lên từng ô quanh tâm vụ nổ. Trả về `{chỉ_số_ô: sát_thương}`.
##
## Bàn là VÒNG KÍN: với bàn nhỏ, ô cách tâm k bước sang trái và sang phải có thể là CÙNG một
## ô. Lấy MAX chứ không cộng dồn — một quả bom không đánh một ô hai lần, và bậc xa không được
## xoá bậc gần.
static func o_trung_bom(tam: int, bac: Array, so_o: int) -> Dictionary:
	var ra := {}
	if so_o <= 0:
		return ra
	for k in bac.size():
		for chieu in [1, -1]:
			var o := posmod(tam + k * chieu, so_o)
			ra[o] = maxi(int(ra.get(o, 0)), int(bac[k]))
	return ra


## Trừ máu một người, có tính Khiên. Trả về `true` nếu người đó vừa chết.
##
## Khiên chặn TRỌN VẸN một đòn, kể cả đòn to hơn số máu đang có — đó là lý do người ta mua nó.
static func tru_mau(tt: Dictionary, k: String, sat: int) -> bool:
	if sat <= 0:
		return false
	var bang_do: Dictionary = _bang(tt, "do")
	var cua_no: Array = bang_do.get(k, [])
	if cua_no.has("khien"):
		cua_no.erase("khien")
		bang_do[k] = cua_no
		return false
	var bang_mau: Dictionary = _bang(tt, "mau")
	var con := int(bang_mau.get(k, MAU_TOI_DA)) - sat
	bang_mau[k] = maxi(con, 0)
	return con <= 0


## Chết: hồi đầy máu, MẤT sạch chìa chưa tiêu và mọi vật phẩm, về ô nghĩa địa.
##
## CỐC KHÔNG MẤT — mở rương rồi thì không ai lấy lại được. Không có cái trần đó thì người dẫn
## đầu bị cả phòng đập về 0 và hai mươi phút vừa chơi thành vô nghĩa.
static func chet(tt: Dictionary, k: String, o_nghia_dia: int) -> void:
	_bang(tt, "mau")[k] = MAU_TOI_DA
	_bang(tt, "chia")[k] = 0
	_bang(tt, "do")[k] = []
	if o_nghia_dia >= 0:
		_bang(tt, "o")[k] = o_nghia_dia


## Hiệu ứng của ô vừa dừng chân. Trả về chuỗi sự kiện ngắn để máy nhận kêu tiếng / bắn hạt.
##
## Trả về `"chet"` thì NGƯỜI GỌI lo hồi sinh — hồi sinh cần biết ô nghĩa địa nằm đâu, mà đó là
## việc của bàn chứ không phải của luật.
static func hieu_ung_o(tt: Dictionary, k: String, l: int, cf: Dictionary) -> String:
	match l:
		BanDuong.Loai.CHIA:
			var c: Dictionary = _bang(tt, "chia")
			c[k] = int(c.get(k, 0)) + 1
			return "+1 chìa"
		BanDuong.Loai.SAT_THUONG:
			var d := int(cf["dau_sat_thuong"])
			return "chet" if tru_mau(tt, k, d) else "-%d máu" % d
		BanDuong.Loai.NGUY_HIEM:
			var d2 := int(cf["dau_nguy_hiem"])
			return "chet" if tru_mau(tt, k, d2) else "-%d máu" % d2
		BanDuong.Loai.NGHIA_DIA:
			_bang(tt, "mau")[k] = MAU_TOI_DA
			return "hồi đầy máu"
		BanDuong.Loai.RUONG:
			return _mo_ruong(tt, k, int(cf["chia_mo_ruong"]))
		BanDuong.Loai.CUA_HANG:
			return mua(tt, k)
	return ""


static func _mo_ruong(tt: Dictionary, k: String, can: int) -> String:
	var c: Dictionary = _bang(tt, "chia")
	var co := int(c.get(k, 0))
	if co < can:
		return "thiếu chìa (%d/%d)" % [co, can]
	c[k] = co - can
	var g: Dictionary = _bang(tt, "coc")
	g[k] = int(g.get(k, 0)) + 1
	return "MỞ RƯƠNG +1 cốc"


## Cửa hàng.
##
## ponytail: TỰ MUA món đắt nhất mua nổi. Bản đủ phải mở bảng cho người chơi chọn — thêm khi
## có UI chọn đồ. Giờ chỉ cần chứng minh cơ chế "tiêu chìa đổi sức mạnh" chạy đúng.
static func mua(tt: Dictionary, k: String) -> String:
	var chia := int(_bang(tt, "chia").get(k, 0))
	var tot := ""
	for mon in GIA:
		var gia := int(GIA[mon])
		if gia <= chia and (tot == "" or gia > int(GIA[tot])):
			tot = mon
	if tot == "":
		return "không đủ chìa để mua"
	_bang(tt, "chia")[k] = chia - int(GIA[tot])
	them_do(tt, k, tot)
	return "mua %s (-%d chìa)" % [TEN_DO[tot], int(GIA[tot])]


static func them_do(tt: Dictionary, k: String, mon: String) -> void:
	var d: Array = _bang(tt, "do").get(k, [])
	d.append(mon)
	_bang(tt, "do")[k] = d


## Lấy món thứ `chi_so` ra khỏi túi. Trả về chuỗi rỗng nếu không có món đó.
static func rut_do(tt: Dictionary, k: String, chi_so: int) -> String:
	var d: Array = _bang(tt, "do").get(k, [])
	if chi_so < 0 or chi_so >= d.size():
		return ""
	var mon := str(d[chi_so])
	d.remove_at(chi_so)
	_bang(tt, "do")[k] = d
	return mon


## Ai đã đủ cốc để THẮNG cả ván. Trả về player_id, hoặc -1 khi chưa ai tới đích.
##
## Đếm cốc chứ không đếm chìa hay máu: chìa tiêu được, máu hồi được, chỉ cốc là thứ không ai
## lấy lại được (xem `chet()`). Nên chỉ nó mới làm được cái mốc kết thúc.
##
## Hoà thì người ĐỨNG TRƯỚC trong vòng lượt thắng. Hai người cùng chạm mốc trong một lượt là
## chuyện không xảy ra — mỗi lượt chỉ một người dừng chân trên rương.
static func nguoi_thang(tt: Dictionary, can: int) -> int:
	if can <= 0:
		return -1                       # 0 hoặc âm = tắt luật thắng, chơi vô hạn
	var tot := -1
	var nhieu := 0
	for id in tt.get("thu_tu", []):
		var c := int(_bang(tt, "coc").get(khoa(id), 0))
		if c >= can and c > nhieu:
			tot = int(id)
			nhieu = c
	return tot


## Người đi ngay sau `k` trong vòng lượt.
static func nguoi_ke_tiep(tt: Dictionary, k: String) -> String:
	var ds: Array = tt.get("thu_tu", [])
	for i in ds.size():
		if khoa(ds[i]) == k:
			return khoa(ds[(i + 1) % ds.size()])
	return k


static func _bang(tt: Dictionary, ten: String) -> Dictionary:
	return tt.get(ten, {}) as Dictionary
