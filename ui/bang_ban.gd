extends VBoxContainer

## Bảng góc phải ở bàn party: lượt của ai và chuyện vừa xảy ra. Chỉ vẽ.

signal thue_da_chon(loai: int)

var _dong_luot := "—"

@onready var _luot: Label = $Luot
@onready var _chon_huong: Label = $ChonHuong
@onready var _menu_thue: PanelContainer = $MenuThue
@onready var _bang: RichTextLabel = $Bang
@onready var _su_kien: Label = $SuKien


func _ready() -> void:
	visible = false
	var cac_nut: Array[Button] = [
		$MenuThue/NoiDung/CacLuaChon/Dat,
		$MenuThue/NoiDung/CacLuaChon/Mau,
		$MenuThue/NoiDung/CacLuaChon/Tien,
		$MenuThue/NoiDung/CacLuaChon/TrangBi,
	]
	for i in cac_nut.size():
		cac_nut[i].pressed.connect(_chon_thue.bind(i))


## ⚠️ Khoá các bảng theo người chơi là chuỗi (gói từ JSON).
func cap_nhat(tt: Dictionary) -> void:
	var thu_tu: Array = tt.get("thu_tu", [])
	if thu_tu.is_empty() or int(tt.get("luot", -1)) < 0:
		visible = false
		return
	visible = true

	var id_luot := int(thu_tu[int(tt["luot"])])
	var nhac := "   —  Space tung xúc xắc" if id_luot == NetManager.local_id() else ""
	_dong_luot = "Lượt: %s%s" % [Player.ten_theo_id(get_tree(), id_luot), nhac]
	_luot.text = _dong_luot

	var dong := PackedStringArray()
	for id in thu_tu:
		dong.append("%s %s" % ["▶" if int(id) == id_luot else "  ",
				Player.ten_theo_id(get_tree(), int(id))])
	_bang.text = "\n".join(dong)

	# `het_vong` là cờ nội bộ, không hiện.
	var su := str(tt.get("su_kien", ""))
	_su_kien.text = "" if su == "het_vong" else su
	var thue: Dictionary = tt.get("thue", {}) as Dictionary
	if not thue.is_empty() and int(thue.get("chu", -1)) == NetManager.local_id():
		_menu_thue.visible = true
	else:
		_menu_thue.visible = false


func _chon_thue(loai: int) -> void:
	_menu_thue.visible = false
	thue_da_chon.emit(loai)


func cap_nhat_chon_huong(noi_dung: String, tieu_de := "ĐÃ TUNG XÚC XẮC — CHỌN HƯỚNG") -> void:
	_chon_huong.text = noi_dung
	_chon_huong.visible = not noi_dung.is_empty()
	_luot.text = tieu_de if _chon_huong.visible else _dong_luot
