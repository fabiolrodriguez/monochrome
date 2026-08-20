class_name OneBitDungeonDetails
extends TileMapLayer

const TILE_SIZE := Vector2i(16, 16)
const ATLAS := preload("res://assets/art/one_bit_dungeon/dungeon_tiles.png")
const PATCHES := [
	[Vector2i(-22, -23), Vector2i(0, 0)],
	[Vector2i(20, -19), Vector2i(3, 0)],
	[Vector2i(-24, 19), Vector2i(0, 4)],
	[Vector2i(21, 21), Vector2i(3, 4)],
]


func _ready() -> void:
	if ProgressionManager.selected_level_id != &"the_core":
		return
	_build_tileset()
	for patch: Array in PATCHES:
		_stamp_room(patch[0], patch[1])


func _build_tileset() -> void:
	var generated_tileset := TileSet.new()
	generated_tileset.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = ATLAS
	source.texture_region_size = TILE_SIZE
	for y: int in 8:
		for x: int in 9:
			source.create_tile(Vector2i(x, y))
	generated_tileset.add_source(source, 0)
	tile_set = generated_tileset


func _stamp_room(origin: Vector2i, atlas_origin: Vector2i) -> void:
	for y: int in 3:
		for x: int in 3:
			# The center glyph reads as a collectible; keep only the reusable room shell.
			if x == 1 and y == 1:
				continue
			set_cell(origin + Vector2i(x, y), 0, atlas_origin + Vector2i(x, y))
