extends VatTrenO

## Two stationary chests beside the tile; the tile center stays clear.
const FLOOR_HEIGHT := 0.2
var _destination := Vector3.INF
var _move: Tween

func _ready() -> void:
	set_process(false)

func dat_len(tile_position: Vector3) -> void:
	var destination := tile_position + Vector3.UP * FLOOR_HEIGHT
	if visible and destination.is_equal_approx(_destination):
		return
	_destination = destination
	if _move != null and _move.is_valid():
		_move.kill()
	if not visible:
		global_position = destination
		visible = true
		return
	_move = create_tween().set_trans(Tween.TRANS_SINE)
	_move.tween_property(self, "global_position", destination, GIAY_DOI_CHO)

func an() -> void:
	if _move != null and _move.is_valid():
		_move.kill()
	visible = false
