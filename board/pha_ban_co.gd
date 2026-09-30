class_name PhaBanCo
extends Node

## Pha BÀN PARTY: tới lượt thì tung xúc xắc, đi, ăn hiệu ứng của ô dừng chân. Hết một vòng
## lượt thì sang minigame.
##
##   phòng chờ  →  BÀN PARTY (tung xúc xắc)  →  minigame  →  bàn party (thứ tự lượt mới)
##
## ## Việc của file này: MẠNG và CÂY SCENE. Luật chơi nằm ở `LuatBan`.
##
## ## Ai quyết — MASTER, và phát NGUYÊN trạng thái
##
## Đúng mẫu mục 8 của `GUIDE.md`. Người chơi chỉ XIN (tung xúc xắc, xin dùng đồ); master kiểm
## luật, cập nhật, rồi phát TOÀN BỘ trạng thái bằng một gói JSON.
##
## Vì sao không để mỗi máy tự diễn lại luật: máu, chìa, cốc, vật phẩm là trạng thái TÍCH LUỸ.
## Một gói rớt là lệch vĩnh viễn. Phát nguyên gói thì gói sau ghi đè gói trước, người vào muộn
## chỉ cần đúng một gói, và đổi master giữa ván không mất gì.
##
## Tám người ra khoảng 800 byte một gói — GUIDE đã đo `String` RPC 3000 byte tới đủ. An toàn,
## miễn là chỉ phát khi CÓ SỰ KIỆN, mỗi lượt vài gói, không phát mỗi frame.
##
## ## Bàn nằm ở đâu
##
## Trên trời, `CAO_BAN` mét phía trên phòng chờ. Phòng chờ là một cái đĩa 36 m đầy bàn ghế và
## tường va chạm; nhét bàn party vào đó là phải đi dọn chỗ. Đặt lên cao thì hai nơi không bao
## giờ đụng nhau, và đi lại giữa chúng chỉ là một phép gán toạ độ.

signal het_vong(thu_tu_cu: Array)
## Trạng thái vừa đổi. HUD nghe tín hiệu này, không đọc thẳng vào đây.
signal trang_thai_doi(tt: Dictionary)
## Nhắc riêng cho HUD cục bộ trong lúc người chơi chọn lộ trình sau khi tung xúc xắc.
signal chon_huong_doi(noi_dung: String)
## Có người đủ cốc — HẾT VÁN. Phát trên MỌI máy, vì gói trạng thái tới máy nào cũng mang cờ
## `thang`. Người điều phối (`main.gd`) lo phần đóng bàn và trả cả phòng về phòng chờ.
signal van_thang(id: int, coc: int)

const CAO_BAN := 100.0
## Đi một ô mất bao lâu, giây.
const GIAY_MOI_O := 0.22
## Nghỉ sau khi một người đi xong, trước khi tới lượt kế.
const NGHI_GIUA_LUOT := 0.8
## Gốc Player nằm ngay dưới chân. Mặt cao nhất của ô (vành Torus) ở khoảng +0.31 m so với
## gốc OBan, nên đặt chân ở +0.32 m; giá trị 0.9 cũ làm nhân vật lơ lửng hơn nửa mét.
const CAO_DUNG := 0.32
## Nhiều người cùng một ô thì đứng cách tâm ô chừng này. Ô rộng 1.4 m nên 0.45 là vừa trong mép.
const BAN_KINH_DUNG := 0.45
const XUC_XAC_SCENE: PackedScene = preload("res://board/xuc_xac_3d.tscn")

## Bàn party là một SCENE RIÊNG, nạp vào khi cần. Đổi bản đồ = trỏ export này sang scene khác.
@export var ban_scene: PackedScene = preload("res://board/ban_party.tscn")

## Chìa cần để mở một rương lấy một cốc.
## @export vì con số này quyết định ván dài 10 phút hay 40 phút — chỉ biết sau khi chơi thử.
@export var chia_mo_ruong := 3
@export var dau_sat_thuong := 2
@export var dau_nguy_hiem := 4

## Bao nhiêu cốc thì thắng cả ván. Đặt 0 để chơi vô hạn (bàn không bao giờ tự đóng).
##
## Con số này quyết định ván dài bao lâu, y như `chia_mo_ruong`: mỗi cốc tốn `chia_mo_ruong`
## chìa, mà chìa thì nhặt từng cái một. 3 cốc × 3 chìa = 9 ô Chìa phải dừng đúng, chưa kể
## chết là mất sạch chìa chưa tiêu. Chỉ chơi thử mới biết đặt mấy là vừa.
@export var coc_de_thang := 3

## Toàn bộ trạng thái bàn. Master giữ bản gốc, máy khác nhận nguyên gói.
var tt: Dictionary = {}
var ban: BanDuong = null
## Tạm ngưng nhận phím và ngưng chốt lượt. Người điều phối (`main.gd`) bật cờ này khi có lớp
## khác đang phủ lên trên — bàn không cần biết lớp đó là cái gì, chỉ cần biết mình đang bị che.
var tam_dung := false
var _dang_di := false
var _dang_chon := false
var _dice_ready := false
var _id_dang_tung := -1
var _so_dang_tung := 0
var _cac_duong: Array[PackedInt32Array] = []
var _lua_chon := 0
## Xúc xắc là vật thể trình diễn cục bộ, gắn vào camera hiện hành. Kết quả vẫn tới từ cùng
## RPC `_net_tung`, vì vậy mọi máy hiển thị đúng một con số và không thêm trạng thái mạng.
var _xuc_xac: Node3D = null
## Hạt giống riêng của master cho ô Bí ẩn. KHÔNG replicate: chỉ master gieo, và kết quả đi
## trong gói trạng thái nên mọi máy vẫn thấy y hệt.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	Fusion.register_broadcast_receiver(self)
	_rng.randomize()
	get_tree().node_removed.connect(_khi_mat_nguoi)


func dang_chay() -> bool:
	return int(tt.get("luot", -1)) >= 0 and not _thu_tu().is_empty()


# ───────────────────────────── mở / đóng bàn ─────────────────────────────

## Mở bàn. CHỈ master — hàm này tự phát RPC cho cả phòng, mười máy cùng gọi là mười lệnh mở.
## `thu_tu_moi` rỗng = lần đầu, lấy id tăng dần.
func xin_mo(thu_tu_moi: Array) -> void:
	if dang_chay() or not NetManager.is_master():
		return
	var ds: Array = thu_tu_moi.duplicate()
	if ds.is_empty():
		for p: Player in get_tree().get_nodes_in_group("players"):
			ds.append(p.player_id())
		ds.sort()
	if ds.is_empty():
		return
	_phat(LuatBan.trang_thai_moi(ds, tt), "vào bàn")


## Thứ tự lượt vòng sau = bảng xếp hạng minigame. CHỈ master.
##
## ⚠️ Phải kiểm `dang_chay()`: minigame có thể chạy từ PHÒNG CHỜ chứ không chỉ từ bàn. Thiếu
## dòng đó thì hết ván minigame là bàn party tự mở ra từ hư không và nhấc cả phòng lên trời —
## đã đo được: người chơi kết thúc ở y = 100.9 m (`CAO_BAN + CAO_DUNG`) thay vì về phòng chờ.
func xin_thu_tu_moi(xep_hang: Array) -> void:
	if not NetManager.is_master() or xep_hang.is_empty() or not dang_chay():
		return
	_phat(LuatBan.trang_thai_moi(xep_hang, tt), "vòng mới")


## Đóng bàn, xoá sạch trạng thái. Chạy trên MỌI máy khi hết ván.
##
## Phải xoá HẲN `tt` chứ không chỉ đặt `luot = -1`: `LuatBan.trang_thai_moi()` giữ lại giá trị
## cũ của ai đã có, nên còn giữ `tt` là ván sau mở ra ai cũng đã sẵn 3 cốc và thắng ngay lập
## tức. Ván mới là ván mới.
func dong() -> void:
	tt = {}
	_dang_di = false
	_dang_chon = false
	_dice_ready = false
	_id_dang_tung = -1
	_so_dang_tung = 0
	_cac_duong.clear()
	chon_huong_doi.emit("")
	tam_dung = false                    # đóng rồi thì không còn lớp nào che nữa
	_che_do_ban_co(false)
	if ban != null and is_instance_valid(ban):
		ban.queue_free()
	ban = null
	if _xuc_xac != null and is_instance_valid(_xuc_xac):
		_xuc_xac.queue_free()
	_xuc_xac = null
	trang_thai_doi.emit(tt)


# ───────────────────────────── mạng ─────────────────────────────

## CHỈ master gọi. Gói đi tới mọi máy KỂ CẢ master (`call_local`) — một đường xử lý duy nhất,
## không phải viết hai nhánh.
func _phat(moi: Dictionary, su_kien: String) -> void:
	moi["su_kien"] = su_kien
	# Mốc thắng đi kèm gói: bảng bên phải hiện "cốc 1/3" chứ không phải "cốc 1", và người vào
	# muộn cũng biết ngay còn bao xa. Master là nơi duy nhất giữ con số này.
	moi["can_coc"] = coc_de_thang
	Fusion.rpc(_net_trang_thai, JSON.stringify(moi))


@rpc("any_peer", "call_local")
func _net_trang_thai(json: String) -> void:
	var g = JSON.parse_string(json)
	if not (g is Dictionary):
		return
	tt = g
	if not dang_chay():
		return
	_bao_dam_co_ban()
	_ap_ruong()
	# Đang chạy animation đi thì đừng giật người về — gói này là bản chốt, animation sẽ tới
	# đúng đó trong chớp mắt nữa.
	if not _dang_di:
		for id in _thu_tu():
			_dat_len_o(int(id), int(_bang("o").get(LuatBan.khoa(id), 0)))
	_che_do_ban_co(true)
	trang_thai_doi.emit(tt)
	if tt.has("thang"):
		var id := int(tt["thang"])
		van_thang.emit(id, int(_bang("coc").get(LuatBan.khoa(id), 0)))
		return                          # hết ván thì không còn vòng nào để chốt
	if str(tt.get("su_kien", "")) == "het_vong":
		het_vong.emit(_thu_tu())


## Người tới lượt bấm phím: tự gieo số rồi phát cho cả phòng để mọi máy diễn lại cùng một
## đoạn đi. Master áp luật ở cuối, xem `_ket_luot`.
func _unhandled_input(event: InputEvent) -> void:
	if _dang_chon and _id_dang_tung == NetManager.local_id():
		if event.is_action_pressed("move_left"):
			get_viewport().set_input_as_handled()
			_lua_chon = posmod(_lua_chon - 1, _cac_duong.size())
			_cap_nhat_lua_chon()
			return
		if event.is_action_pressed("move_right"):
			get_viewport().set_input_as_handled()
			_lua_chon = posmod(_lua_chon + 1, _cac_duong.size())
			_cap_nhat_lua_chon()
			return
		if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_dang_chon = false
			chon_huong_doi.emit("Đã chọn — đang chờ xác nhận từ chủ phòng...")
			Fusion.rpc(_net_xin_chon_duong, NetManager.local_id(), _lua_chon)
			return
	if not _den_luot_minh():
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		Fusion.rpc(_net_tung, NetManager.local_id(), randi() % 6 + 1)
		return
	# Dùng đồ: phím 1..9 theo thứ tự đồ đang có. Đọc thẳng keycode chứ không thêm action vào
	# `project.godot` cho mấy phím demo.
	if event is InputEventKey and event.pressed and not event.echo:
		var so := (event as InputEventKey).keycode - KEY_1
		if so >= 0 and so < 9:
			get_viewport().set_input_as_handled()
			Fusion.rpc(_net_xin_dung, NetManager.local_id(), so)


func _den_luot_minh() -> bool:
	if not dang_chay() or _dang_di or tam_dung:
		return false
	return int(_thu_tu()[int(tt["luot"])]) == NetManager.local_id()


@rpc("any_peer", "call_local")
func _net_tung(id: int, so: int) -> void:
	if not dang_chay() or _dang_di or tam_dung:
		return
	if int(_thu_tu()[int(tt["luot"])]) != id:
		return
	_dang_di = true
	_dice_ready = false
	_id_dang_tung = id
	_so_dang_tung = clampi(so, 1, 6)
	await _hien_xuc_xac(id, so)
	_dice_ready = true
	_bat_dau_chon_duong(id, _so_dang_tung)


func _bat_dau_chon_duong(id: int, so: int) -> void:
	var k := LuatBan.khoa(id)
	var bat_dau := int(_bang("o").get(k, 0))
	_cac_duong = ban.cac_duong(bat_dau, so)
	_lua_chon = 0
	if _cac_duong.is_empty():
		push_error("BanDuong: khong co lo trinh %d buoc tu o %d" % [so, bat_dau])
		_dang_di = false
		return
	if _cac_duong.size() == 1:
		if NetManager.is_master():
			_phat_duong_di(id, _cac_duong[0])
		return
	_dang_chon = true
	if id == NetManager.local_id():
		_cap_nhat_lua_chon()
	else:
		chon_huong_doi.emit("%s đang chọn hướng đi..." % Player.ten_theo_id(get_tree(), id))


func _cap_nhat_lua_chon() -> void:
	if ban == null or _cac_duong.is_empty():
		return
	ban.noi_bat_duong(_cac_duong, _lua_chon)
	var d := _cac_duong[_lua_chon]
	chon_huong_doi.emit("CHỌN LỘ TRÌNH  %d/%d  → ô %d    [A/D] đổi    [SPACE/E] xác nhận" % [
			_lua_chon + 1, _cac_duong.size(), int(d[d.size() - 1])])


@rpc("any_peer", "call_local")
func _net_xin_chon_duong(id: int, chi_so: int) -> void:
	if not NetManager.is_master() or not dang_chay() or not _dang_di:
		return
	if id != _id_dang_tung or int(_thu_tu()[int(tt["luot"])]) != id:
		return
	var bat_dau := int(_bang("o").get(LuatBan.khoa(id), 0))
	var hop_le := ban.cac_duong(bat_dau, _so_dang_tung)
	if chi_so < 0 or chi_so >= hop_le.size():
		return
	_phat_duong_di(id, hop_le[chi_so])


func _phat_duong_di(id: int, duong: PackedInt32Array) -> void:
	Fusion.rpc(_net_di_theo_duong, id, JSON.stringify(Array(duong)))


@rpc("any_peer", "call_local")
func _net_di_theo_duong(id: int, json_duong: String) -> void:
	if not dang_chay() or id != _id_dang_tung:
		return
	var raw = JSON.parse_string(json_duong)
	if not (raw is Array):
		return
	var duong := PackedInt32Array()
	for o in raw:
		duong.append(int(o))
	var bat_dau := int(_bang("o").get(LuatBan.khoa(id), 0))
	if not ban.duong_hop_le(bat_dau, duong, _so_dang_tung):
		return
	while not _dice_ready:
		await get_tree().process_frame
	_dang_chon = false
	chon_huong_doi.emit("")
	ban.xoa_noi_bat()
	await _di_theo_duong(id, duong)
	_dang_di = false
	_id_dang_tung = -1
	_so_dang_tung = 0
	_cac_duong.clear()
	if NetManager.is_master():
		await get_tree().create_timer(NGHI_GIUA_LUOT).timeout
		_ket_luot(id)


## Hiển thị cùng một xúc xắc 3D trước camera từng máy. Nó nảy, xoay rồi dừng đúng mặt
## `so`; chỉ sau khi người chơi đọc được kết quả quân cờ mới bắt đầu đi.
func _hien_xuc_xac(id: int, so: int) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		await get_tree().create_timer(0.6).timeout
		return
	if _xuc_xac == null or not is_instance_valid(_xuc_xac):
		_xuc_xac = XUC_XAC_SCENE.instantiate() as Node3D
		camera.add_child(_xuc_xac)
	elif _xuc_xac.get_parent() != camera:
		_xuc_xac.reparent(camera, false)
	await _xuc_xac.tung(clampi(so, 1, 6), Player.ten_theo_id(get_tree(), id))


## Xin dùng món thứ `chi_so` trong túi. Master là người duy nhất kiểm và áp, nên hai người
## cùng bấm trong một frame cũng không thể ra hai kết quả.
@rpc("any_peer", "call_local")
func _net_xin_dung(id: int, chi_so: int) -> void:
	if not NetManager.is_master() or not dang_chay() or _dang_di or tam_dung:
		return
	if int(_thu_tu()[int(tt["luot"])]) != id:
		return
	var k := LuatBan.khoa(id)
	var mon := LuatBan.rut_do(tt, k, chi_so)
	if mon == "":
		return
	_phat(tt, _dung_do(k, mon))


# ───────────────────────────── luật cần tới bàn ─────────────────────────────

## CHỈ master. Áp hiệu ứng ô vừa dừng chân, sang lượt kế, rồi phát nguyên trạng thái.
func _ket_luot(id: int) -> void:
	var k := LuatBan.khoa(id)
	var o_dung := int(_bang("o").get(k, 0))
	var l := ban.loai(o_dung)
	var coc_truoc := int(_bang("coc").get(k, 0))
	var su := _the_bi_an(k) if l == BanDuong.Loai.BI_AN else LuatBan.hieu_ung_o(tt, k, l, {
		"dau_sat_thuong": dau_sat_thuong,
		"dau_nguy_hiem": dau_nguy_hiem,
		"chia_mo_ruong": chia_mo_ruong,
	})
	# Mở được rương thì rương DỜI ĐI CHỖ KHÁC. So số cốc trước/sau chứ không dò chuỗi sự
	# kiện: "thiếu chìa" cũng là dừng chân trên rương nhưng không mở được, và chuỗi kia là
	# câu cho người đọc, đổi chữ lúc nào cũng được.
	if int(_bang("coc").get(k, 0)) > coc_truoc:
		_doi_cho_ruong()
	if su == "chet":
		_hoi_sinh(k)
		su = "CHẾT — mất hết chìa và đồ"

	# Kiểm mốc thắng NGAY sau hiệu ứng ô, trước khi sang lượt kế: mở rương xong là thắng
	# ngay, không phải chờ hết vòng rồi mới biết.
	var thang := LuatBan.nguoi_thang(tt, coc_de_thang)
	if thang >= 0:
		tt["thang"] = thang
		_phat(tt, "%s THẮNG — đủ %d cốc" % [Player.ten_theo_id(get_tree(), thang),
				coc_de_thang])
		return

	var luot := int(tt["luot"]) + 1
	if luot >= _thu_tu().size():
		tt["luot"] = 0
		_phat(tt, "het_vong")
		return
	tt["luot"] = luot
	_phat(tt, "" if su == "" else "%s: %s" % [Player.ten_theo_id(get_tree(), id), su])


## Mục tiêu của bom là ô của NGƯỜI KẾ TIẾP trong thứ tự lượt.
##
## ponytail: tự nhắm để khỏi phải dựng UI chọn mục tiêu. Bản đủ cho người chơi chỉ vào một ô
## bất kỳ — luật nổ trong `LuatBan` không đổi một dòng khi thêm UI.
func _dung_do(k: String, mon: String) -> String:
	if not LuatBan.BAC_BOM.has(mon):
		# Khiên nằm im trong túi, `tru_mau` tự tiêu nó khi ăn đòn. Bấm nhầm thì trả lại.
		LuatBan.them_do(tt, k, mon)
		return "%s để dành, không bấm ra được" % LuatBan.TEN_DO.get(mon, mon)

	var tam := int(_bang("o").get(LuatBan.nguoi_ke_tiep(tt, k), 0))
	var trung := ban.o_trung_bom(tam, LuatBan.BAC_BOM[mon] as Array)
	var dinh := PackedStringArray()
	for nguoi in _bang("o").keys():
		var kk := str(nguoi)
		var o := int(_bang("o")[kk])
		if not trung.has(o):
			continue
		var sat := int(trung[o])
		var da_chet := LuatBan.tru_mau(tt, kk, sat)
		dinh.append("%s -%d%s" % [Player.ten_theo_id(get_tree(), int(kk)), sat,
				" CHẾT" if da_chet else ""])
		if da_chet:
			_hoi_sinh(kk)
	return "%s nổ ở ô %d — %s" % [LuatBan.TEN_DO[mon], tam,
			", ".join(dinh) if dinh.size() > 0 else "không trúng ai"]


func _hoi_sinh(k: String) -> void:
	var nd := ban.gan_nhat_loai(int(_bang("o").get(k, 0)), BanDuong.Loai.NGHIA_DIA)
	if nd < 0:
		push_error("BanDuong: ban do khong co o NGHIA_DIA, khong biet hoi sinh o dau")
	LuatBan.chet(tt, k, nd)


## Ô Bí ẩn: MASTER rút thẻ. Đây là chỗ DUY NHẤT trên bàn có ngẫu nhiên không suy ra được từ
## nước đi, nên kết quả phải đi trong gói trạng thái chứ không để mỗi máy tự gieo.
func _the_bi_an(k: String) -> String:
	var chia: Dictionary = _bang("chia")
	match _rng.randi() % 4:
		0:
			chia[k] = int(chia.get(k, 0)) + 2
			return "thẻ Bí ẩn: +2 chìa"
		1:
			chia[k] = maxi(int(chia.get(k, 0)) - 1, 0)
			return "thẻ Bí ẩn: -1 chìa"
		2:
			LuatBan.them_do(tt, k, "bom")
			return "thẻ Bí ẩn: +1 Bom"
		_:
			_bang("mau")[k] = LuatBan.MAU_TOI_DA
			return "thẻ Bí ẩn: hồi đầy máu"


## Có người rời phòng GIỮA VÁN. Fusion xoá object player của họ trên mọi máy, nhưng vòng lượt
## thì không tự biết — tới lượt một id không còn ai ngồi sau là **cả bàn đứng im vĩnh viễn**,
## vì lượt chỉ sang khi có người bấm phím tung xúc xắc.
##
## CHỈ master sửa vòng lượt rồi phát lại, y như mọi thay đổi khác.
func _khi_mat_nguoi(n: Node) -> void:
	var p := n as Player
	if p == null or not dang_chay() or not NetManager.is_master():
		return
	_bo_khoi_vong(p.player_id())


## Gỡ một người khỏi vòng lượt và chỉnh lại con trỏ lượt.
##
## Hai trường hợp phải phân biệt, và cả hai đều sai nếu chỉ `erase` rồi thôi:
##
##   - Người rời đứng TRƯỚC người đang tới lượt → mọi người sau đó tụt một bậc, con trỏ phải
##     tụt theo, không thì nhảy cóc qua một người.
##   - Người rời CHÍNH LÀ người đang tới lượt → giữ nguyên chỉ số là trúng người kế tiếp.
##     `posmod` lo nốt trường hợp họ đứng cuối vòng.
func _bo_khoi_vong(id: int) -> void:
	var ds := _thu_tu().duplicate()
	var i := -1
	for j in ds.size():
		if int(ds[j]) == id:            # JSON trả số về float, phải ép kiểu mới so được
			i = j
			break
	if i < 0:
		return
	ds.remove_at(i)
	if ds.is_empty():
		dong()
		return
	var luot := int(tt["luot"])
	tt["thu_tu"] = ds
	tt["luot"] = posmod(luot - 1 if i < luot else luot, ds.size())
	_dang_di = false                    # họ có thể đang giữa đoạn đi; không gỡ cờ là bàn khoá
	_phat(tt, "%s rời phòng" % Player.ten_theo_id(get_tree(), id))


## Rương DI CHUYỂN: mở xong là nó dời sang một ô Trống khác.
##
## Bản đồ chỉ có MỘT ô Rương. Để yên một chỗ thì cả ván là đi vòng vòng về đúng ô đó, và ai
## đang đứng gần nó lúc gom đủ chìa thì thắng — thắng bằng chỗ ngồi chứ không phải bằng cách
## chơi. Rương chạy thì mỗi lần mở, cả bàn phải tính lại đường.
##
## CHỈ master gọi, và ô mới đi trong gói trạng thái — không máy nào tự gieo số.
func _doi_cho_ruong() -> void:
	var trong := ban.cac_o_loai(BanDuong.Loai.TRONG)
	if trong.is_empty():
		return                          # bàn không còn ô Trống nào: để rương nguyên chỗ
	tt["o_ruong"] = int(trong[_rng.randi() % trong.size()])


## Dựng mặt bàn cho khớp gói: đúng MỘT ô là Rương, ô rương cũ trả về Trống.
##
## Chạy trên MỌI máy ở MỌI gói, nên người vào giữa ván cũng thấy đúng chỗ rương đang nằm —
## không có trạng thái riêng nào để lệch.
func _ap_ruong() -> void:
	var moi := int(tt.get("o_ruong", -1))
	if moi < 0 or ban == null:
		return                          # chưa ai mở lần nào: giữ đúng chỗ bản đồ vẽ sẵn
	for i in ban.so_luong():
		if i == moi:
			ban.dat_loai(i, BanDuong.Loai.RUONG)
		elif ban.loai(i) == BanDuong.Loai.RUONG:
			ban.dat_loai(i, BanDuong.Loai.TRONG)


# ───────────────────────────── cây scene ─────────────────────────────

func _bao_dam_co_ban() -> void:
	if ban != null and is_instance_valid(ban):
		return
	ban = ban_scene.instantiate() as BanDuong
	ban.position.y = CAO_BAN
	get_tree().current_scene.add_child(ban)


## Đi từng ô một để nhìn thấy được, không nhảy thẳng tới đích.
func _di_theo_duong(id: int, duong: PackedInt32Array) -> void:
	var k := LuatBan.khoa(id)
	var p := _nguoi(id)
	for i in range(1, duong.size()):
		_bang("o")[k] = int(duong[i])
		if p != null:
			var tw := create_tween()
			tw.tween_property(p, "global_position", _cho_dung(id, int(_bang("o")[k])),
					GIAY_MOI_O)
			await tw.finished
		else:
			await get_tree().create_timer(GIAY_MOI_O).timeout


func _dat_len_o(id: int, o: int) -> void:
	var p := _nguoi(id)
	if p != null:
		p.global_position = _cho_dung(id, o)


## Chỗ đứng của một người trên ô.
##
## Sáu người cùng xuất phát ở ô 0, nên đặt ai cũng vào đúng tâm ô là được một cục thịt không
## ai nhận ra ai — đã thấy tận mắt ở lần chạy thử đầu tiên. Rải đều quanh tâm theo THỨ TỰ LƯỢT
## thì chỗ đứng ổn định, mọi máy tính ra y hệt, và không tốn một byte mạng nào.
func _cho_dung(id: int, o: int) -> Vector3:
	var goc := ban.vi_tri(o) + Vector3.UP * CAO_DUNG
	var ds := _thu_tu()
	if ds.size() <= 1:
		return goc
	# JSON trả số về dạng float, nên so sánh phải ép kiểu — `ds.find(id)` với id là int thì
	# không bao giờ khớp.
	for i in ds.size():
		if int(ds[i]) == id:
			var a := TAU * i / float(ds.size())
			return goc + Vector3(cos(a), 0.0, sin(a)) * BAN_KINH_DUNG
	return goc


func _nguoi(id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == id:
			return p
	return null


func _thu_tu() -> Array:
	return tt.get("thu_tu", []) as Array


func _bang(ten: String) -> Dictionary:
	return tt.get(ten, {}) as Dictionary


## Bật/tắt CHẾ ĐỘ QUÂN CỜ cho người chơi của máy này: khoá WASD (đi lại do xúc xắc quyết,
## không do phím) và kéo camera ra góc nhìn bàn.
##
## Chỉ đụng tới `is_mine`. Camera của người khác không tồn tại trên máy này (`CameraRig` bị
## `queue_free()` ở máy không sở hữu), mà khoá phím hộ họ cũng chẳng để làm gì.
func _che_do_ban_co(bat: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not p.is_mine:
			continue
		p.khoa_di_chuyen = bat
		if p.rig != null and is_instance_valid(p.rig):
			p.rig.set_ban_co(bat)
