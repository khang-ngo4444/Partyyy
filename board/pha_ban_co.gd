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
## Có người mở đúng rương — HẾT VÁN. Phát trên MỌI máy, vì gói trạng thái mang cờ
## `thang`. Người điều phối (`main.gd`) lo phần đóng bàn và trả cả phòng về phòng chờ.
signal van_thang(id: int)

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
## Tầm tính từ người bắn tới mục tiêu. Tia ngắm bắt đầu ở camera để khớp đúng tâm màn hình.
const TAM_SUNG := 35.0
const XUC_XAC_SCENE: PackedScene = preload("res://board/xuc_xac_3d.tscn")

## Bàn party là một SCENE RIÊNG, nạp vào khi cần. Đổi bản đồ = trỏ export này sang scene khác.
@export var ban_scene: PackedScene = preload("res://board/ban_party.tscn")

## Chủ phòng khóa cấu hình này trước khi mọi người vào sảnh.
var settings: Dictionary = GameplaySettings.defaults()

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
var _thue_token := 0
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


func dat_cai_dat(value: Dictionary) -> void:
	settings = GameplaySettings.sanitize(value)


# ───────────────────────────── mở / đóng bàn ─────────────────────────────

## Mở bàn. CHỈ master — hàm này tự phát RPC cho cả phòng, mười máy cùng gọi là mười lệnh mở.
## `thu_tu_moi` rỗng = lần đầu, gom người chơi rồi trộn thứ tự.
func xin_mo(thu_tu_moi: Array) -> void:
	if dang_chay() or not NetManager.is_master():
		return
	var ds: Array = thu_tu_moi.duplicate()
	if ds.is_empty():
		for p: Player in get_tree().get_nodes_in_group("players"):
			ds.append(p.player_id())
		ds.sort()
		_tron(ds)
	if ds.is_empty():
		return
	_bao_dam_co_ban()
	var moi := LuatBan.trang_thai_moi(ds, {}, settings)
	_tao_mat_ban(moi)
	_phat(moi, "Bắt đầu — thứ tự lượt đã được chọn ngẫu nhiên")


## Thứ tự lượt vòng sau = bảng xếp hạng minigame. CHỈ master.
##
## ⚠️ Phải kiểm `dang_chay()`: minigame có thể chạy từ PHÒNG CHỜ chứ không chỉ từ bàn. Thiếu
## dòng đó thì hết ván minigame là bàn party tự mở ra từ hư không và nhấc cả phòng lên trời —
## đã đo được: người chơi kết thúc ở y = 100.9 m (`CAO_BAN + CAO_DUNG`) thay vì về phòng chờ.
func xin_thu_tu_moi(xep_hang: Array) -> void:
	if not NetManager.is_master() or xep_hang.is_empty() or not dang_chay():
		return
	var thuong := LuatBan.thuong_minigame(tt, xep_hang, settings)
	_phat(LuatBan.trang_thai_moi(xep_hang, tt, settings), "Vòng mới · %s" % thuong)


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
	moi["max_health"] = int(settings.get("max_health", 10))
	moi["chest_cost"] = int(settings.get("chest_cost", 100))
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
	_ap_mat_ban()
	# Minigame đang phủ lên (`tam_dung`): chỉ nhận số liệu, KHÔNG kéo người về ô và KHÔNG khoá
	# WASD. Có người rời phòng giữa minigame là master phát lại bàn (`_bo_khoi_vong`) — trước
	# đây gói đó khoá cứng mọi nhân vật và nhấc họ từ sân về bàn. Hết minigame thì
	# `xin_thu_tu_moi` phát gói mới, lúc đó mới đặt lại.
	# Đang chạy animation đi thì đừng giật người về — gói này là bản chốt, animation sẽ tới
	# đúng đó trong chớp mắt nữa.
	if not tam_dung:
		if not _dang_di:
			for id in _thu_tu():
				_dat_len_o(int(id), int(_bang("o").get(LuatBan.khoa(id), 0)))
		_che_do_ban_co(true)
	trang_thai_doi.emit(tt)
	if tt.has("thang"):
		var id := int(tt["thang"])
		van_thang.emit(id)
		return                          # hết ván thì không còn vòng nào để chốt
	if str(tt.get("su_kien", "")) == "het_vong":
		het_vong.emit(_thu_tu())


## Súng phải đọc ở `_input`: tâm ngắm là các Control nằm đúng giữa màn hình, nên chuột trái
## có thể bị GUI đánh dấu đã xử lý trước khi tới `_unhandled_input`. Chỉ nhận lúc chuột đang
## bị khoá vào game để không bắn xuyên qua menu Esc / menu thuế.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
			and _co_the_ban_sung(NetManager.local_id()):
		get_viewport().set_input_as_handled()
		_xin_ban_sung()


## Người tới lượt bấm phím: tự gieo số rồi phát cho cả phòng để mọi máy diễn lại cùng một
## đoạn đi. Master áp luật ở cuối, xem `_ket_luot`.
func _unhandled_input(event: InputEvent) -> void:
	var thue: Dictionary = tt.get("thue", {}) as Dictionary
	if not thue.is_empty() and int(thue.get("chu", -1)) == NetManager.local_id():
		if event is InputEventKey and event.pressed and not event.echo:
			var lua_chon_thue := int((event as InputEventKey).keycode) - KEY_1
			if lua_chon_thue >= 0 and lua_chon_thue < 4:
				get_viewport().set_input_as_handled()
				Fusion.rpc(_net_xin_thu_thue, NetManager.local_id(), lua_chon_thue)
		return
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


func _den_luot_minh() -> bool:
	if not dang_chay() or _dang_di or tam_dung or not (tt.get("thue", {}) as Dictionary).is_empty():
		return false
	return int(_thu_tu()[int(tt["luot"])]) == NetManager.local_id()


func _co_the_ban_sung(id: int) -> bool:
	if not dang_chay() or tam_dung or _dang_di or _dang_chon or tt.has("thang"):
		return false
	if not (tt.get("thue", {}) as Dictionary).is_empty():
		return false
	return _co_sung_trong_tui(id)


func _co_sung_trong_tui(id: int) -> bool:
	return (_bang("do").get(LuatBan.khoa(id), []) as Array).has("sung_1_phat")


func _xin_ban_sung() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var goc := camera.global_position
	var huong := -camera.global_transform.basis.z.normalized()
	var du_lieu := JSON.stringify({
		"goc": [goc.x, goc.y, goc.z],
		"huong": [huong.x, huong.y, huong.z],
	})
	Fusion.rpc(_net_xin_ban_sung, NetManager.local_id(), du_lieu)


@rpc("any_peer", "call_local")
func _net_xin_ban_sung(id: int, json_du_lieu: String) -> void:
	if not NetManager.is_master() or not _co_the_ban_sung(id):
		return
	var raw = JSON.parse_string(json_du_lieu)
	if not (raw is Dictionary):
		return
	var goc_raw: Array = raw.get("goc", []) as Array
	var huong_raw: Array = raw.get("huong", []) as Array
	if goc_raw.size() != 3 or huong_raw.size() != 3:
		return
	var goc := Vector3(float(goc_raw[0]), float(goc_raw[1]), float(goc_raw[2]))
	var huong := Vector3(float(huong_raw[0]), float(huong_raw[1]), float(huong_raw[2]))
	var nguoi_ban := _nguoi(id)
	if nguoi_ban == null or not goc.is_finite() or not huong.is_finite():
		return
	if goc.distance_to(nguoi_ban.global_position) > 22.0 or huong.length_squared() < 0.9:
		return
	huong = huong.normalized()
	# Không so hướng này với `nhin_doc` replicate: ngay sau minigame, camera cục bộ đã trở về
	# bàn nhưng góc nhìn trên máy master có thể còn chậm một gói mạng. Vị trí bắt đầu vẫn bị
	# giới hạn quanh người bắn; master vẫn tự raycast, kiểm tầm và trừ đúng một khẩu trong túi.
	var muc_tieu := _muc_tieu_sung(nguoi_ban, goc, huong)
	var k_muc_tieu := "" if muc_tieu == null else LuatBan.khoa(muc_tieu.player_id())
	var ket_qua := LuatBan.ban_sung(tt, LuatBan.khoa(id), k_muc_tieu,
			int(settings.get("weapon_damage", 3)))
	if not bool(ket_qua.get("da_ban", false)):
		return
	var su_kien := str(ket_qua.get("su_kien", ""))
	if muc_tieu != null:
		su_kien += " %s" % Player.ten_theo_id(get_tree(), muc_tieu.player_id())
		if bool(ket_qua.get("chet", false)):
			LuatBan.chet(tt, k_muc_tieu, settings)
			su_kien += " · hồi sinh"
	_phat(tt, "%s: %s" % [Player.ten_theo_id(get_tree(), id), su_kien])


func _muc_tieu_sung(nguoi_ban: Player, goc: Vector3, huong: Vector3) -> Player:
	var q := PhysicsRayQueryParameters3D.create(goc, goc + huong * 60.0,
			Pickable.LOP_THE_GIOI | Player.LOP_NGUOI)
	q.exclude = [nguoi_ban.get_rid()]
	var trung := nguoi_ban.get_world_3d().direct_space_state.intersect_ray(q)
	if trung.is_empty():
		return null
	var muc_tieu := trung.get("collider") as Player
	if muc_tieu == null or muc_tieu.player_id() == nguoi_ban.player_id():
		return null
	if muc_tieu.global_position.distance_to(nguoi_ban.global_position) > TAM_SUNG:
		return null
	return muc_tieu


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
	var so_da_tung := _so_dang_tung
	_dang_di = false
	_id_dang_tung = -1
	_so_dang_tung = 0
	_cac_duong.clear()
	if NetManager.is_master():
		await get_tree().create_timer(NGHI_GIUA_LUOT).timeout
		_ket_luot(id, so_da_tung)


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


# ───────────────────────────── luật cần tới bàn ─────────────────────────────

## CHỈ master. Áp hiệu ứng ô vừa dừng chân, sang lượt kế, rồi phát nguyên trạng thái.
func _ket_luot(id: int, so_buoc: int) -> void:
	var k := LuatBan.khoa(id)
	var o_dung := int(_bang("o").get(k, 0))
	var truoc := int(_bang("buoc").get(k, 0))
	_bang("buoc")[k] = truoc + so_buoc
	var checkpoint := _mo_checkpoint_neu_du(id, truoc, int(_bang("buoc")[k]), o_dung)

	if (tt.get("ruong", []) as Array).has(o_dung):
		var ket_qua_ruong := _mo_ruong(k, o_dung)
		if tt.has("thang"):
			_phat(tt, ket_qua_ruong)
			return
		_sang_luot(id, _noi_su_kien(ket_qua_ruong, checkpoint))
		return

	var l := _loai_o(o_dung)
	if l == BanDuong.Loai.DAT:
		var dat: Dictionary = _bang("chu_dat")
		var ok := str(o_dung)
		if not dat.has(ok):
			dat[ok] = id
			_bat_dau_chon_thue_dat(id, o_dung, checkpoint)
			return
		var chu := int(dat[ok])
		if chu != id:
			var loai_thue := int(_bang("thue_dat").get(ok, LuatBan.Thue.TIEN))
			var su_thue := LuatBan.thu_thue(tt, LuatBan.khoa(chu), k, loai_thue, settings)
			if int(_bang("mau").get(k, 1)) <= 0:
				LuatBan.chet(tt, k, settings)
				su_thue += " · hồi sinh"
			_sang_luot(id, _noi_su_kien(su_thue, checkpoint))
			return
		_sang_luot(id, _noi_su_kien("về đất của mình", checkpoint))
		return

	var su := LuatBan.hieu_ung_o(tt, k, l, settings)
	if l == BanDuong.Loai.TRANG_BI:
		var mon := "khien" if _rng.randi() % 3 == 0 else "sung_1_phat"
		LuatBan.them_do(tt, k, mon)
		su = ("+Khiên · tự động chặn một đòn" if mon == "khien"
				else "+Súng một phát · chuột trái để bắn")
	_sang_luot(id, _noi_su_kien(su, checkpoint))


func _sang_luot(id: int, su: String) -> void:
	var luot := int(tt["luot"]) + 1
	if luot >= _thu_tu().size():
		tt["luot"] = 0
		_phat(tt, "het_vong")
		return
	tt["luot"] = luot
	_phat(tt, "" if su.is_empty() else "%s: %s" % [Player.ten_theo_id(get_tree(), id), su])


func _mo_ruong(k: String, o: int) -> String:
	var gia := int(settings.get("chest_cost", 100))
	var co := int(_bang("tien").get(k, 0))
	if co < gia:
		return "chưa đủ vàng mở rương (%d/%d)" % [co, gia]
	_bang("tien")[k] = co - gia
	var ruong: Array = tt.get("ruong", [])
	ruong.erase(o)
	tt["ruong"] = ruong
	if o == int(tt.get("ruong_that", -1)):
		tt["thang"] = int(k)
		return "%s MỞ ĐÚNG RƯƠNG VÀ CHIẾN THẮNG" % Player.ten_theo_id(get_tree(), int(k))
	return "mở rương giả (-%d vàng)" % gia


func _bat_dau_chon_thue_dat(chu: int, o: int, checkpoint: String) -> void:
	_thue_token += 1
	tt["thue"] = {"chu": chu, "o": o, "checkpoint": checkpoint,
			"token": _thue_token}
	_phat(tt, "%s đã đánh dấu ô đất %d — chọn loại thuế cho ô này" % [
			Player.ten_theo_id(get_tree(), chu), o])
	_het_han_thue(_thue_token)


## HUD gọi khi người chơi bấm một nút trong menu thuế. Phím 1–4 vẫn đi qua
## `_unhandled_input()` để người chơi có thể chọn mà không cần nhả chuột khỏi camera.
func xin_chon_thue(loai: int) -> void:
	var thue: Dictionary = tt.get("thue", {}) as Dictionary
	if loai < 0 or loai >= 4 or thue.is_empty():
		return
	if int(thue.get("chu", -1)) != NetManager.local_id():
		return
	Fusion.rpc(_net_xin_thu_thue, NetManager.local_id(), loai)


@rpc("any_peer", "call_local")
func _net_xin_thu_thue(chu: int, loai: int) -> void:
	if not NetManager.is_master() or loai < 0 or loai >= 4:
		return
	var thue: Dictionary = tt.get("thue", {}) as Dictionary
	if thue.is_empty() or int(thue.get("chu", -1)) != chu:
		return
	_chot_thue(loai)


func _het_han_thue(token: int) -> void:
	await get_tree().create_timer(12.0).timeout
	if not NetManager.is_master():
		return
	var thue: Dictionary = tt.get("thue", {}) as Dictionary
	if not thue.is_empty() and int(thue.get("token", -1)) == token:
		_chot_thue(LuatBan.Thue.TIEN)


func _chot_thue(loai: int) -> void:
	var thue: Dictionary = tt.get("thue", {}) as Dictionary
	if thue.is_empty():
		return
	var chu := int(thue["chu"])
	var o := int(thue["o"])
	_bang("thue_dat")[str(o)] = loai
	var ten_thue := str(LuatBan.TEN_THUE[loai])
	tt.erase("thue")
	_sang_luot(chu, _noi_su_kien("đánh dấu ô đất · thuế %s" % ten_thue,
			str(thue.get("checkpoint", ""))))


func _mo_checkpoint_neu_du(id: int, truoc: int, sau: int, o_dung: int) -> String:
	var moc := int(settings.get("respawn_steps", 18))
	if moc <= 0 or sau / moc <= truoc / moc:
		return ""
	var ke := ban.ke(o_dung)
	var dat := o_dung if ke.is_empty() else int(ke[0])
	_bang("hoi_sinh")[LuatBan.khoa(id)] = dat
	return "mở điểm hồi sinh ở ô %d" % dat


func _noi_su_kien(a: String, b: String) -> String:
	if a.is_empty():
		return b
	return a if b.is_empty() else "%s · %s" % [a, b]


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


## Rải đúng bốn loại ô theo tỷ lệ chủ phòng chọn, rồi đặt 4 rương lên các ô ngẫu nhiên.
## Chỉ master gọi; kết quả cụ thể nằm trong gói trạng thái nên mọi máy nhìn cùng một bàn.
func _tao_mat_ban(moi: Dictionary) -> void:
	var n := ban.so_luong()
	var loai: Array = []
	var cau_hinh := [
		[BanDuong.Loai.DAT, "tile_land"],
		[BanDuong.Loai.MAU, "tile_health"],
		[BanDuong.Loai.TIEN, "tile_money"],
		[BanDuong.Loai.TRANG_BI, "tile_equipment"],
	]
	var con_lai := n
	for i in cau_hinh.size():
		var dem := (n * int(settings[cau_hinh[i][1]])) / 100
		if i == cau_hinh.size() - 1:
			dem = con_lai
		for _j in int(dem):
			loai.append(int(cau_hinh[i][0]))
		con_lai -= int(dem)
	_tron(loai)
	# Ô xuất phát luôn là đất để tất cả cùng đứng trên một mặt ổn định.
	if not loai.is_empty():
		var vi_tri_dat := loai.find(BanDuong.Loai.DAT)
		if vi_tri_dat > 0:
			var tmp = loai[0]
			loai[0] = loai[vi_tri_dat]
			loai[vi_tri_dat] = tmp
	moi["loai_o"] = loai
	var ung_vien: Array = []
	for i in range(1, n):
		ung_vien.append(i)
	_tron(ung_vien)
	var so_ruong := mini(4, ung_vien.size())
	moi["ruong"] = ung_vien.slice(0, so_ruong)
	moi["ruong_that"] = int(moi["ruong"][_rng.randi_range(0, so_ruong - 1)]) if so_ruong > 0 else -1


func _ap_mat_ban() -> void:
	if ban == null:
		return
	var loai: Array = tt.get("loai_o", []) as Array
	var ruong: Array = tt.get("ruong", []) as Array
	var dat: Dictionary = _bang("chu_dat")
	var thue_dat: Dictionary = _bang("thue_dat")
	var checkpoints: Dictionary = _bang("hoi_sinh")
	for i in ban.so_luong():
		var ten_chu := ""
		var ten_thue := ""
		if dat.has(str(i)):
			ten_chu = Player.ten_theo_id(get_tree(), int(dat[str(i)]))
		if thue_dat.has(str(i)):
			var loai_thue := int(thue_dat[str(i)])
			if loai_thue >= 0 and loai_thue < LuatBan.TEN_THUE.size():
				ten_thue = str(LuatBan.TEN_THUE[loai_thue])
		var ds_hoi_sinh := PackedStringArray()
		for k in checkpoints:
			if int(checkpoints[k]) == i:
				ds_hoi_sinh.append(Player.ten_theo_id(get_tree(), int(k)))
		ban.hien_o(i, int(loai[i]) if i < loai.size() else BanDuong.Loai.DAT,
				ten_chu, ten_thue, ruong.has(i), ds_hoi_sinh)


func _loai_o(i: int) -> int:
	var loai: Array = tt.get("loai_o", []) as Array
	return int(loai[i]) if i >= 0 and i < loai.size() else BanDuong.Loai.DAT


func _tron(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


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
			# Chỉ camera của người sở hữu đổi sang góc ngắm. Máy khác không có rig này,
			# và trạng thái túi được tra bằng local_id nên không thể hiện góc ngắm của đối thủ.
			p.rig.set_ngam_sung(bat and _co_sung_trong_tui(NetManager.local_id()))
