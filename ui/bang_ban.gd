extends VBoxContainer

## Bảng trạng thái bàn party ở góc phải: lượt của ai, máu / chìa / cốc / đồ của từng người,
## và chuyện vừa xảy ra.
##
## CHỈ HIỂN THỊ. Nghe một tín hiệu, đổ chữ ra, hết. Không đọc thẳng vào `PhaBanCo`, không giữ
## trạng thái riêng — trạng thái duy nhất là gói vừa nhận.

@onready var _luot: Label = $Luot
@onready var _chon_huong: Label = $ChonHuong
@onready var _bang: RichTextLabel = $Bang
@onready var _su_kien: Label = $SuKien
var _dong_luot := "—"


func _ready() -> void:
	visible = false


## ⚠️ Khoá của mọi bảng theo người chơi là CHUỖI — gói tới từ `JSON.parse_string()`. Đọc bằng
## số nguyên thì tra không thấy, trả về mặc định, và bảng hiện ai cũng 0 máu.
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
		dong.append(_mot_dong(tt, int(id), id_luot, int(tt.get("can_coc", 0))))
	_bang.text = "\n".join(dong)

	# `het_vong` là cờ nội bộ cho `main.gd`, không phải câu để người chơi đọc.
	var su := str(tt.get("su_kien", ""))
	_su_kien.text = "" if su == "het_vong" else su


func cap_nhat_chon_huong(noi_dung: String) -> void:
	_chon_huong.text = noi_dung
	_chon_huong.visible = not noi_dung.is_empty()
	_luot.text = "ĐÃ TUNG XÚC XẮC — CHỌN HƯỚNG" if _chon_huong.visible else _dong_luot


## `can` = số cốc để thắng. 0 nghĩa là ván chơi vô hạn, khi đó không hiện mẫu số — "cốc 2/0"
## thì còn khó hiểu hơn là không ghi gì.
func _mot_dong(tt: Dictionary, id: int, id_luot: int, can: int) -> String:
	var k := LuatBan.khoa(id)
	var tui: Array = _bang_cua(tt, "do").get(k, [])
	var ten_do := PackedStringArray()
	for i in tui.size():
		ten_do.append("[%d] %s" % [i + 1, LuatBan.TEN_DO.get(str(tui[i]), str(tui[i]))])
	var coc := int(_bang_cua(tt, "coc").get(k, 0))
	return "%s %s — máu %d/%d · chìa %d · cốc %s · %s" % [
		"▶" if id == id_luot else "  ",
		Player.ten_theo_id(get_tree(), id),
		int(_bang_cua(tt, "mau").get(k, 0)), LuatBan.MAU_TOI_DA,
		int(_bang_cua(tt, "chia").get(k, 0)),
		str(coc) if can <= 0 else "%d/%d" % [coc, can],
		" · ".join(ten_do) if ten_do.size() > 0 else "tay không",
	]


func _bang_cua(tt: Dictionary, ten: String) -> Dictionary:
	return tt.get(ten, {}) as Dictionary
