class_name RuinWallDetails
extends TileMapLayer

const TILE_SIZE := Vector2i(16, 16)
const DETAIL_ATLAS := preload("res://assets/art/dungeon_bw/dungeon_16x16_bw.png")
const DETAIL_COORDINATES := [
	Vector2i(0, 12), Vector2i(1, 12), Vector2i(2, 12), Vector2i(3, 12),
	Vector2i(4, 12), Vector2i(5, 12), Vector2i(6, 12), Vector2i(7, 12),
]

@export var generation_seed := 6021
@export_range(0.0, 1.0, 0.05) var detail_chance := 0.35

var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.seed = generation_seed
	_build_tileset()
	call_deferred("_decorate_existing_walls")


func _build_tileset() -> void:
	var generated_tileset := TileSet.new()
	generated_tileset.tile_size = TILE_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = DETAIL_ATLAS
	atlas.texture_region_size = TILE_SIZE
	for coordinate: Vector2i in DETAIL_COORDINATES:
		atlas.create_tile(coordinate)
	generated_tileset.add_source(atlas, 0)
	tile_set = generated_tileset


func _decorate_existing_walls() -> void:
	var forest_walls := get_tree().get_first_node_in_group("forest_walls") as TileMapLayer
	if forest_walls == null:
		return
	for cell: Vector2i in forest_walls.get_used_cells():
		if _random.randf() > detail_chance:
			continue
		var variant := _random.randi_range(0, DETAIL_COORDINATES.size() - 1)
		set_cell(cell, 0, DETAIL_COORDINATES[variant])
