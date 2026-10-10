class_name DungDo
extends Node

## Dùng vật phẩm trên bàn (node con của `PhaBanCo`).
## Máy người chơi: chọn món, ngắm / chọn mục tiêu, gửi yêu cầu. Master: kiểm luật, raycast, áp, phát
## gói (kèm mô tả hiệu ứng). Mọi máy: dựng scene hiệu ứng thế giới từ cùng một gói.

## Giao diện bàn của máy này đổi (HUD vẽ theo).
signal giao_dien_doi(hien: bool, chon: int, duoc_dung: bool)

## Bảng chọn dạng danh sách — chỉ còn dùng cho món chọn minigame. `nhan` rỗng = đóng bảng.
signal can_chon(tieu_de: String, nhan: PackedStringArray)

## Dòng nhắc cho HUD khi đang chọn mục tiêu trong thế giới (rỗng = tắt).
signal goi_y_doi(noi_dung: String)

## Số nút có sẵn trong `bang_chon.tscn`.
const TOI_DA_LUA_CHON := 9

## Gốc tia phải nằm quanh người dùng (camera đứng sau lưng).
const GOC_CACH_NGUOI_TOI_DA := 22.0

## Bán kính vòng mục tiêu (nhân với vòng gốc trong `vong_muc_tieu.tscn`): dưới chân người / trên ô.
const TY_LE_VONG_NGUOI := 1.0
const TY_LE_VONG_O := 1.35

## Món bắn trượt thì đạn bay tới chừng này (m) khi món không có tầm.
const TAM_TRUOT_VO_HAN := 30.0

@export var quan_tro: QuanTroMiniGame = null
@export var danh_muc: DanhMucVatPham = null

var _chon := -1
var _giao_dien_cu := ""

## Giá trị ứng với từng dòng của bảng chọn minigame đang mở.
var _gia_tri_chon: Array = []

## Món đang giơ trên đầu (chỉ báo lại khi đổi).
var _dang_cam := ""

## Mục tiêu hợp lệ của món chọn-trong-thế-giới (người / ô) và mục đang trỏ tới (A/D đổi).
var _ung_vien: Array = []
var _con_tro := 0

## Khoá vòng mục tiêu đã báo cho cả phòng ("" = ẩn, "n:<id>" người, "o:<ô>" ô) và dòng gợi ý cũ.
var _khoa_da_bao := ""
var _goi_y_cu := ""

## Đã gửi yêu cầu dùng, đang chờ hiệu ứng (giữ camera bàn thay vì trả về camera mình).
var _dang_gui := false

@onready var ban_co: PhaBanCo = get_parent() as PhaBanCo


func _ready() -> void:
	Fusion.register_broadcast_receiver(self)
	add_to_group("esc_huy")
	ban_co.hieu_ung.connect(_chieu_hieu_ung)


func _process(_delta: float) -> void:
	var hien := ban_co.dang_chay() and not ban_co.tam_dung
	var duoc := hien and ban_co.den_luot_dung_do(NetManager.local_id())
	if _chon >= 0 and (not duoc or _chon >= _tui().size()):
		_chon_mon(-1)
	var moi := "%s|%d|%s" % [hien, _chon, duoc]
	if moi != _giao_dien_cu:
		_giao_dien_cu = moi
		giao_dien_doi.emit(hien, _chon, duoc)


## Món ngắm (Ná, Cần câu...): vòng báo trước ai sẽ trúng nếu bắn ngay. Chỉ hiện ở máy người ngắm.
func _physics_process(_delta: float) -> void:
	if _chon < 0 or ban_co.ban == null:
		return
	var mon := str(_tui()[_chon]) if _chon < _tui().size() else ""
	if not VatPham.la_ngam(mon):
		return
	var camera := get_viewport().get_camera_3d()
	var toi := ban_co.nguoi(NetManager.local_id())
	if camera == null or toi == null:
		return
	var goc := camera.global_position
	var huong := -camera.global_transform.basis.z.normalized()
	var trung: Player
	if VatPham.nham(mon) == VatPham.Nham.NON:
		trung = NgamMucTieu.non(toi, goc, huong, VatPham.tam(mon))
	else:
		trung = NgamMucTieu.tia(toi, goc, huong, VatPham.tam(mon))
	if trung == null:
		ban_co.ban.an_muc_tieu()
	else:
		ban_co.ban.dat_muc_tieu(trung.global_position, TY_LE_VONG_NGUOI)


func _unhandled_input(event: InputEvent) -> void:
	# Đang chọn mục tiêu trong thế giới: A/D đổi mục tiêu, Space/E xác nhận. (DungDo đứng sau
	# PhaBanCo trong cây nên nhận sự kiện trước — Space ở đây không tung xúc xắc nữa.)
	if _chon >= 0 and not _ung_vien.is_empty() and _bam_duoc():
		var buoc := 0
		if event.is_action_pressed("move_left"):
			buoc = -1
		elif event.is_action_pressed("move_right"):
			buoc = 1
		if buoc != 0:
			get_viewport().set_input_as_handled()
			_con_tro = posmod(_con_tro + buoc, _ung_vien.size())
			_cap_nhat_vong()
			return
		if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_xac_nhan()
			return
	# Phím 1..9 chọn món; bấm lại là bỏ chọn.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if not _bam_duoc():
		return
	var o := int((event as InputEventKey).keycode) - KEY_1
	if o >= 0 and o < mini(_tui().size(), TOI_DA_LUA_CHON):
		get_viewport().set_input_as_handled()
		_chon_mon(-1 if o == _chon else o)


## Đọc chuột trái ở `_input` vì GUI có thể nuốt click trước `_unhandled_input`.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		return
	if _chon < 0 or not _bam_duoc():
		return
	var mon := str(_tui()[_chon])
	if not _ung_vien.is_empty():
		get_viewport().set_input_as_handled()
		_xac_nhan()
	elif VatPham.la_ngam(mon):
		get_viewport().set_input_as_handled()
		_gui(_huong_camera())
	elif VatPham.nham(mon) == VatPham.Nham.TAI_CHO:
		get_viewport().set_input_as_handled()
		_gui({})


## `PauseMenu` hỏi trước khi mở menu bằng Esc: đang chọn món thì Esc chỉ bỏ chọn.
func huy_bang_esc() -> bool:
	if _chon < 0:
		return false
	_chon_mon(-1)
	return true


## Còn được bấm dùng đồ: tới lượt, chưa dùng món nào lượt này, không dính mắm tôm.
func _bam_duoc() -> bool:
	var k := LuatBan.khoa(NetManager.local_id())
	return (ban_co.den_luot_dung_do(NetManager.local_id())
			and not (ban_co.tt.get("da_dung", {}) as Dictionary).has(k)
			and not LuatHieuUng.bi_khoa_do(ban_co.tt, k))


## Chọn dòng `i` của bảng chọn minigame; `i` < 0 = huỷ.
func chon(i: int) -> void:
	if i < 0 or i >= _gia_tri_chon.size() or _chon < 0:
		_chon_mon(-1)
		return
	_gui(_gia_tri_chon[i])


func _tui() -> Array:
	return (ban_co.tt.get("do", {}) as Dictionary).get(
			LuatBan.khoa(NetManager.local_id()), []) as Array


func _chon_mon(o: int) -> void:
	var tui := _tui()
	_chon = o if o >= 0 and o < tui.size() else -1
	var mon := "" if _chon < 0 else str(tui[_chon])
	_ap_ngam(not mon.is_empty() and VatPham.la_ngam(mon))
	_hien_tam(mon)
	if mon != _dang_cam:
		_dang_cam = mon
		Fusion.rpc(_net_cam, NetManager.local_id(), mon)
	_ung_vien = []
	_con_tro = 0
	_gia_tri_chon = []
	can_chon.emit("", PackedStringArray())
	if not mon.is_empty():
		match VatPham.nham(mon):
			VatPham.Nham.CHON_NGUOI, VatPham.Nham.CHON_O:
				_lap_ung_vien(mon)
			VatPham.Nham.CHON_MINIGAME:
				_mo_bang_chon(mon)
	if ban_co.ban != null and not VatPham.la_ngam(mon):
		ban_co.ban.an_muc_tieu()
	_cap_nhat_vong()


## Vòng `VongTam` (node trong player.tscn, bán kính 1 m) giãn theo tầm món đang cầm
## (1 ô ≈ `MET_MOI_O` m); không cầm / tầm vô hạn thì ẩn.
func _hien_tam(mon: String) -> void:
	var toi := ban_co.nguoi(NetManager.local_id())
	var vong := toi.get_node_or_null("VongTam") as Node3D if toi != null else null
	if vong == null:
		return
	var tam := 0.0 if mon.is_empty() else VatPham.tam(mon) * VatPham.MET_MOI_O
	vong.visible = tam > 0.0
	if tam > 0.0:
		vong.scale = Vector3(tam, 1.0, tam)


func _ap_ngam(bat: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_mine and p.rig != null and is_instance_valid(p.rig):
			p.rig.set_ngam_sung(bat and ban_co.dang_chay() and not ban_co.tam_dung)


# ───────────────────────────── chọn mục tiêu trong thế giới ─────────────────────────────


## Danh sách mục tiêu hợp lệ (cùng luật `LuatDo.muc_tieu_hop_le` mà master sẽ kiểm lại).
## Người: gần tới xa. Ô: ô có người trước, rồi gần tới xa.
func _lap_ung_vien(mon: String) -> void:
	var tt := ban_co.tt
	var toi := LuatBan.khoa(NetManager.local_id())
	var vi_tri: Dictionary = tt.get("o", {}) as Dictionary
	var ban := ban_co.ban
	if ban == null:
		return
	var nguoi_toi := ban_co.nguoi(NetManager.local_id())
	match VatPham.nham(mon):
		VatPham.Nham.CHON_NGUOI:
			var ds: Array = []
			for id in tt.get("thu_tu", []) as Array:
				var du := {"muc_tieu": LuatBan.khoa(id)}
				var p := ban_co.nguoi(int(id))
				if p != null and nguoi_toi != null and LuatDo.muc_tieu_hop_le(tt, toi, mon, du, ban):
					ds.append([p.global_position.distance_to(nguoi_toi.global_position), du])
			ds.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
			for d: Array in ds:
				_ung_vien.append(d[1])
		VatPham.Nham.CHON_O:
			var bac := []
			bac.resize(VatPham.tam(mon) + 1)
			bac.fill(0)
			var co_nguoi: Array = []
			var trong: Array = []
			for o in ban.o_trung_bom(int(vi_tri.get(toi, 0)), bac):
				var du := {"o": int(o)}
				if not LuatDo.muc_tieu_hop_le(tt, toi, mon, du, ban):
					continue
				var dang_dung := false
				for k in vi_tri:
					dang_dung = dang_dung or (k != toi and int(vi_tri[k]) == int(o))
				(co_nguoi if dang_dung else trong).append(du)
			_ung_vien = co_nguoi + trong


## Đưa vòng tới mục tiêu đang trỏ (báo cả phòng) và cập nhật dòng gợi ý của HUD.
func _cap_nhat_vong() -> void:
	var khoa := ""
	var goi_y := ""
	if _chon >= 0 and _chon < _tui().size():
		var mon := str(_tui()[_chon])
		if not _ung_vien.is_empty():
			var du: Dictionary = _ung_vien[_con_tro]
			var ten_muc_tieu := ""
			if du.has("muc_tieu"):
				khoa = "n:%s" % du["muc_tieu"]
				ten_muc_tieu = ban_co.ten(str(du["muc_tieu"]))
			else:
				khoa = "o:%d" % int(du["o"])
				ten_muc_tieu = "ô %d" % int(du["o"])
			goi_y = "%s → %s  (%d/%d)    [A/D] đổi · [SPACE/E/chuột trái] xác nhận · [Esc] huỷ" % [
					VatPham.ten(mon), ten_muc_tieu, _con_tro + 1, _ung_vien.size()]
		elif VatPham.nham(mon) == VatPham.Nham.CHON_NGUOI or VatPham.nham(mon) == VatPham.Nham.CHON_O:
			goi_y = "%s — không có mục tiêu trong tầm    [Esc] huỷ" % VatPham.ten(mon)
	if goi_y != _goi_y_cu:
		_goi_y_cu = goi_y
		goi_y_doi.emit(goi_y)
	_camera_theo_muc_tieu()
	if khoa != _khoa_da_bao:
		_khoa_da_bao = khoa
		Fusion.rpc(_net_ngam, NetManager.local_id(), khoa)


## Camera bàn bám mục tiêu đang trỏ để thấy vòng dù mục tiêu ở xa; hết chọn thì trả camera.
func _camera_theo_muc_tieu() -> void:
	if ban_co.ban == null:
		return
	if not _ung_vien.is_empty():
		var du: Dictionary = _ung_vien[_con_tro]
		var muc_tieu: Node3D = (ban_co.nguoi(int(str(du["muc_tieu"]))) if du.has("muc_tieu")
				else ban_co.ban.nut_o(int(du["o"])))
		if muc_tieu != null:
			ban_co.ban.camera_ban.theo(muc_tieu)
	elif not _dang_gui:
		ban_co.dat_lai_camera()


func _xac_nhan() -> void:
	if _con_tro >= 0 and _con_tro < _ung_vien.size():
		_gui(_ung_vien[_con_tro])


## Mọi máy: người đang tới lượt đổi mục tiêu đang trỏ, vòng mục tiêu dời theo ("" = ẩn).
## Chỉ là gợi ý nhìn; việc xác nhận vẫn do master kiểm trong `_net_xin_dung_do`.
@rpc("any_peer", "call_local")
func _net_ngam(id: int, khoa: String) -> void:
	if ban_co.ban == null:
		return
	if khoa.is_empty() or not ban_co.den_luot_dung_do(id):
		ban_co.ban.an_muc_tieu()
		return
	if khoa.begins_with("n:"):
		var p := ban_co.nguoi(int(khoa.substr(2)))
		if p != null:
			ban_co.ban.dat_muc_tieu(p.global_position, TY_LE_VONG_NGUOI)
			return
	elif khoa.begins_with("o:"):
		ban_co.ban.dat_muc_tieu(_diem_o(int(khoa.substr(2))), TY_LE_VONG_O)
		return
	ban_co.ban.an_muc_tieu()


func _mo_bang_chon(mon: String) -> void:
	var nhan := PackedStringArray()
	_gia_tri_chon = []
	if VatPham.nham(mon) == VatPham.Nham.CHON_MINIGAME:
		for ma in quan_tro.danh_sach():
			nhan.append(str(ma))
			_gia_tri_chon.append({"minigame": str(ma)})
	if nhan.size() > TOI_DA_LUA_CHON:
		nhan.resize(TOI_DA_LUA_CHON)
		_gia_tri_chon.resize(TOI_DA_LUA_CHON)
	can_chon.emit("%s — %s" % [VatPham.ten(mon),
			"chọn" if not nhan.is_empty() else "không có lựa chọn"], nhan)


func _huong_camera() -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return {}
	var goc := camera.global_position
	var huong := -camera.global_transform.basis.z.normalized()
	return {"goc": [goc.x, goc.y, goc.z], "huong": [huong.x, huong.y, huong.z]}


func _gui(du_lieu: Dictionary) -> void:
	var chi_so := _chon
	_dang_gui = true
	_chon_mon(-1)
	# Master từ chối thì không có hiệu ứng nào tới: tự trả camera.
	get_tree().create_timer(3.0).timeout.connect(_het_cho_hieu_ung)
	Fusion.rpc(_net_xin_dung_do, NetManager.local_id(), chi_so, JSON.stringify(du_lieu))


func _het_cho_hieu_ung() -> void:
	if _dang_gui:
		_dang_gui = false
		ban_co.dat_lai_camera()


## Mọi máy: giơ model món trên đầu người `id` (rỗng = cất).
@rpc("any_peer", "call_local")
func _net_cam(id: int, mon: String) -> void:
	var p := ban_co.nguoi(id)
	var vat := p.get_node_or_null("VatCam") as VatCam if p != null else null
	if vat != null:
		vat.hien(mon if VatPham.BANG.has(mon) else "")


# ───────────────────────────── hiệu ứng thế giới ─────────────────────────────


## Chân đứng trên ô (cùng độ cao với chân quân cờ), không rải quanh tâm.
func _diem_o(o: int) -> Vector3:
	return ban_co.ban.vi_tri(o) + Vector3.UP * PhaBanCo.CAO_DUNG


## Mọi máy: dựng scene hiệu ứng của món từ gói `fx` (người dùng, mục tiêu, ô, đường đi... do
## master gửi) và báo cho bàn chờ nó — quân cờ chỉ bị giật về ô khi hiệu ứng báo `cham`.
func _chieu_hieu_ung(fx: Dictionary) -> void:
	var mon := str(fx.get("mon", ""))
	var hinh := danh_muc.tim(mon) if danh_muc != null else null
	var nguoi_tu := ban_co.nguoi(int(fx.get("tu", -1)))
	if hinh == null or hinh.hieu_ung == null or nguoi_tu == null or ban_co.ban == null:
		return
	var nguoi_den := ban_co.nguoi(int(fx.get("den", -1)))
	var tu := nguoi_tu.global_position
	var den := _diem_den(fx, mon, tu, nguoi_den)
	var trung := bool(fx.get("trung", true))
	var ngu := {"tu": tu, "den": den, "nguoi_tu": nguoi_tu, "nguoi_den": nguoi_den,
			"trung": trung}
	var cac_o: Array[Vector3] = []
	for o in fx.get("cac_o", []) as Array:
		cac_o.append(_diem_o(int(o)))
	if cac_o.is_empty() and trung:
		cac_o.append(den)
	ngu["cac_o"] = cac_o
	if nguoi_den != null:
		var o_moi := int((ban_co.tt.get("o", {}) as Dictionary).get(
				LuatBan.khoa(int(fx["den"])), 0))
		ngu["den_moi"] = ban_co.vi_tri_dung(int(fx["den"]), o_moi)
	var duong: Array = fx.get("duong", []) as Array
	if duong.size() >= 2:
		var diem: Array[Vector3] = [tu]
		for i in range(1, duong.size() - 1):
			diem.append(_diem_o(int(duong[i])))
		diem.append(ban_co.vi_tri_dung(int(fx["tu"]), int(duong[duong.size() - 1])))
		ngu["duong"] = diem
	var hieu_ung_moi := _dung_hieu_ung(hinh.hieu_ung, ngu)
	ban_co.hieu_ung_dang_dien = hieu_ung_moi
	_dang_gui = false
	# Mọi máy: camera bàn nhìn vào chỗ đòn tới (hết hiệu ứng thì bàn trả camera theo lượt).
	if nguoi_den != null:
		ban_co.ban.camera_ban.theo(nguoi_den)
	elif int(fx.get("o", -1)) >= 0:
		ban_co.ban.camera_ban.theo(ban_co.ban.nut_o(int(fx["o"])))
	# Mục tiêu có Úp thúng đỡ đòn: hiện cái chắn đúng lúc đòn chạm.
	if bool(fx.get("chan", false)) and nguoi_den != null:
		hieu_ung_moi.cham.connect(_hien_khien.bind(den))


func _dung_hieu_ung(scene: PackedScene, ngu: Dictionary) -> HieuUng:
	var e := scene.instantiate() as HieuUng
	ban_co.ban.add_child(e)
	e.bat_dau(ngu)
	return e


func _hien_khien(vi_tri: Vector3) -> void:
	var hinh := danh_muc.tim("khien") if danh_muc != null else null
	if hinh == null or hinh.hieu_ung == null or ban_co.ban == null or not is_inside_tree():
		return
	_dung_hieu_ung(hinh.hieu_ung, {"tu": vi_tri, "den": vi_tri})


## Chỗ đòn tới: người bị trúng, ô được chọn, hoặc (trượt) điểm xa theo hướng ngắm.
func _diem_den(fx: Dictionary, mon: String, tu: Vector3, nguoi_den: Player) -> Vector3:
	if nguoi_den != null:
		return nguoi_den.global_position
	if int(fx.get("o", -1)) >= 0:
		return _diem_o(int(fx["o"]))
	var huong: Array = fx.get("huong", []) as Array
	if huong.size() == 3 and VatPham.la_ngam(mon):
		var phang := Vector3(float(huong[0]), 0.0, float(huong[2]))
		if phang.length_squared() > 0.0001:
			var tam := VatPham.tam(mon) * VatPham.MET_MOI_O
			return tu + phang.normalized() * (tam if tam > 0.0 else TAM_TRUOT_VO_HAN)
	return tu


# ───────────────────────────── master ─────────────────────────────


@rpc("any_peer", "call_local")
func _net_xin_dung_do(id: int, chi_so: int, json: String) -> void:
	if not NetManager.is_master() or not ban_co.den_luot_dung_do(id):
		return
	var tt := ban_co.tt
	var k := LuatBan.khoa(id)
	if not LuatDo.ly_do_khong_dung(tt, k, chi_so).is_empty():
		return
	var raw = JSON.parse_string(json)
	if not (raw is Dictionary):
		return
	var mon := str((tt["do"] as Dictionary)[k][chi_so])
	var du_lieu := {}
	match VatPham.nham(mon):
		VatPham.Nham.TIA, VatPham.Nham.NON:
			var trung = _ai_trung(id, mon, raw)
			if trung == null:
				return
			du_lieu["muc_tieu"] = str(trung)
		VatPham.Nham.CHON_NGUOI:
			du_lieu["muc_tieu"] = str(raw.get("muc_tieu", ""))
		VatPham.Nham.CHON_O:
			du_lieu["o"] = int(raw.get("o", -1))
		VatPham.Nham.CHON_MINIGAME:
			du_lieu["minigame"] = str(raw.get("minigame", ""))
			if not quan_tro.co_tro(du_lieu["minigame"]):
				return
	if not LuatDo.muc_tieu_hop_le(tt, k, mon, du_lieu, ban_co.ban):
		return
	var km := str(du_lieu.get("muc_tieu", ""))
	# Úp thúng chỉ đỡ được một đòn: xét trước khi `dung` tiêu nó. Cần câu không kéo được người
	# có Úp thúng.
	var chan := not km.is_empty() and LuatBan.co_khien(tt, km)
	var keo_ve := mon == "can_cau" and not km.is_empty() and not chan
	var o_tam := int(du_lieu["o"]) if du_lieu.has("o") else int((tt["o"] as Dictionary).get(k, 0))
	var cac_o := LuatTanCong.vung_no(mon, o_tam, ban_co.ban)
	var ra := LuatDo.dung(tt, k, chi_so, du_lieu, ban_co.ban, ban_co.settings, ban_co.ten)
	# Mô tả hiệu ứng: mọi máy dựng cùng một scene từ đây (không dùng đồng hồ máy nào).
	# `trung` = đòn tới nơi trọn vẹn (bắn trượt, Cần câu bị Úp thúng chặn → false: clip "truot").
	var trung := not (VatPham.la_ngam(mon) and km.is_empty()) and (mon != "can_cau" or keo_ve)
	var fx := {"tu": id, "mon": mon, "den": int(km) if not km.is_empty() else -1,
			"o": int(du_lieu.get("o", -1)), "huong": raw.get("huong", []), "chan": chan,
			"trung": trung}
	if not cac_o.is_empty():
		fx["cac_o"] = cac_o
	var duong: Array = ra.get("duong", []) as Array
	if not duong.is_empty():
		fx["duong"] = duong
	ra["hieu_ung"] = fx
	ban_co.sau_khi_dung(id, "%s dùng %s: %s" % [ban_co.ten(k), VatPham.ten(mon), ra["su"]], ra)


## null = dữ liệu không hợp lệ; "" = trượt.
func _ai_trung(id: int, mon: String, raw: Dictionary) -> Variant:
	var goc_raw: Array = raw.get("goc", []) as Array
	var huong_raw: Array = raw.get("huong", []) as Array
	if goc_raw.size() != 3 or huong_raw.size() != 3:
		return null
	var goc := Vector3(float(goc_raw[0]), float(goc_raw[1]), float(goc_raw[2]))
	var huong := Vector3(float(huong_raw[0]), float(huong_raw[1]), float(huong_raw[2]))
	var nguoi := ban_co.nguoi(id)
	if nguoi == null or not goc.is_finite() or not huong.is_finite():
		return null
	if goc.distance_to(nguoi.global_position) > GOC_CACH_NGUOI_TOI_DA or huong.length_squared() < 0.9:
		return null
	huong = huong.normalized()
	var p: Player
	if VatPham.nham(mon) == VatPham.Nham.NON:
		p = NgamMucTieu.non(nguoi, goc, huong, VatPham.tam(mon))
	else:
		p = NgamMucTieu.tia(nguoi, goc, huong, VatPham.tam(mon))
	return "" if p == null else LuatBan.khoa(p.player_id())
