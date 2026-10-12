class_name PhaBanCo
extends Node

## Pha 2 — bàn party: tung xúc xắc, đi, ăn hiệu ứng ô; hết vòng thì sang minigame.
## Master giữ luật và phát NGUYÊN trạng thái (`tt`) cho cả phòng bằng một gói JSON.
## Luật nằm ở các file `luat_*.gd`; file này lo mạng, lượt đi và cây scene.

signal het_vong(thu_tu_cu: Array)

## Trạng thái vừa đổi (HUD nghe).
signal trang_thai_doi(tt: Dictionary)

## Dòng nhắc cho HUD lúc chọn hướng.
signal chon_huong_doi(noi_dung: String)

## Gói mang theo một hiệu ứng dùng đồ; `DungDo` dựng scene hiệu ứng và gán `hieu_ung_dang_dien`.
## Chỉ phát một lần mỗi gói.
signal hieu_ung(fx: Dictionary)

## Hết ván (cờ `thang` trong gói); `main.gd` đóng bàn.
signal van_thang(id: int)

## Chế độ camera của máy này vừa đổi (HUD vẽ nhãn).
signal camera_doi(nhan: String)

## Camera bàn — riêng từng máy, không replicate.
## TU_DO: bay tự do (mặc định khi vào bàn). GAN: gắn nhân vật — mình hoặc người đang theo dõi.
enum CheDoCam { TU_DO, GAN }

## Phím chọn trên bàn (ngã rẽ, mục tiêu vật phẩm). Không dùng A/D vì WASD là của camera bay.
const PHIM_TRAI := KEY_Z
const PHIM_PHAI := KEY_X


## Bấm phím chọn trái (-1) / phải (+1); 0 = không phải.
static func huong_phim(event: InputEvent) -> int:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return 0
	if k.physical_keycode == PHIM_TRAI or k.keycode == PHIM_TRAI:
		return -1
	if k.physical_keycode == PHIM_PHAI or k.keycode == PHIM_PHAI:
		return 1
	return 0

const CAO_BAN := 100.0
const GIAY_MOI_O := 0.22
const NGHI_GIUA_LUOT := 0.8

## Chân nhân vật cao hơn gốc ô chừng này (mặt ô ~0.31 m).
const CAO_DUNG := 0.32

## Nhiều người chung ô thì đứng cách tâm chừng này.
const BAN_KINH_DUNG := 0.45

## Phóng to hình quân cờ (chỉ hình, không đổi va chạm).
const TO_BAN := 1.35

@export var ban_scene: PackedScene = null
@export var xuc_xac_scene: PackedScene = null
@export var hai_xuc_xac_scene: PackedScene = null

var settings: Dictionary = GameplaySettings.defaults()

## Trạng thái bàn: master giữ bản gốc, máy khác nhận nguyên gói.
var tt: Dictionary = {}
var ban: BanDuong = null

## Scene hiệu ứng vừa được dựng cho gói này (do `DungDo` gán lúc phát `hieu_ung`). Quân cờ chỉ
## bị giật về ô khi hiệu ứng báo `cham`, để người bị kéo/hoán đổi không dịch chuyển trước hình.
var hieu_ung_dang_dien: HieuUng = null

## Có lớp khác (minigame, bảng thắng) đang phủ lên bàn.
var tam_dung := false
var _dang_di := false
var _dang_chon := false
var _dice_ready := false
var _id_dang_tung := -1
var _so_dang_tung := 0

## Các hướng ở ngã rẽ đang chờ chọn.
var _cac_huong := PackedInt32Array()
var _lua_chon := 0

## Đang diễn một đoạn đi; đoạn sau phải chờ.
var _dang_dien := false
var _thue_token := 0

## CHỈ master: phần còn lại của lượt đang đi.
var _buoc_con := 0
var _duong_luot: Array = []
var _su_duong := ""
var _o_cuoi := -1
var _cho_master := PackedInt32Array()
var _xuc_xac: Node3D = null
var _hai_xuc_xac: Node3D = null

var che_do_cam := CheDoCam.TU_DO
## Ở chế độ GAN: 0 = tự động (người đang tới lượt), còn lại = id người đang theo dõi.
var muc_theo := 0
var cam_tu_do: CameraTuDo = null
## Đang ngắm vật phẩm: bắt buộc dùng camera nhân vật mình (tâm màn hình = tia bắn).
var _ep_cam_toi := false

## RNG của master; kết quả đi trong gói nên mọi máy thấy giống nhau.
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


## CHỈ master. `thu_tu_moi` rỗng = lần đầu, trộn thứ tự ngẫu nhiên.
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
	moi["so_vong"] = KinhTe.so_vong(ds.size(), settings)
	_tao_mat_ban(moi)
	_phat(moi, "Bắt đầu — thứ tự lượt đã được chọn ngẫu nhiên")


## CHỈ master: hết minigame → thưởng, sang vòng mới (hoặc hết ván).
func xin_thu_tu_moi(xep_hang: Array) -> void:
	if not NetManager.is_master() or xep_hang.is_empty() or not dang_chay():
		return
	var quai := LuatHieuUng.het_vong(tt, settings, ban, ten)
	var thuong := _noi_su_kien(quai, KinhTe.thuong_minigame(tt, xep_hang, settings, _rng))
	if int(tt.get("vong", 1)) >= int(tt.get("so_vong", 1)):
		tt["thang"] = LuatRuong.nguoi_thang(tt)
		_phat(tt, "Hết vòng · %s" % thuong)
		return
	var moi := LuatBan.trang_thai_moi(xep_hang, tt, settings)
	moi["vong"] = int(moi["vong"]) + 1
	_phat(moi, "Vòng %d/%d · %s" % [int(moi["vong"]), int(moi["so_vong"]), thuong])


## Đóng bàn, xoá sạch trạng thái (mọi máy).
func dong() -> void:
	tt = {}
	_dang_di = false
	_dang_chon = false
	_dice_ready = false
	_id_dang_tung = -1
	_so_dang_tung = 0
	_cac_huong = PackedInt32Array()
	_cho_master = PackedInt32Array()
	_dang_dien = false
	che_do_cam = CheDoCam.TU_DO
	muc_theo = 0
	_ep_cam_toi = false
	cam_tu_do = null
	camera_doi.emit("")
	chon_huong_doi.emit("")
	tam_dung = false
	_camera_cua_toi()
	_che_do_ban_co(false)
	if ban != null and is_instance_valid(ban):
		ban.queue_free()
	ban = null
	if _xuc_xac != null and is_instance_valid(_xuc_xac):
		_xuc_xac.queue_free()
	_xuc_xac = null
	if _hai_xuc_xac != null and is_instance_valid(_hai_xuc_xac):
		_hai_xuc_xac.queue_free()
	_hai_xuc_xac = null
	trang_thai_doi.emit(tt)


# ───────────────────────────── mạng ─────────────────────────────


## CHỈ master. Gói tới mọi máy, kể cả master (`call_local`).
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
	# Hiệu ứng diễn trước khi quân cờ bị dời (Cần câu: móc bay tới, kéo về rồi mới chốt ô).
	var fx = tt.get("hieu_ung")
	tt.erase("hieu_ung")
	hieu_ung_dang_dien = null
	if fx is Dictionary:
		hieu_ung.emit(fx)
	var cho := hieu_ung_dang_dien
	hieu_ung_dang_dien = null
	# Minigame đang phủ: chỉ nhận số liệu. Đang diễn đoạn đi thì không giật người về ô.
	if not tam_dung:
		_che_do_ban_co(true)
		_sau_hieu_ung(cho)
	trang_thai_doi.emit(tt)
	if tt.has("thang"):
		var id := int(tt["thang"])
		van_thang.emit(id)
		return
	if str(tt.get("su_kien", "")) == "het_vong":
		het_vong.emit(_thu_tu())


## Có hiệu ứng thì chờ nó báo `cham`, rồi giật mọi người về ô theo gói và chuyển camera.
func _sau_hieu_ung(cho: HieuUng) -> void:
	if cho != null and not cho.da_cham:
		await cho.cham
	_dat_moi_nguoi_len_o()
	# Camera ở lại chỗ hiệu ứng cho tới khi nó diễn xong.
	if cho != null and not cho.da_xong:
		await cho.xong
	_cap_nhat_camera()


## Giật mọi người về ô theo gói (đang diễn đoạn đi thì thôi).
func _dat_moi_nguoi_len_o() -> void:
	if _dang_di or tam_dung or not dang_chay():
		return
	for id in _thu_tu():
		_dat_len_o(int(id), int(_bang("o").get(LuatBan.khoa(id), 0)))


func _unhandled_input(event: InputEvent) -> void:
	# C: camera tự do <-> gắn nhân vật · V: đổi người theo dõi. Mỗi máy tự quyết, không gửi mạng.
	if event is InputEventKey and event.pressed and not event.echo and ban != null \
			and dang_chay() and not tam_dung and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.keycode == KEY_C:
			get_viewport().set_input_as_handled()
			doi_che_do_camera()
			return
		if event.keycode == KEY_V:
			get_viewport().set_input_as_handled()
			doi_nguoi_theo_doi()
			return
	var thue: Dictionary = tt.get("thue", {}) as Dictionary
	if not thue.is_empty() and int(thue.get("chu", -1)) == NetManager.local_id():
		if event is InputEventKey and event.pressed and not event.echo:
			var lua_chon_thue := int((event as InputEventKey).keycode) - KEY_1
			if lua_chon_thue >= 0 and lua_chon_thue < 4:
				get_viewport().set_input_as_handled()
				Fusion.rpc(_net_xin_thu_thue, NetManager.local_id(), lua_chon_thue)
		return
	if _dang_chon and _id_dang_tung == NetManager.local_id():
		var buoc := huong_phim(event)
		if buoc != 0:
			get_viewport().set_input_as_handled()
			_lua_chon = posmod(_lua_chon + buoc, _cac_huong.size())
			_cap_nhat_lua_chon()
			return
		if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_dang_chon = false
			chon_huong_doi.emit("")
			Fusion.rpc(_net_xin_huong, NetManager.local_id(), int(_cac_huong[_lua_chon]))
			return
	if not _den_luot_minh():
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		# Luôn gieo hai hột; hột thứ hai chỉ dùng khi có Hai hột xí ngầu.
		Fusion.rpc(_net_tung, NetManager.local_id(), randi() % 6 + 1, randi() % 6 + 1)


func _den_luot_minh() -> bool:
	if not dang_chay() or _dang_di or tam_dung or not (tt.get("thue", {}) as Dictionary).is_empty():
		return false
	return int(_thu_tu()[int(tt["luot"])]) == NetManager.local_id()


## Được dùng đồ: tới lượt, chưa tung, không bị che, ván chưa xong.
func den_luot_dung_do(id: int) -> bool:
	if not dang_chay() or tam_dung or _dang_di or _dang_chon or tt.has("thang"):
		return false
	if not (tt.get("thue", {}) as Dictionary).is_empty():
		return false
	var ds := _thu_tu()
	var luot := int(tt.get("luot", -1))
	return luot >= 0 and luot < ds.size() and int(ds[luot]) == id


## Tên người theo khoá chuỗi (Callable cho file luật).
func ten(k: String) -> String:
	return Player.ten_theo_id(get_tree(), int(k))


## CHỈ master, sau khi dùng một món.
func sau_khi_dung(id: int, su: String, ra: Dictionary) -> void:
	var duong: Array = ra.get("duong", []) as Array
	if not duong.is_empty():
		LuatHieuUng.ghi_duong(tt, LuatBan.khoa(id), duong)
		su = _noi_su_kien(su, _ruong_tren_duong(LuatBan.khoa(id), PackedInt32Array(duong)))
	if ra.has("hieu_ung"):
		tt["hieu_ung"] = ra["hieu_ung"]
	if bool(ra.get("het_luot", false)):
		_sang_luot(id, su)
	else:
		_phat(tt, su)


@rpc("any_peer", "call_local")
func _net_tung(id: int, so: int, so_2: int) -> void:
	if not dang_chay() or _dang_di or tam_dung:
		return
	if int(_thu_tu()[int(tt["luot"])]) != id:
		return
	_dang_di = true
	_dice_ready = false
	_id_dang_tung = id
	so = clampi(so, 1, 6)
	_so_dang_tung = so
	if str(tt.get("hai_hot", "")) == LuatBan.khoa(id):
		so_2 = clampi(so_2, 1, 6)
		_so_dang_tung += so_2
		await _hien_hai_xuc_xac(id, so, so_2)
	else:
		await _hien_xuc_xac(id, so)
	_dice_ready = true
	if NetManager.is_master():
		_buoc_con = _so_dang_tung
		_duong_luot = [int(_bang("o").get(LuatBan.khoa(id), 0))]
		_su_duong = ""
		_o_cuoi = -1
		_di_tiep(id, -1)


## CHỈ master. Đi từng ô tới khi hết bước, vướng rào/bẫy, hoặc gặp ngã rẽ cần chọn.
## Chiều đi (`tt.chieu`) chốt ở bước đầu ván — không bao giờ đi lùi.
func _di_tiep(id: int, chon: int) -> void:
	var k := LuatBan.khoa(id)
	var o := int(_duong_luot[_duong_luot.size() - 1])
	var doan := [o]
	_cho_master = PackedInt32Array()
	while _buoc_con > 0:
		var chieu := int(_bang("chieu").get(k, 0))
		var huong := ban.huong_di(o, chieu)
		if huong.is_empty():
			_buoc_con = 0
			break
		var toi := int(huong[0])
		if huong.size() > 1:
			if chon < 0 or not huong.has(chon):
				_cho_master = huong
				break
			toi = chon
			chon = -1
		if chieu == 0:
			_bang("chieu")[k] = ban.chieu_toi(o, toi)
		var rao := LuatBay.vuong_rao(tt, k, toi, ten)
		if not rao.is_empty():
			_su_duong = _noi_su_kien(_su_duong, rao)
			_buoc_con = 0
			break
		doan.append(toi)
		o = toi
		_buoc_con -= 1
		var bay := LuatBay.giam_bay(tt, k, o, _buoc_con, settings, ten)
		if not bay.is_empty():
			_su_duong = _noi_su_kien(_su_duong, str(bay["su"]))
			_buoc_con = int(bay["con"])
			if int(bay["o_cuoi"]) >= 0:
				_o_cuoi = int(bay["o_cuoi"])
				_buoc_con = 0
				break
	_duong_luot.append_array(doan.slice(1))
	Fusion.rpc(_net_di_doan, id, JSON.stringify({"doan": doan, "huong": Array(_cho_master)}))


## Người tới lượt chọn hướng ở ngã rẽ.
@rpc("any_peer", "call_local")
func _net_xin_huong(id: int, o_chon: int) -> void:
	if not NetManager.is_master() or id != _id_dang_tung or not _cho_master.has(o_chon):
		return
	_di_tiep(id, o_chon)


## Mọi máy diễn một đoạn đi; dừng ở ngã rẽ thì hiện mũi tên.
@rpc("any_peer", "call_local")
func _net_di_doan(id: int, json: String) -> void:
	if not dang_chay() or id != _id_dang_tung:
		return
	var raw = JSON.parse_string(json)
	if not (raw is Dictionary):
		return
	var doan := PackedInt32Array()
	for o in raw.get("doan", []):
		doan.append(int(o))
	var huong := PackedInt32Array()
	for o in raw.get("huong", []):
		huong.append(int(o))
	while not _dice_ready or _dang_dien:
		await get_tree().process_frame
	_dang_dien = true
	_dang_chon = false
	_cac_huong = PackedInt32Array()
	chon_huong_doi.emit("")
	if ban != null:
		ban.hien_mui_ten(0, _cac_huong, 0)
	await _di_theo_duong(id, doan)
	_dang_dien = false
	if not huong.is_empty():
		_cac_huong = huong
		_lua_chon = 0
		_dang_chon = true
		_cap_nhat_lua_chon()
		return
	_dang_di = false
	_id_dang_tung = -1
	_so_dang_tung = 0
	if NetManager.is_master():
		await get_tree().create_timer(NGHI_GIUA_LUOT).timeout
		_ket_luot(id, _duong_luot.size() - 1, PackedInt32Array(_duong_luot))


func _cap_nhat_lua_chon() -> void:
	if ban == null or _cac_huong.is_empty():
		return
	var o := int(_bang("o").get(LuatBan.khoa(_id_dang_tung), 0))
	ban.hien_mui_ten(o, _cac_huong, _lua_chon)
	if _id_dang_tung == NetManager.local_id():
		chon_huong_doi.emit("NGÃ RẼ — chọn hướng  %d/%d    [Z/X] đổi    [SPACE/E] đi" % [
				_lua_chon + 1, _cac_huong.size()])
	else:
		chon_huong_doi.emit("%s đang chọn hướng..." % Player.ten_theo_id(get_tree(),
				_id_dang_tung))


## TU_DO: camera bay của máy này. GAN: bám người được theo dõi (tự động = người đang tới lượt;
## tới mình thì dùng camera nhân vật để ngắm đồ). Đang ngắm đồ thì luôn về camera mình.
func _cap_nhat_camera() -> void:
	if ban == null or tam_dung or tt.has("thang"):
		return
	_bao_dam_cam_tu_do()
	if _ep_cam_toi:
		_camera_cua_toi()
	elif che_do_cam == CheDoCam.TU_DO:
		cam_tu_do.make_current()
	else:
		var id := _id_theo_doi()
		if id == NetManager.local_id():
			_camera_cua_toi()
		elif nguoi(id) != null:
			ban.camera_ban.theo(nguoi(id))
	_bao_camera()


## Id người camera GAN đang bám (-1 = chưa có lượt).
func _id_theo_doi() -> int:
	if muc_theo != 0 and nguoi(muc_theo) != null:
		return muc_theo
	var ds := _thu_tu()
	var luot := int(tt.get("luot", -1))
	if luot < 0 or luot >= ds.size():
		return NetManager.local_id()
	return int(ds[luot])


## Camera bàn nhìn vào `n` một lúc (hiệu ứng, xem trước mục tiêu). Ở camera tự do thì không giật
## camera, trừ khi `ca_khi_tu_do` (chính mình đang chọn mục tiêu bằng Z/X).
func cam_xem(n: Node3D, ca_khi_tu_do := false) -> void:
	if ban == null or n == null:
		return
	if che_do_cam == CheDoCam.TU_DO and not ca_khi_tu_do:
		return
	if che_do_cam == CheDoCam.GAN and muc_theo != 0 and not ca_khi_tu_do:
		return
	ban.camera_ban.theo(n)


## DungDo bật khi đang ngắm vật phẩm.
func ep_camera_toi(bat: bool) -> void:
	if _ep_cam_toi == bat:
		return
	_ep_cam_toi = bat
	_cap_nhat_camera()


func _bao_dam_cam_tu_do() -> void:
	if cam_tu_do != null and is_instance_valid(cam_tu_do):
		return
	cam_tu_do = CameraTuDo.new()
	cam_tu_do.name = "CameraTuDo"
	ban.add_child(cam_tu_do)
	cam_tu_do.tam = Vector3(ban.global_position.x, CAO_BAN, ban.global_position.z)
	# Bắt đầu chếch phía sau-trên quân của mình, nhìn xuống ô đang đứng.
	var toi := nguoi(NetManager.local_id())
	var dich := toi.global_position if toi != null else cam_tu_do.tam
	cam_tu_do.dat_nhin(dich + Vector3(0.0, 14.0, 12.0), dich)


## Đổi qua lại camera tự do / gắn nhân vật.
func doi_che_do_camera() -> void:
	if ban == null or not dang_chay():
		return
	che_do_cam = CheDoCam.GAN if che_do_cam == CheDoCam.TU_DO else CheDoCam.TU_DO
	if che_do_cam == CheDoCam.TU_DO:
		# Bay tiếp từ đúng chỗ camera đang nhìn cho khỏi giật.
		_bao_dam_cam_tu_do()
		var cu := get_viewport().get_camera_3d()
		if cu != null and cu != cam_tu_do:
			var nhin := cu.global_position - cu.global_basis.z * 10.0
			cam_tu_do.dat_nhin(cu.global_position, nhin)
	_cap_nhat_camera()


## Chế độ GAN: lần lượt theo dõi tự động → mình → từng người khác.
func doi_nguoi_theo_doi() -> void:
	if ban == null or not dang_chay():
		return
	if che_do_cam != CheDoCam.GAN:
		che_do_cam = CheDoCam.GAN
	var ds: Array = [0]
	for id in _thu_tu():
		ds.append(int(id))
	var i := ds.find(muc_theo)
	muc_theo = int(ds[(i + 1) % ds.size()])
	_cap_nhat_camera()


func _bao_camera() -> void:
	if che_do_cam == CheDoCam.TU_DO and not _ep_cam_toi:
		camera_doi.emit("CAM TỰ DO")
		return
	var id := _id_theo_doi()
	var ten_nguoi := "BẠN" if id == NetManager.local_id() else Player.ten_theo_id(get_tree(), id)
	camera_doi.emit(("THEO LƯỢT · %s" if muc_theo == 0 else "THEO · %s") % ten_nguoi)


## Camera về đúng chỗ theo lượt hiện tại (sau khi camera bàn bám mục tiêu / hiệu ứng).
func dat_lai_camera() -> void:
	_cap_nhat_camera()


func _camera_cua_toi() -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_mine and p.rig != null and is_instance_valid(p.rig):
			p.rig.make_current()


func _hien_xuc_xac(id: int, so: int) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		await get_tree().create_timer(0.6).timeout
		return
	_xuc_xac = _gan_vao_camera(_xuc_xac, xuc_xac_scene, camera)
	await _xuc_xac.tung(clampi(so, 1, 6), Player.ten_theo_id(get_tree(), id))


## Hai hột xí ngầu: cả hai hột hiện cùng lúc, mỗi hột một mặt từ RPC của người tung.
func _hien_hai_xuc_xac(id: int, so_1: int, so_2: int) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		await get_tree().create_timer(0.6).timeout
		return
	_hai_xuc_xac = _gan_vao_camera(_hai_xuc_xac, hai_xuc_xac_scene, camera)
	await _hai_xuc_xac.tung(so_1, so_2, Player.ten_theo_id(get_tree(), id))


## Xúc xắc gắn vào camera đang dùng: dựng lần đầu, các lần sau chuyển theo camera.
func _gan_vao_camera(cu: Node3D, scene: PackedScene, camera: Camera3D) -> Node3D:
	if cu == null or not is_instance_valid(cu):
		cu = scene.instantiate() as Node3D
		camera.add_child(cu)
	elif cu.get_parent() != camera:
		cu.reparent(camera, false)
	return cu


# ───────────────────────────── luật cần tới bàn ─────────────────────────────


## CHỈ master. Áp hiệu ứng ô vừa dừng rồi sang lượt kế.
func _ket_luot(id: int, so_buoc: int, duong: PackedInt32Array) -> void:
	var k := LuatBan.khoa(id)
	var o_dung := int(_bang("o").get(k, 0))
	var truoc := int(_bang("buoc").get(k, 0))
	_bang("buoc")[k] = truoc + so_buoc
	var checkpoint := _mo_checkpoint_neu_du(id, truoc, int(_bang("buoc")[k]), o_dung)
	var bay := _su_duong
	var o_cuoi := _o_cuoi
	_su_duong = ""
	_o_cuoi = -1
	tt.erase("hai_hot")
	LuatHieuUng.ghi_duong(tt, k, Array(duong))
	checkpoint = _noi_su_kien(_ruong_tren_duong(k, duong), checkpoint)
	checkpoint = _noi_su_kien(bay, checkpoint)
	# Gục vì bẫy / bị Dây thun giật về: không ăn hiệu ứng ô.
	if o_cuoi >= 0:
		_bang("o")[k] = o_cuoi
		_sang_luot(id, checkpoint)
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
		var mon := VatPham.rut_o(_rng)
		su = "+" + VatPham.ten(mon) + LuatBan.them_do(tt, k, mon)
	_sang_luot(id, _noi_su_kien(su, checkpoint))


func _sang_luot(id: int, su: String) -> void:
	tt.erase("da_dung")
	tt.erase("hai_hot")
	su = _noi_su_kien(su, LuatHieuUng.cuoi_luot(tt, LuatBan.khoa(id), settings, ten))
	var luot := int(tt["luot"]) + 1
	if luot >= _thu_tu().size():
		tt["luot"] = 0
		_phat(tt, "het_vong")
		return
	tt["luot"] = luot
	_phat(tt, "" if su.is_empty() else "%s: %s" % [Player.ten_theo_id(get_tree(), id), su])


## Đi qua Rương báu thì mở nếu đủ vàng, rồi dời rương.
func _ruong_tren_duong(k: String, duong: PackedInt32Array) -> String:
	var o := int(tt.get("ruong_o", -1))
	if not Array(duong).slice(1).has(o):
		return ""
	var su := LuatRuong.mo(tt, k, settings)
	if not su.is_empty():
		tt["ruong_o"] = _o_ruong_moi(o)
	return su


func _o_ruong_moi(cu: int) -> int:
	var gan := ban.o_trung_bom(cu, range(LuatRuong.CACH_TOI_THIEU))
	var co_nguoi: Array = []
	for k in _bang("o"):
		co_nguoi.append(int(_bang("o")[k]))
	return LuatRuong.cho_moi(ban.so_luong(), cu, gan, co_nguoi, _rng)


func _bat_dau_chon_thue_dat(chu: int, o: int, checkpoint: String) -> void:
	_thue_token += 1
	tt["thue"] = {"chu": chu, "o": o, "checkpoint": checkpoint,
			"token": _thue_token}
	_phat(tt, "%s đã đánh dấu ô đất %d — chọn loại thuế cho ô này" % [
			Player.ten_theo_id(get_tree(), chu), o])
	_het_han_thue(_thue_token)


## HUD gọi khi bấm nút trong menu thuế.
## Kho đồ: đổi chỗ hai ô túi của mình (lúc nào cũng được, không tốn lượt).
func xin_doi_cho_do(a: int, b: int) -> void:
	if not dang_chay():
		return
	Fusion.rpc(_net_xin_doi_cho_do, NetManager.local_id(), a, b)


@rpc("any_peer", "call_local")
func _net_xin_doi_cho_do(id: int, a: int, b: int) -> void:
	if not NetManager.is_master() or not dang_chay() or tt.has("thang"):
		return
	if LuatBan.doi_cho(tt, LuatBan.khoa(id), a, b):
		# Phát lại sự kiện cũ; riêng cờ "het_vong" không được phát lại (sẽ kích hết vòng lần nữa).
		var su := str(tt.get("su_kien", ""))
		_phat(tt, "" if su == "het_vong" else su)


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


## Có người rời phòng giữa ván: master gỡ họ khỏi vòng lượt.
func _khi_mat_nguoi(n: Node) -> void:
	var p := n as Player
	if p == null or not dang_chay() or not NetManager.is_master():
		return
	_bo_khoi_vong(p.player_id())


## Gỡ người khỏi vòng lượt và chỉnh con trỏ lượt cho đúng người kế tiếp.
func _bo_khoi_vong(id: int) -> void:
	var ds := _thu_tu().duplicate()
	var i := -1
	for j in ds.size():
		if int(ds[j]) == id:
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
	_dang_di = false  # họ có thể đang giữa đoạn đi
	_phat(tt, "%s rời phòng" % Player.ten_theo_id(get_tree(), id))


## CHỈ master. Rải loại ô theo tỷ lệ, đặt Rương báu.
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
	# Ô xuất phát luôn là đất.
	if not loai.is_empty():
		var vi_tri_dat := loai.find(BanDuong.Loai.DAT)
		if vi_tri_dat > 0:
			var tmp = loai[0]
			loai[0] = loai[vi_tri_dat]
			loai[vi_tri_dat] = tmp
	moi["loai_o"] = loai
	moi["ruong_o"] = LuatRuong.cho_moi(n, 0, ban.o_trung_bom(0, range(LuatRuong.CACH_TOI_THIEU)),
			[0], _rng)


func _ap_mat_ban() -> void:
	if ban == null:
		return
	var loai: Array = tt.get("loai_o", []) as Array
	var ruong := int(tt.get("ruong_o", -1))
	ban.dat_ruong(ruong)
	ban.dat_quai(int((tt.get("quai", {}) as Dictionary).get("o", -1)))
	var ghi_chu := _ghi_chu_tren_o()
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
				ten_chu, ten_thue, i == ruong, ds_hoi_sinh,
				PackedStringArray(ghi_chu.get(i, [])))
	ban.hien_dau_hieu(_dau_hieu_tren_o())


## {"rao:ô" / "bay:ô" / "neo:người": ô} — để dựng mô hình rào, bẫy, neo trên bàn.
func _dau_hieu_tren_o() -> Dictionary:
	var ra := {}
	for loai in ["rao", "bay"]:
		for o in _bang(loai):
			ra["%s:%s" % [loai, o]] = int(o)
	var neo: Dictionary = _bang("neo")
	for k in neo:
		ra["neo:%s" % k] = int((neo[k] as Dictionary).get("o", 0))
	return ra


## {ô: ["BAY · Tên", ...]} — bẫy, rào, neo đang nằm trên ô.
func _ghi_chu_tren_o() -> Dictionary:
	var ra := {}
	for cap in [["bay", "BAY"], ["rao", "RAO"]]:
		var bang: Dictionary = _bang(cap[0])
		for o in bang:
			ra[int(o)] = (ra.get(int(o), []) as Array) + ["%s · %s" % [cap[1], ten(str(bang[o]))]]
	var neo: Dictionary = _bang("neo")
	for k in neo:
		var o := int((neo[k] as Dictionary).get("o", -1))
		ra[o] = (ra.get(o, []) as Array) + ["NEO · %s" % ten(k)]
	return ra


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


func _di_theo_duong(id: int, duong: PackedInt32Array) -> void:
	var k := LuatBan.khoa(id)
	var p := nguoi(id)
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
	var p := nguoi(id)
	if p != null:
		p.global_position = _cho_dung(id, o)


## Chỗ đứng trên ô: rải quanh tâm theo thứ tự lượt để không chồng lên nhau.
func _cho_dung(id: int, o: int) -> Vector3:
	var goc := ban.vi_tri(o) + Vector3.UP * CAO_DUNG
	var ds := _thu_tu()
	if ds.size() <= 1:
		return goc
	# JSON trả số dạng float — phải ép kiểu khi so.
	for i in ds.size():
		if int(ds[i]) == id:
			var a := TAU * i / float(ds.size())
			return goc + Vector3(cos(a), 0.0, sin(a)) * BAN_KINH_DUNG
	return goc


## Chỗ đứng của người `id` trên ô `o` (cho hiệu ứng biết quân cờ sẽ dời tới đâu).
func vi_tri_dung(id: int, o: int) -> Vector3:
	return _cho_dung(id, o)


func nguoi(id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == id:
			return p
	return null


func _thu_tu() -> Array:
	return tt.get("thu_tu", []) as Array


func _bang(ten: String) -> Dictionary:
	return tt.get(ten, {}) as Dictionary


## Bật/tắt chế độ quân cờ: phóng to hình mọi người; người của máy này bị khoá WASD.
func _che_do_ban_co(bat: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		p.model_root.scale = Vector3.ONE * (TO_BAN if bat else 1.0)
		if not p.is_mine:
			continue
		p.khoa_di_chuyen = bat
		if p.rig != null and is_instance_valid(p.rig):
			p.rig.set_ban_co(bat)
