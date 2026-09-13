class_name Pickable
extends RigidBody3D

## Vat nhat duoc: quan co, xuc xac, bong ro, phi tieu, la bai. Tat ca la RigidBody3D THAT.
##
## MASTER SO HUU VINH VIEN va la may QUYET DINH vat bay di dau. Fusion ban Godot KHONG co
## NetworkRigidBody3D rieng: RigidBody3D lam goc + FusionSharedReplicator con, `root_replication_mode
## = Auto`. May khac VAN CHAY vat ly tai cho, replicator nan ban sao ve trang thai master
## (`root_interpolation_mode = Forecast` + lo xo, dat trong .tscn cua tung vat).
##
## `root_forecast_gravity = false` trong .tscn la BAT BUOC. Mac dinh `true` + `root_max_forecast_time
## = 0.25`: may khac du doan roi tu do 0.25 s ca voi vat DANG NAM YEN — do duoc moi vat nam tren
## may khac lun 0.32 m (= 1/2 * 9.8 * 0.25^2), quan co va xuc xac xuyen xuong duoi san.
##
## Dung owner_mode mac dinh (TRANSACTION) chu KHONG dung MASTER_CLIENT: MASTER_CLIENT lam hong
## viec replicate vi tri (da do: may khac khong nhan duoc vi tri moi).
##
## Khong chuyen quyen so huu khi nhat: nguoi choi gui RPC xin cam, master gan `holder_id`, roi
## chinh master dieu khien vat (vi tri + goc nhin nguoi choi da replicate san).
##
## HAI KIEU CAM:
##   - SIEU LINH (mac dinh): vat lo lung truoc mat, VAN LA VAT LY — va vao ban, bi tuong chan,
##     vat nang tre hon. Master keo no bang mot lo xo mem co gioi han luc (xem `_keo_sieu_linh`).
##   - TRONG TAY (`sieu_linh = false`): dung cu can nam dung cho — bua, gay golf, phi tieu. Tat
##     vat ly, dat thang theo camera nguoi cam.
##
## Trang thai than vat ly SUY RA moi nhip tu (co ai cam, co bi khoa) — khong bat/tat rai rac o
## tung cho, nen khong co duong nao quen bat lai trong luc.

## Lop va cham cua vat nhat duoc. Nguoi choi nam lop rieng (Player.LOP_NGUOI) va hai ben khong
## va nhau: di qua ban co khong xo do quan, quan co khong chan chan.
const LOP_VAT := 1 << 3
const LOP_THE_GIOI := 1
## Duoi do cao nay coi nhu roi khoi phong — tra ve cho de san.
const DAY_VUC := -5.0
## Dung yen tren cao qua chung nay giay (ket tren noc bang ro, tren tu) thi tra ve cho cu.
const CAO_KET := 1.5
const GIAY_KET := 2.0

## Ai dang cam. 0 = khong ai. Chi master ghi.
@export var holder_id: int = 0
## Cho cam kieu TRONG TAY, trong he toa do CAMERA nguoi cam: +X phai, +Y len, -Z phia truoc.
@export var cam_offset := Vector3(0.27, -0.24, -0.6)
## 0 = xoay khop ngay theo camera. > 0 = xoay duoi theo camera voi toc do nay.
@export var do_tre_xoay := 0.0

## Cam kieu SIEU LINH. Tay la mot LO XO MEM CO GIOI HAN LUC, theo "Soft Constraints: Reinventing
## the Spring" (Erin Catto, GDC 2011) va mouse joint cua Box2D: do cung cho bang TAN SO (Hz) va
## TI LE TAT DAN thay vi he so tho, nen vat nang nhe deu bam tay cung mot kieu — chi khac o gioi
## han luc. Tat cho dung cu phai nam dung trong tay.
@export var sieu_linh := true
## Tan so lo xo. Cao = bam sat hon. Box2D: giu duoi mot nua nhip vat ly (60 Hz -> duoi 30 Hz).
@export var sieu_linh_hz := 5.0
## 1 = tat dan toi han: toi dich khong vuot qua, khong rung. Duoi 1 thi nay lac lu.
@export var sieu_linh_tat_dan := 1.0
## Luc tay toi da = so nay x trong luong vat. Duoi 1 thi khong nhac noi.
@export var sieu_linh_luc := 4.0
## Vat lo lung cach mat nguoi cam chung nay met, hoi thap duoi tam nhin.
@export var sieu_linh_xa := 1.3
## Ham xoay trong luc lo lung, de vat khong quay tit mai sau moi cu va.
@export var sieu_linh_ham_xoay := 4.0

## Chi so vat ly. Lop con dat trong `_init`.
@export var nay := 0.2
@export var ma_sat := 0.6
## Ham khi dang cham mat (lan, truot). Tren khong LUON bang 0 — nem xa bao nhieu la do luc tay.
@export var ham_mat_dat := 0.8
@export var ham_xoay := 0.5

## Vat dang KHOA vat ly dong: la bai nam trong o nha cai, phi tieu dang cam tren bia. Replicate —
## may khac cung phai khoa, khong thi ban sao tu roi khoi bia roi bi nan nguoc lai.
@export var dinh_co_dinh := false
## Master ghi luc tha: ai tha, va nguoi do dung dau (bong ro tinh 2 hay 3 diem).
var nguoi_nem := 0
var cho_nem := Vector3.ZERO
## Cho de san. Roi khoi phong / ket tren cao thi vat ve day. Chua ai gan thi lay cho luc sinh ra.
var cho_mac_dinh := Vector3.ZERO

@onready var sync: FusionSharedReplicator = $Replicator

## Goc xoay dang duoi theo camera, giu RIENG o may nay. Khong doc lai tu `global_transform`:
## o may nguoi cam (khong phai master), replicator ghi de goc xoay bang gia tri cu mot nhip mang.
var _xoay_tay := Basis.IDENTITY
## Dang duoi theo tay ai (0 = khong). Doi nguoi cam thi bat dau lai tu dung huong camera.
var _tay_cua := 0
var _dung_yen := 0.0


func _ready() -> void:
	add_to_group("pickable")
	# Chay SAU replicator (priority 0). O may nguoi cam, vat duoc dat theo camera cua chinh ho;
	# chay truoc thi replicator ghi de bang vi tri cu tu mang va vat giat lui moi nhip.
	process_priority = 1
	continuous_cd = true
	# REPLACE chu khong COMBINE: COMBINE cong them ham 0.1 cua Project Settings, vat mat toc do
	# giua khong trung (da do: 4/4 cu nem ro hut).
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp = ham_xoay
	var vat_lieu := PhysicsMaterial.new()
	vat_lieu.bounce = nay
	vat_lieu.friction = ma_sat
	physics_material_override = vat_lieu
	# Can biet dang cham mat hay dang bay de bat ham (xem `_physics_process`).
	contact_monitor = true
	max_contacts_reported = 4
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	# Khoa cho toi nhip vat ly dau tien — luc do moi biet chac may nay co phai master khong.
	freeze = true
	collision_layer = LOP_VAT
	collision_mask = LOP_THE_GIOI | LOP_VAT


## Nguoi choi goi o may cua ho. Chi la loi de nghi — master moi quyet.
func request_pick() -> void:
	if holder_id != 0:
		return
	Fusion.rpc(_net_pick, NetManager.local_id())


## Tha tay: vat roi tu do ngay tai cho dang cam.
func drop() -> void:
	if holder_id != NetManager.local_id():
		return
	Fusion.rpc(_net_drop)


## Nem theo huong nhin voi toc do `toc_do` (m/s). Huong va luc la INPUT cua nguoi choi nen may
## ho gui di; chi master dat van toc cho than vat ly.
func throw(direction: Vector3, toc_do: float) -> void:
	if holder_id != NetManager.local_id():
		return
	Fusion.rpc(_net_throw, direction, toc_do)


@rpc("any_peer", "call_local")
func _net_pick(by_id: int) -> void:
	# Chi master xu ly. Hai nguoi xin cung luc thi RPC toi master theo thu tu — nguoi sau thay
	# `holder_id` da khac 0 va bi tu choi. Khong co tranh chap.
	if not sync.has_authority() or holder_id != 0:
		return
	holder_id = by_id
	dinh_co_dinh = false
	_khi_duoc_nhat()


@rpc("any_peer", "call_local")
func _net_throw(direction: Vector3, toc_do: float) -> void:
	if not sync.has_authority() or holder_id == 0:
		return
	_tha(direction.normalized() * toc_do)


@rpc("any_peer", "call_local")
func _net_drop() -> void:
	if not sync.has_authority() or holder_id == 0:
		return
	# Giu nguyen da dang co: vat sieu linh dang bay ma buong tay thi bay tiep theo quan tinh. Vat
	# cam TRONG TAY dang khoa nen van toc san la 0 — roi thang xuong nhu truoc.
	_tha(linear_velocity)


## Master tha vat voi mot van toc. Mo khoa than vat ly NGAY (khong doi nhip sau) de van toc co
## tac dung trong nhip nay.
func _tha(van_toc: Vector3) -> void:
	nguoi_nem = holder_id
	var p := _find_player(holder_id)
	cho_nem = p.global_position if p != null else global_position
	holder_id = 0
	_mo_khoa()
	sleeping = false
	angular_velocity = Vector3.ZERO
	linear_velocity = van_toc
	_khi_bat_dau_bay()


func _process(delta: float) -> void:
	# Vat sieu linh do VAT LY dua di (xem `_keo_sieu_linh`), khong dat theo tay.
	if sieu_linh:
		_tay_cua = 0
		return
	if not sync.has_authority():
		# May cua NGUOI DANG CAM: tu dat vat theo camera cua chinh minh moi frame, khong doi
		# master. May khac thay vi tri master tinh bang CUNG cong thuc (Player.diem_cam).
		if holder_id != 0 and holder_id == NetManager.local_id():
			_theo_tay(delta)
		else:
			_tay_cua = 0
		return
	if holder_id == 0:
		_tay_cua = 0
		return
	if not _theo_tay(delta):
		# Nguoi cam da roi phong — tha roi tu do tai cho.
		_tha(Vector3.ZERO)


func _physics_process(delta: float) -> void:
	var la_master := sync.has_authority()
	if la_master and cho_mac_dinh == Vector3.ZERO:
		cho_mac_dinh = global_position
	if holder_id != 0 and sieu_linh:
		# Lo lung: VAN LA VAT LY DONG, van va cham. May khac thay no bay y nhu vat dang bay.
		_mo_khoa()
		linear_damp = 0.0
		angular_damp = sieu_linh_ham_xoay
		if la_master:
			_keo_sieu_linh()
		return
	angular_damp = ham_xoay
	if holder_id != 0 or dinh_co_dinh:
		_khoa(holder_id != 0)
		return
	_mo_khoa()
	# Tren khong khong ham; cham mat moi ham cho vat khoi lan mai.
	linear_damp = ham_mat_dat if get_contact_count() > 0 else 0.0
	if not la_master:
		return

	if global_position.y < DAY_VUC:
		_ve_cho_cu()
		return
	if global_position.y > CAO_KET and linear_velocity.length() < 0.05:
		_dung_yen += delta
		if _dung_yen > GIAY_KET:
			_ve_cho_cu()
			return
	else:
		_dung_yen = 0.0
	_khi_bay_vat_ly(delta)


## Tay sieu linh (chi master). Lo xo - giam chan dat theo tan so va ti le tat dan, nhan khoi
## luong de do cung KHONG phu thuoc vat nang hay nhe:
##     w = 2 pi f          F = m (w^2 * lech  -  2 * zeta * w * v)
## roi CAT o `sieu_linh_luc` lan trong luong: vat nang bi tuong/ban chan thi tay khong du luc
## xuyen qua, va vat cham dich cham hon mot chut. Trong luc van tac dung, nen vat dung yen xe
## xuong g / w^2 (5 Hz: khoang 1 cm) — nhu nang bang tay that.
##
## Dat LUC (apply_central_force) chu khong ghi thang `linear_velocity`: tai lieu Godot noi ghi
## thang trang thai moi nhip thi may vat ly khong mo phong dung duoc; va cong thuc gan van toc
## `v = K * lech - C * v` doi dau moi nhip khi C >= 1.
##
## ponytail: chua tinh van toc cua diem giu (Catto co). Di nhanh thi vat tre sau ~2*zeta*v/w
## (chay 6 m/s, 5 Hz: ~0.38 m). Them van toc diem giu vao so hang giam chan neu can bam sat hon.
func _keo_sieu_linh() -> void:
	var p := _find_player(holder_id)
	if p == null:
		_tha(linear_velocity)       # nguoi cam roi phong: buong tay, vat bay tiep
		return
	var dich := p.diem_cam(Vector3(0.0, -0.15, -sieu_linh_xa)).origin
	var w := TAU * sieu_linh_hz
	var luc := mass * ((dich - global_position) * w * w
			- linear_velocity * 2.0 * sieu_linh_tat_dan * w)
	var trong_luc := maxf(get_gravity().length(), 9.8)
	sleeping = false
	apply_central_force(luc.limit_length(sieu_linh_luc * mass * trong_luc))


func _mo_khoa() -> void:
	if not freeze:
		return
	freeze = false
	collision_layer = LOP_VAT
	collision_mask = LOP_THE_GIOI | LOP_VAT


## Dang cam TRONG TAY thi tat ca va cham: mot vat vo hinh truoc mat nguoi cam se huc do moi thu
## no di qua.
func _khoa(dang_cam: bool) -> void:
	if not freeze:
		freeze = true
	var lop := 0 if dang_cam else LOP_VAT
	if collision_layer != lop:
		collision_layer = lop
		collision_mask = 0 if dang_cam else (LOP_THE_GIOI | LOP_VAT)


func _ve_cho_cu() -> void:
	_dung_yen = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = Transform3D(Basis.IDENTITY, cho_mac_dinh)


## Dat vat vao tay nguoi dang cam: truoc camera cua ho, lech `cam_offset`, xoay theo huong nhin.
func _theo_tay(delta: float) -> bool:
	var p := _find_player(holder_id)
	if p == null:
		return false
	var dich := p.diem_cam(cam_offset)
	if _tay_cua != holder_id or do_tre_xoay <= 0.0:
		_xoay_tay = dich.basis
		_tay_cua = holder_id
	else:
		_xoay_tay = _xoay_tay.slerp(dich.basis, clampf(delta * do_tre_xoay, 0.0, 1.0))
	global_transform = Transform3D(_xoay_tay, dich.origin)
	return true


## Lop con goi sau khi dung xong hinh. Moi vat MOT hinh va cham, dat lai moi lan hinh doi.
func _dat_hinh(hinh: Shape3D, vi_tri := Vector3.ZERO) -> void:
	if hinh == null:
		return
	var cs := get_node_or_null("HinhVaCham") as CollisionShape3D
	if cs == null:
		cs = CollisionShape3D.new()
		cs.name = "HinhVaCham"
		add_child(cs)
	cs.shape = hinh
	cs.position = vi_tri


## Hinh loi da dung, theo khoa (loai quan + goc xoay). Moi loai chi dung MOT lan cho ca phong.
static var _hinh_da_dung := {}
## Toi da chung nay diem dua vao hinh loi — may vat ly tu bao loi tu cac diem do.
const DIEM_LOI_TOI_DA := 256


## Hinh loi (convex) bao moi luoi duoi `goc`, tinh trong he toa do cua vat. Cho vat hinh la
## (quan co vua): hop chu nhat thi quan nga khong dung dang.
##
## KHONG dung `Mesh.create_convex_shape()`: do duoc 64–119 ms MOI model (5–14 nghin dinh). 32 quan
## cung sinh ra la chan luong chinh 6.9 s — Photon khong duoc phuc vu, hang doi goi den day (canh
## bao 1035) va may vao sau bi ngat (1040). Lay thua dinh, de may vat ly tu bao loi, va nho lai.
##
## Bo qua luoi dang cho xoa (dung lai hinh trong cung frame) va vo sang highlight ("vien_ngam").
func _hinh_loi_tu_luoi(goc: Node3D, khoa: String) -> ConvexPolygonShape3D:
	if _hinh_da_dung.has(khoa):
		return _hinh_da_dung[khoa]
	var diem := PackedVector3Array()
	for m in goc.find_children("*", "MeshInstance3D", true, false):
		var luoi := m as MeshInstance3D
		if luoi.mesh == null or luoi.is_queued_for_deletion() or luoi.is_in_group("vien_ngam"):
			continue
		var t := _bien_doi_toi_goc(luoi)
		for mat in luoi.mesh.get_surface_count():
			for p in luoi.mesh.surface_get_arrays(mat)[Mesh.ARRAY_VERTEX]:
				diem.append(t * p)
	if diem.is_empty():
		return null
	var buoc := maxi(1, ceili(diem.size() / float(DIEM_LOI_TOI_DA)))
	var gon := PackedVector3Array()
	for i in range(0, diem.size(), buoc):
		gon.append(diem[i])
	var hinh := ConvexPolygonShape3D.new()
	hinh.points = gon
	_hinh_da_dung[khoa] = hinh
	return hinh


func _bien_doi_toi_goc(n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var x: Node = n
	while x != null and x != self:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t


## Cac moc cho lop con. Chi chay tren master.
func _khi_duoc_nhat() -> void:
	pass


func _khi_bat_dau_bay() -> void:
	pass


func _khi_bay_vat_ly(_delta: float) -> void:
	pass


func _find_player(player_id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.player_id() == player_id:
			return p
	return null
