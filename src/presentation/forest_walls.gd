class_name ForestWalls
extends TileMapLayer

const TILE_SIZE := Vector2i(16, 16)
const ATLAS_COORDINATES := [
	Vector2i(0, 8), Vector2i(1, 8), Vector2i(4, 8), Vector2i(6, 8),
	Vector2i(0, 9), Vector2i(1, 9), Vector2i(4, 9), Vector2i(6, 9),
	Vector2i(0, 10), Vector2i(1, 10), Vector2i(4, 10), Vector2i(6, 10),
]
const WALL_ATLAS := preload("res://assets/art/dungeon_bw/dungeon_16x16_bw.png")
const MAP_BOUNDARY_IN_TILES := 40

@export var generation_seed: int = 3108

var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.seed = generation_seed
	_build_tileset()
	_build_void_garden_layout()
	TileCollisionBuilder.attach_static_body(self, Vector2(16, 16))


func _build_tileset() -> void:
	var generated_tileset := TileSet.new()
	generated_tileset.tile_size = TILE_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = WALL_ATLAS
	atlas.texture_region_size = TILE_SIZE
	for coordinate: Vector2i in ATLAS_COORDINATES:
		atlas.create_tile(coordinate)
	generated_tileset.add_source(atlas, 0)
	tile_set = generated_tileset


func _build_void_garden_layout() -> void:
	# Reusable forest border establishes a finite playable area.
	var boundary_length := MAP_BOUNDARY_IN_TILES * 2 + 1
	_paint_horizontal(Vector2i(-MAP_BOUNDARY_IN_TILES, -MAP_BOUNDARY_IN_TILES), boundary_length)
	_paint_horizontal(Vector2i(-MAP_BOUNDARY_IN_TILES, MAP_BOUNDARY_IN_TILES), boundary_length)
	_paint_vertical(Vector2i(-MAP_BOUNDARY_IN_TILES, -MAP_BOUNDARY_IN_TILES + 1), boundary_length - 2)
	_paint_vertical(Vector2i(MAP_BOUNDARY_IN_TILES, -MAP_BOUNDARY_IN_TILES + 1), boundary_length - 2)

	# Broken perimeter around the initial clearing: broad exits on every side.
	_paint_horizontal(Vector2i(3, -1), 6)
	_paint_horizontal(Vector2i(13, -1), 6)
	_paint_horizontal(Vector2i(3, 12), 5)
	_paint_horizontal(Vector2i(13, 12), 6)
	_paint_vertical(Vector2i(2, 0), 4)
	_paint_vertical(Vector2i(2, 8), 4)
	_paint_vertical(Vector2i(19, 0), 4)
	_paint_vertical(Vector2i(19, 8), 4)

	# Small reusable C-shaped rooms and forest pockets beyond the clearing.
	_paint_room(Vector2i(-9, 1), Vector2i(7, 8), 1)
	_paint_room(Vector2i(23, 2), Vector2i(8, 7), 3)
	_paint_room(Vector2i(7, -12), Vector2i(8, 7), 2)
	_paint_room(Vector2i(8, 17), Vector2i(7, 8), 0)
	_paint_room(Vector2i(-12, -11), Vector2i(6, 6), 1)
	_paint_room(Vector2i(27, 17), Vector2i(7, 6), 3)

	# Short tree lines break sightlines without forming impassable mazes.
	_paint_horizontal(Vector2i(-2, 15), 5)
	_paint_vertical(Vector2i(24, -8), 5)
	_paint_horizontal(Vector2i(29, -5), 6)
	_paint_vertical(Vector2i(-5, 18), 6)


func _paint_room(origin: Vector2i, size: Vector2i, opening_side: int) -> void:
	# opening_side: 0 top, 1 right, 2 bottom, 3 left.
	var door_offset := size.x / 2
	for x: int in range(size.x):
		if opening_side != 0 or abs(x - door_offset) > 1:
			_place_wall(origin + Vector2i(x, 0))
		if opening_side != 2 or abs(x - door_offset) > 1:
			_place_wall(origin + Vector2i(x, size.y - 1))
	var vertical_door_offset := size.y / 2
	for y: int in range(1, size.y - 1):
		if opening_side != 3 or abs(y - vertical_door_offset) > 1:
			_place_wall(origin + Vector2i(0, y))
		if opening_side != 1 or abs(y - vertical_door_offset) > 1:
			_place_wall(origin + Vector2i(size.x - 1, y))


func _paint_horizontal(start: Vector2i, length: int) -> void:
	for offset: int in length:
		_place_wall(start + Vector2i(offset, 0))


func _paint_vertical(start: Vector2i, length: int) -> void:
	for offset: int in length:
		_place_wall(start + Vector2i(0, offset))


func _place_wall(cell: Vector2i) -> void:
	var variant := _random.randi_range(0, ATLAS_COORDINATES.size() - 1)
	set_cell(cell, 0, ATLAS_COORDINATES[variant])
