extends Control

## Phím M trong phòng: mở màn Nhân vật chung (CharacterCreator) ở chế độ áp ngay lên Player.


@onready var _creator: CharacterCreator = %Creator


func _ready() -> void:
	add_to_group("chon_nhan_vat")
	visible = false
	_creator.confirmed.connect(dong)
	_creator.cancelled.connect(dong)


## Người chơi của máy này.
func _toi() -> Player:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_mine:
			return p
	return null


func mo() -> void:
	var p := _toi()
	if p == null:
		return
	visible = true
	_creator.open_phong(p)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func dong() -> void:
	if not visible:
		return
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
