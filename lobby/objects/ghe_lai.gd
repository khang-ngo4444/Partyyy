class_name GheLai
extends CardSeat

## Ghế lái tàu Canopy Line: ngắm vào tàu, E để lái (W/S ga và phanh), Q để xuống.
## Kế thừa `CardSeat` để dùng lại cơ chế ngồi của Player; ai lái do `CanopyLine` giữ,
## master phân xử.
## Đặt làm con của `Car` (PathFollow3D) trong `CanopyLine`; `Hitbox` là sàn để đứng lên tàu.

## Chỗ ngồi (trên thùng hàng) và chỗ đứng khi xuống, hệ toạ độ xe.
const LECH_NGOI := Vector3(0.0, 1.0, 0.05)
const LECH_DUNG := Vector3(0.0, 1.05, 0.0)

var _tau: CanopyLine = null


func _ready() -> void:
	super()
	# Không thuộc bàn bài nào (`CardDealer` đọc `deck` của mọi ghế).
	deck = -1
	di_dong = true
	_tau = get_parent().get_parent() as CanopyLine


## Đọc người lái từ tàu mỗi khung; người lái thì gửi phím ga.
func _process(_delta: float) -> void:
	nguoi = _tau.lai_boi if _tau.lai_hop_le() else 0
	toi_dang_ngoi = nguoi != 0 and nguoi == NetManager.local_id()
	if toi_dang_ngoi:
		var dang_go := get_viewport().gui_get_focus_owner() is LineEdit
		_tau.dat_ga(0.0 if dang_go else signf(Input.get_axis("move_back", "move_forward")))
		_tag.text = "W/S CHAY  -  Q XUONG"
		_tag.modulate = Color("d9c98a")
	elif nguoi != 0:
		_tag.text = "CO NGUOI LAI"
		_tag.modulate = Color("8b8d98")
	else:
		_tag.text = "E - LAI TAU"
		_tag.modulate = Color("d9c98a")


func con_trong() -> bool:
	return nguoi == 0


func xin_ngoi() -> void:
	_tau.xin_lai()


func xin_dung_day() -> void:
	_tau.nha_lai()


## Ngồi quay mặt theo hướng tàu chạy, giữ thẳng đứng dù tàu nghiêng dốc.
func diem_ngoi() -> Transform3D:
	var truoc := global_basis.z
	truoc.y = 0.0
	return Transform3D(Basis.looking_at(truoc.normalized(), Vector3.UP), global_transform * LECH_NGOI)


## Xuống xe thì đứng trên thùng hàng, vẫn đi theo tàu.
func diem_dung_day() -> Vector3:
	return global_transform * LECH_DUNG


## Ngắm vào tàu thì viền cả model xe.
func vat_vien() -> Node3D:
	var xe := get_parent().get_node_or_null("Model") as Node3D
	return xe if xe != null else self


func loi_nhac() -> String:
	return "Đang lái tàu — [W/S] ga/phanh  ·  [Q] xuống  ·  [ESC] menu"
