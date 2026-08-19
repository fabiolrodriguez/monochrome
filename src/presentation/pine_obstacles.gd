class_name PineObstacles
extends TileMapLayer

const TILE_SIZE := Vector2i(16, 16)
const ATLAS_COORDINATES := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const PINE_ATLAS := preload("res://assets/tilesets/void_pines.svg")
const PLAYER_START_CELL := Vector2i(10, 5)

@export var generation_seed: int = 8803
@export_range(1, 100, 1) var pine_count: int = 38
@export_range(2, 12, 1) var minimum_spacing: int = 4
@export_range(8, 64, 1) var map_radius: int = 36

var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.seed = generation_seed
	_build_tileset()
	_scatter_pines()
	TileCollisionBuilder.attach_static_body(self, Vector2(12, 14))


func _build_tileset() -> void:
	var generated_tileset := TileSet.new()
	generated_tileset.tile_size = TILE_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = PINE_ATLAS
	atlas.texture_region_size = TILE_SIZE
	for coordinate: Vector2i in ATLAS_COORDINATES:
		atlas.create_tile(coordinate)
	generated_tileset.add_source(atlas, 0)
	tile_set = generated_tileset


func _scatter_pines() -> void:
	var forest_walls := get_tree().get_first_node_in_group("forest_walls") as TileMapLayer
	var placed: Array[Vector2i] = []
	var attempts := pine_count * 30
	while placed.size() < pine_count and attempts > 0:
		attempts -= 1
		var candidate := Vector2i(
			_random.randi_range(-map_radius, map_radius),
			_random.randi_range(-map_radius, map_radius)
		)
		if candidate.distance_to(PLAYER_START_CELL) < 6.0:
			continue
		if forest_walls != null and forest_walls.get_cell_source_id(candidate) != -1:
			continue
		if not _is_spaced(candidate, placed):
			continue
		var variant := _random.randi_range(0, ATLAS_COORDINATES.size() - 1)
		set_cell(candidate, 0, ATLAS_COORDINATES[variant])
		placed.append(candidate)


func _is_spaced(candidate: Vector2i, placed: Array[Vector2i]) -> bool:
	for existing: Vector2i in placed:
		if candidate.distance_to(existing) < float(minimum_spacing):
			return false
	return true
