extends RefCounted

const Rules = preload("res://minigame/paint/paint_rules.gd")
const EMPTY_COLOR := Color("eee9dd")
const COLORS := [Color("f05a77"), Color("36bcee"), Color("f4c542"), Color("9966e9"),
	Color("46ce91"), Color("f79344"), Color("ed78ce"), Color("5283f2")]

var _last_cells := ""
var _texture: ImageTexture
var _material: ShaderMaterial


static func color(index: int) -> Color:
	return COLORS[index] if index < COLORS.size() else Color.from_hsv(fposmod(index * 0.618034, 1), 0.65, 0.9)


func attach(floor_mesh: MeshInstance3D, origin: Vector3) -> void:
	_material = floor_mesh.material_override.duplicate() as ShaderMaterial
	_material.set_shader_parameter("arena_origin", Vector2(origin.x, origin.z))
	floor_mesh.material_override = _material


func present(cells: String) -> void:
	if cells == _last_cells:
		return
	_last_cells = cells
	var image := Image.create(Rules.GRID_SIZE, Rules.GRID_SIZE, false, Image.FORMAT_RGB8)
	for y: int in Rules.GRID_SIZE:
		for x: int in Rules.GRID_SIZE:
			var owner := Rules.OWNER_CODES.find(cells[y * Rules.GRID_SIZE + x])
			image.set_pixel(x, y, EMPTY_COLOR if owner <= 0 else color(owner - 1))
	if _texture == null:
		_texture = ImageTexture.create_from_image(image)
		_material.set_shader_parameter("paint_map", _texture)
	else:
		_texture.update(image)
