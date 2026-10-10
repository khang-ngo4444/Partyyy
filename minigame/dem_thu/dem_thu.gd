extends MiniGame3D

## ĐẾM THÚ — thú chạy ngang đồng cỏ; mỗi vòng đếm một loại rồi chốt con số, đúng +1.
## Bằng điểm thì ai chốt nhanh hơn đứng trên. Đàn thú là hàm của hạt giống và `gio()`;
## mỗi người gửi một gói mỗi vòng.

const LOAI := ["ga", "canh_cut", "heo"]
const TEN_LOAI := ["GÀ", "CHIM CÁNH CỤT", "HEO"]
const SO_VONG := 3

## Một vòng: đọc câu hỏi → đàn chạy → chốt đáp án.
const GIAY_HOI := 3.0
const GIAY_CHAY := 10.0
const GIAY_TRA_LOI := 6.0
const GIAY_VONG := GIAY_HOI + GIAY_CHAY + GIAY_TRA_LOI

## Thú xuất phát ở mép phải, chạy trong dải z.
const X_DAU := 15.0
const Z_LAN := 5.0
const TOC_MIN := 5.0
const TOC_MAX := 8.5

## Số con phải đếm và số con nhiễu mỗi vòng.
const DEM_MIN := 4
const DEM_MAX := 11
const NHIEU_MIN := 5
const NHIEU_MAX := 12
const DAP_AN_TOI_DA := 30

## Theo thứ tự `LOAI`.
@export var thu_scenes: Array[PackedScene] = []

var _lich: Array = []
var _thu: Array[ConThu] = []
var _da_tha := {}

## id -> [số câu đúng, tổng giây chốt].
var _diem := {}
var _dem := 0
var _vong_da_chot := -1
var _ds_nguoi: Array = []

@onready var _cau_hoi: Label = %CauHoi
@onready var _so_dem: Label = %SoDem
@onready var _goi_y: Label = %GoiY
@onready var _lop: CanvasLayer = $Lop


func _ready() -> void:
	super()
	ten = "ĐẾM THÚ"
	luat = "Đếm đúng loại thú được hỏi · W/S chỉnh số · Space chốt · đúng +1, chốt nhanh xếp trên"
	# +1 s để đáp án tự gửi cuối vòng chót kịp tới master.
	giay_van = GIAY_VONG * SO_VONG + 1.0
	_lop.visible = false


func bat_dau(nguoi_choi: Array, giong: int) -> void:
	_ds_nguoi = nguoi_choi.duplicate()
	_diem.clear()
	for id in nguoi_choi:
		_diem[int(id)] = [0, 0.0]
	_dem = 0
	_vong_da_chot = -1
	super(nguoi_choi, giong)
	_lop.visible = true
	_giau_nguoi(true)


func dung_som() -> void:
	_giau_nguoi(false)
	_lop.visible = false
	super()


## Giấu hình mọi người; khoá di chuyển (W/S dùng để chỉnh số).
func _giau_nguoi(giau: bool) -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		p.model_root.visible = not giau
		p.name_tag.visible = not giau
		if giau and p.is_mine:
			p.khoa_di_chuyen = true


func _dung_san() -> void:
	_lich = lich(hat_giong)
	_thu.clear()
	_da_tha.clear()


## Đứng sau camera, ngoài đồng cỏ.
func _cho_vao(i: int, _tong: int) -> Vector3:
	return Vector3(i * 1.5, 0.5, 22.0)


## Không ai bị loại.
func _toi_thua() -> bool:
	return false


func so_con_song() -> int:
	return _diem.size()


func _luat_moi_nhip() -> void:
	var t := gio()
	var vong := mini(int(t / GIAY_VONG), SO_VONG - 1)
	var pha := t - vong * GIAY_VONG
	var m: Dictionary = _lich[vong]
	for i in (m["thu"] as Array).size():
		var con: Dictionary = m["thu"][i]
		var khoa := "%d_%d" % [vong, i]
		if not _da_tha.has(khoa) and t >= float(con["t0"]):
			_da_tha[khoa] = true
			_tha(con)
	var con_lai: Array[ConThu] = []
	for c in _thu:
		if c.dat_luc(t):
			con_lai.append(c)
		else:
			c.queue_free()
	_thu = con_lai
	_ve_bang(vong, pha, m)
	# Hết giờ mà chưa chốt thì tự gửi con số đang chỉnh.
	if pha >= GIAY_VONG - 0.3 and _vong_da_chot < vong:
		_chot(vong, GIAY_TRA_LOI)


func _ve_bang(vong: int, pha: float, m: Dictionary) -> void:
	var loai: String = TEN_LOAI[int(m["hoi"])]
	if pha < GIAY_HOI:
		_cau_hoi.text = "Vòng %d/%d — hãy đếm số %s!" % [vong + 1, SO_VONG, loai]
		var truoc := "" if vong == 0 else "Vòng trước: đáp án %d" % int(_lich[vong - 1]["dap_an"])
		_so_dem.text = ""
		_goi_y.text = truoc
	elif pha < GIAY_HOI + GIAY_CHAY:
		_cau_hoi.text = "Đếm số %s..." % loai
		_so_dem.text = ""
		_goi_y.text = ""
	else:
		_cau_hoi.text = "Có bao nhiêu %s?" % loai
		_so_dem.text = "◀  %d  ▶" % _dem
		_goi_y.text = ("Đã chốt — chờ người khác" if _vong_da_chot >= vong
				else "W/S chỉnh số · Space chốt (%.0f s)" % (GIAY_VONG - pha))


func _unhandled_input(event: InputEvent) -> void:
	if not _chay:
		return
	var t := gio()
	var vong := mini(int(t / GIAY_VONG), SO_VONG - 1)
	var pha := t - vong * GIAY_VONG
	if pha < GIAY_HOI + GIAY_CHAY or _vong_da_chot >= vong:
		return
	if event.is_action_pressed("move_forward") or event.is_action_pressed("move_right"):
		_dem = mini(_dem + 1, DAP_AN_TOI_DA)
	elif event.is_action_pressed("move_back") or event.is_action_pressed("move_left"):
		_dem = maxi(_dem - 1, 0)
	elif event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		_chot(vong, pha - GIAY_HOI - GIAY_CHAY)
	else:
		return
	get_viewport().set_input_as_handled()


func _chot(vong: int, giay: float) -> void:
	_vong_da_chot = vong
	Fusion.rpc(_net_tra_loi, NetManager.local_id(), vong, _dem, giay)
	_dem = 0


## Ghi con số chốt; mỗi người mỗi vòng tính một lần.
@rpc("any_peer", "call_local")
func _net_tra_loi(id: int, vong: int, so: int, giay: float) -> void:
	if not _diem.has(id) or vong < 0 or vong >= _lich.size():
		return
	var da: Array = _diem[id]
	if da.size() > 2 and int(da[2]) >= vong:
		return
	var dung := int(da[0]) + (1 if so == int(_lich[vong]["dap_an"]) else 0)
	_diem[id] = [dung, float(da[1]) + clampf(giay, 0.0, GIAY_TRA_LOI), vong]


func _tha(con: Dictionary) -> void:
	var i := int(con["loai"])
	if san == null or i >= thu_scenes.size() or thu_scenes[i] == null:
		return
	var c := thu_scenes[i].instantiate() as ConThu
	san.add_child(c)
	c.chay(X_DAU, float(con["z"]), float(con["toc"]), float(con["t0"]))
	c.dat_luc(gio())
	_thu.append(c)


## Lịch cả ván: mỗi vòng {hoi, dap_an, thu: [{loai, z, toc, t0}]}; thú chạy hết trước pha chốt.
static func lich(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ra: Array = []
	for vong in SO_VONG:
		var hoi := rng.randi_range(0, LOAI.size() - 1)
		var dap_an := rng.randi_range(DEM_MIN, DEM_MAX)
		var ds: Array = []
		for _j in dap_an:
			ds.append(hoi)
		for _j in rng.randi_range(NHIEU_MIN, NHIEU_MAX):
			ds.append((hoi + rng.randi_range(1, LOAI.size() - 1)) % LOAI.size())
		var bat_dau := vong * GIAY_VONG + GIAY_HOI
		var thu: Array = []
		for loai in ds:
			var toc := rng.randf_range(TOC_MIN, TOC_MAX)
			var het := (X_DAU - ConThu.X_HET) / toc
			thu.append({"loai": loai, "z": rng.randf_range(-Z_LAN, Z_LAN), "toc": toc,
					"t0": bat_dau + rng.randf_range(0.0, maxf(GIAY_CHAY - het, 0.0))})
		ra.append({"hoi": hoi, "dap_an": dap_an, "thu": thu})
	return ra


# ─── điểm ───


func diem_cua(id: int) -> float:
	return float(_diem[id][0]) if _diem.has(id) else NAN


func chu_diem(id: int) -> String:
	return "%d/%d" % [int(_diem[id][0]), SO_VONG] if _diem.has(id) else ""


func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _diem:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool:
		if int(_diem[a][0]) != int(_diem[b][0]):
			return int(_diem[a][0]) > int(_diem[b][0])
		return float(_diem[a][1]) < float(_diem[b][1]))
	Fusion.rpc(_net_xep_hang, xep)
