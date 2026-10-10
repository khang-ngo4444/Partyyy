class_name DauHieuBan
extends Node3D

## Bể node rào/bẫy/neo đặt sẵn trong `dau_hieu_ban.tscn` (mỗi loại đủ cho số người tối đa).
## Tên con quyết định loại: `Rao*`, `Bay*`, `Neo*`.

## khoá ("rao:ô", "bay:ô", "neo:người") -> node đang dùng.
var _dang_dung := {}


## `can`: {khoá: vị trí}. Khoá mới lấy node rảnh, khoá đã mất thì cất node.
func hien(can: Dictionary) -> void:
	for khoa in _dang_dung.keys():
		if not can.has(khoa):
			(_dang_dung[khoa] as DauHieuO).an()
			_dang_dung.erase(khoa)
	for khoa in can:
		var n := _dang_dung.get(khoa) as DauHieuO
		if n == null:
			n = _ranh(str(khoa).get_slice(":", 0))
			if n == null:
				continue
			_dang_dung[khoa] = n
		n.dat(can[khoa])


func _ranh(loai: String) -> DauHieuO:
	var dang := _dang_dung.values()
	for c in get_children():
		if c is DauHieuO and str(c.name).to_lower().begins_with(loai) and not dang.has(c):
			return c
	return null
