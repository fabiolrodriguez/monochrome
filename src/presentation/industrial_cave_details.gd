class_name IndustrialCaveDetails
extends TileMapLayer

const TILE_SIZE := Vector2i(16, 16)
const CAVE_ATLAS := preload("res://assets/art/monochrome_caves/bw_tiles.png")
const PATCH_ORIGINS := [
	Vector2i(-29, -23), Vector2i(23, -16), Vector2i(1, 24),
	Vector2i(-20, 18), Vector2i(27, 11), Vector2i(-5, -27),
]


func _ready() -> void:
	_build_tileset()
	_build_reusable_patches()


func _build_tileset() -> void:
	var generated_tileset := TileSet.new()
	generated_tileset.tile_size = TILE_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = CAVE_ATLAS
	atlas.texture_region_size = TILE_SIZE
	for y: int in 4:
		for x: int in 4:
			atlas.create_tile(Vector2i(x, y))
	generated_tileset.add_source(atlas, 0)
	tile_set = generated_tileset


func _build_reusable_patches() -> void:
	for patch_index: int in PATCH_ORIGINS.size():
		var origin: Vector2i = PATCH_ORIGINS[patch_index]
		var mirrored := patch_index % 2 == 1
		for y: int in 4:
			for x: int in 4:
				var source_x := 3 - x if mirrored else x
				set_cell(origin + Vector2i(x, y), 0, Vector2i(source_x, y))
