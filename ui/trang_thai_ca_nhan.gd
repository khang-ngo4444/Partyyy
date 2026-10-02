class_name TrangThaiCaNhan
extends PanelContainer

## HUD riêng của máy này. Dù gói bàn chứa trạng thái chung để mô phỏng đồng bộ, giao diện
## chỉ tra đúng khóa `NetManager.local_id()` và không dựng dòng dữ liệu cho bất kỳ ai khác.

@onready var _mau: Label = %Mau
@onready var _thanh_mau: ProgressBar = %ThanhMau
@onready var _vang: Label = %Vang
@onready var _khien: Label = %Khien
@onready var _sung: Label = %Sung
@onready var _goi_y_sung: Label = %GoiYSung


func _ready() -> void:
	visible = false


func cap_nhat(tt: Dictionary) -> void:
	var k := LuatBan.khoa(NetManager.local_id())
	var bang_mau: Dictionary = tt.get("mau", {}) as Dictionary
	if not bang_mau.has(k):
		visible = false
		return
	visible = true

	var toi_da := maxi(int(tt.get("max_health", 10)), 1)
	var hien_tai := clampi(int(bang_mau.get(k, 0)), 0, toi_da)
	var tui: Array = (tt.get("do", {}) as Dictionary).get(k, []) as Array
	var so_khien := tui.count("khien")
	var so_sung := tui.count("sung_1_phat")

	_mau.text = "%d / %d" % [hien_tai, toi_da]
	_thanh_mau.max_value = toi_da
	_thanh_mau.value = hien_tai
	_vang.text = str(int((tt.get("tien", {}) as Dictionary).get(k, 0)))
	_khien.text = "x%d" % so_khien
	_sung.text = "x%d" % so_sung
	_goi_y_sung.visible = so_sung > 0
