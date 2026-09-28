extends MiniGameLan

## NHẶT QUÀ NÉ RÁC — chạy hết làn trong 60 giây. Quà +1, quà to +3, rác −1.
##
## Khuôn T4 thứ hai. Không ai chết, không ai bị hất — chỉ chạy và chọn.
##
## ## 0 gói tin
##
## Món nằm ở đâu là hàm thuần của hạt giống. Ai nhặt được món nào thì **mọi máy tự tính lấy**
## từ vị trí người chơi mà replicator đã gửi sẵn — giống hệt cách Bounding Blocks tự sơn lấy cả
## bàn cờ. Cả ván không thêm một byte nào.
##
## ## Mọi làn bày ĐÚNG một bố cục
##
## Cùng một danh sách món cho mọi làn. Khác bố cục thì người thắng chỉ là người bốc được làn dễ,
## và bảng xếp hạng mất hết ý nghĩa. Vì vậy `bo_cuc()` chỉ nhận hạt giống, không nhận chỉ số làn.
##
## ## Vì sao điểm được xuống âm
##
## Chặn ở 0 thì nửa sau ván người đang thua không còn lý do gì để né rác — cứ lao thẳng, nhặt
## hết, âm bao nhiêu cũng vẫn là 0. Cho âm thì mỗi món rác vẫn là một quyết định.

## Bao nhiêu món trên một làn.
const SO_MON := 64
## Món đầu tiên cách vạch xuất phát chừng này mét — chừa chỗ cho người chơi định thần.
const BAT_DAU_TU := 12.0
## Món cuối cùng nằm cách cuối làn chừng này mét.
const CHUA_CUOI := 20.0
## Món lệch trái/phải trong khoảng này. Làn rộng 10 m, trừ tường còn ~4,4 m mỗi bên.
const LECH_TOI_DA := 3.4
## Tỉ lệ từng loại: quà nhỏ, quà to, rác. Rác nhiều hơn quà to nên né mới là việc chính.
const TI_LE_QUA_TO := 0.18
const TI_LE_RAC := 0.34

@export var vat_pham_scene: PackedScene = null

## Món của từng làn: `_mon[i]` là mảng `VatPham` của làn thứ `i`.
var _mon: Array = []
## player_id -> điểm. Mọi máy cùng cộng; bảng của master là bảng chốt.
var _diem: Dictionary = {}


func _ready() -> void:
	super()
	ten = "NHẶT QUÀ NÉ RÁC"
	luat = "WASD chạy · chuột xoay người · quà +1 · quà to +3 · rác −1"
	giay_van = 60.0


func _dung_san() -> void:
	_mon.clear()
	_diem.clear()
	for id in _song:
		_diem[int(id)] = 0
	if san == null or vat_pham_scene == null:
		return
	var bo := bo_cuc(hat_giong)
	# Chỉ bày món ở làn ĐANG CÓ NGƯỜI. Bày đủ 8 làn là 512 `Area3D` cho một ván 4 người.
	for i in _ds_nguoi.size():
		var cua_lan: Array[VatPham] = []
		for m in bo:
			var v := vat_pham_scene.instantiate() as VatPham
			san.add_child(v)
			v.dat(int(m["loai"]))
			v.global_position = san.global_position + Vector3(
					x_lan(i) + float(m["lech"]), 1.0, -float(m["xa"]))
			cua_lan.append(v)
		_mon.append(cua_lan)


func _luat_moi_nhip() -> void:
	ghi_quang_duong()
	for p: Player in get_tree().get_nodes_in_group("players"):
		var i := lan_cua(p.player_id())
		if i < 0 or i >= _mon.size():
			continue
		for v: VatPham in _mon[i]:
			if v.da_nhat or not v.overlaps_body(p):
				continue
			v.nhat()
			_diem[p.player_id()] = int(_diem.get(p.player_id(), 0)) + v.diem()


## Ghi đè: làn có tường hai bên, không ai rơi và không có gì giết người.
func _toi_thua() -> bool:
	return false


## Xếp hạng theo điểm, không theo quãng đường như mặc định của khuôn T4.
func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var xep: Array = []
	for id in _diem:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool: return int(_diem[a]) > int(_diem[b]))
	Fusion.rpc(_net_xep_hang, xep)


# ───────────────────────── luật: hàm thuần, kiểm bằng assert ─────────────────────────

## Bố cục món của MỘT làn, suy ra từ hạt giống. Mọi làn dùng chung bố cục này.
static func bo_cuc(giong: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = giong
	var ds: Array = []
	var het := MiniGameLan.DAI_LAN - CHUA_CUOI
	var buoc := (het - BAT_DAU_TU) / float(SO_MON - 1)
	for i in SO_MON:
		var r := rng.randf()
		var loai := VatPham.QUA_NHO
		if r < TI_LE_RAC:
			loai = VatPham.RAC
		elif r < TI_LE_RAC + TI_LE_QUA_TO:
			loai = VatPham.QUA_TO
		ds.append({
			"xa": BAT_DAU_TU + buoc * i,
			"lech": rng.randf_range(-LECH_TOI_DA, LECH_TOI_DA),
			"loai": loai,
		})
	return ds
