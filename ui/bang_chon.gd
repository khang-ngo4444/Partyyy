class_name BangChon
extends PanelContainer

## Bảng chọn mục tiêu vật phẩm (người / ô / minigame). Phím 1..9 chọn, Esc huỷ.

## -1 = huỷ.
signal da_chon(i: int)

@onready var _tieu_de: Label = %TieuDe
@onready var _cac_nut: Array[Button] = [%Chon1, %Chon2, %Chon3, %Chon4, %Chon5, %Chon6,
		%Chon7, %Chon8, %Chon9]


func _ready() -> void:
	visible = false
	for i in _cac_nut.size():
		_cac_nut[i].pressed.connect(_chon.bind(i))
	%Huy.pressed.connect(_chon.bind(-1))


## `nhan` rỗng = đóng bảng.
func mo(tieu_de: String, nhan: PackedStringArray) -> void:
	_tieu_de.text = tieu_de
	for i in _cac_nut.size():
		_cac_nut[i].visible = i < nhan.size()
		if i < nhan.size():
			_cac_nut[i].text = "%d. %s" % [i + 1, nhan[i]]
	visible = not tieu_de.is_empty()


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey and event.pressed and not event.echo):
		return
	var phim := (event as InputEventKey).keycode
	if phim == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_chon(-1)
		return
	var i := int(phim) - KEY_1
	if i >= 0 and i < _cac_nut.size() and _cac_nut[i].visible:
		get_viewport().set_input_as_handled()
		_chon(i)


func _chon(i: int) -> void:
	visible = false
	da_chon.emit(i)
