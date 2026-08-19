class_name TiledFloor
extends TileMapLayer

const TILE_SIZE := Vector2i(16, 16)
const ATLAS_COORDINATES := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const FLOOR_ATLAS := preload("res://assets/tilesets/monochrome_floor.svg")

@export_range(8, 128, 1) var radius_in_tiles: int = 40
@export var generation_seed: int = 1977


func _ready() -> void:
	_build_tileset()
	_paint_floor()


func _build_tileset() -> void:
	var generated_tileset := TileSet.new()
	generated_tileset.tile_size = TILE_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = FLOOR_ATLAS
	atlas.texture_region_size = TILE_SIZE
	for coordinate: Vector2i in ATLAS_COORDINATES:
		atlas.create_tile(coordinate)
	generated_tileset.add_source(atlas, 0)
	tile_set = generated_tileset


func _paint_floor() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = generation_seed
	for y: int in range(-radius_in_tiles, radius_in_tiles + 1):
		for x: int in range(-radius_in_tiles, radius_in_tiles + 1):
			# Most cells use the quiet base tile; detail remains sparse and irregular.
			var variant := 0
			if random.randf() < 0.12:
				variant = random.randi_range(1, ATLAS_COORDINATES.size() - 1)
			set_cell(Vector2i(x, y), 0, ATLAS_COORDINATES[variant])

