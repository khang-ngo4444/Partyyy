extends MiniGame3D

## Timed floor groups sink and return. Standing on a tile never damages it.
const Rules = preload("res://minigame/breaking_blocks/falling_floor_rules.gd")

@export var o_scene: PackedScene = null
@export var mat_lanh: StandardMaterial3D = null
@export var mat_bao: StandardMaterial3D = null

var _tiles: Array[OSan] = []
var _centers: PackedVector3Array = PackedVector3Array()
var _plan: Array = []
var _warning_material: StandardMaterial3D


func _ready() -> void:
	super()
	_warning_material = mat_bao.duplicate() as StandardMaterial3D


func _dung_san() -> void:
	# A solo practice round should reach the first wave instead of ending on spawn.
	ket_thuc_khi_con_mot = _song.size() > 1
	_tiles.clear()
	_centers.clear()
	_plan = Rules.plan(hat_giong)
	if o_scene == null:
		push_error("FallingFloor: missing authored tile scene")
		return
	for index: int in Rules.TILE_COUNT:
		var tile := o_scene.instantiate() as OSan
		san.add_child(tile)
		var center: Vector3 = Rules.center(index)
		tile.position = center
		_tiles.append(tile)
		_centers.append(center)
		tile.dat(true)
		tile.son(mat_lanh)


func _luat_moi_nhip() -> void:
	_present_floor(maxf(gio(), 0.0))
	if NetManager.is_master() and _song.size() == 1 and so_con_song() == 0:
		_chot_ket_qua()


func _present_floor(elapsed: float) -> void:
	var pulse := (sin(elapsed * 12.0) + 1.0) * 0.5
	_warning_material.emission_energy_multiplier = lerpf(0.3, 1.5, pulse)
	for index: int in _tiles.size():
		var sample: Dictionary = Rules.tile_at(_plan, index, elapsed)
		var tile: OSan = _tiles[index]
		tile.position = _centers[index] + Vector3.DOWN * float(sample.depth)
		# The visual sinks while its authored collider disconnects immediately.
		# Returning floors cannot catch a player who has already fallen below them.
		var body := tile.get_node("Than") as StaticBody3D
		body.collision_layer = 1 if bool(sample.solid) else 0
		tile.son(_warning_material if bool(sample.warning) else mat_lanh)


func _cho_vao(index: int, total: int) -> Vector3:
	var position := super(index, total)
	var column := clampi(roundi(position.x / Rules.TILE_SIZE + 3.5), 0, Rules.SIDE - 1)
	var row := clampi(roundi(position.z / Rules.TILE_SIZE + 3.5), 0, Rules.SIDE - 1)
	return Rules.center(row * Rules.SIDE + column) + Vector3.UP


func ban_kinh_vao_san() -> float:
	return Rules.TILE_SIZE * 2.0


func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	Fusion.rpc(_net_xep_hang, Rules.ranking(_song.keys(), _song, _thu_tu_chet))


func chu_diem(id: int) -> String:
	if not _song.has(id):
		return ""
	var order: int = _thu_tu_chet.find(id)
	return "Còn trên sàn" if order < 0 else "Rơi #%d" % (order + 1)
