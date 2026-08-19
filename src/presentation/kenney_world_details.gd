class_name KenneyWorldDetails
extends TileMapLayer

const TILE_SIZE := Vector2i(16, 16)
const ATLAS := preload("res://assets/art/kenney_1bit/monochrome_tilemap.png")

# Only perspective-neutral props are selected from the platformer atlas:
# panels, ladders, signs, vegetation, bones and small mechanical parts.
const DEAD_FACTORY_PROPS := [
	[Vector2i(-24, -17), Vector2i(4, 1)], [Vector2i(-21, -17), Vector2i(5, 1)],
	[Vector2i(26, -11), Vector2i(6, 1)], [Vector2i(29, -11), Vector2i(7, 1)],
	[Vector2i(2, 28), Vector2i(0, 4)], [Vector2i(3, 28), Vector2i(1, 4)],
	[Vector2i(-31, 8), Vector2i(12, 3)], [Vector2i(31, 5), Vector2i(13, 3)],
	[Vector2i(-7, -29), Vector2i(8, 19)], [Vector2i(18, 24), Vector2i(9, 19)],
]
const WHITE_FOREST_PROPS := [
	[Vector2i(-30, -18), Vector2i(14, 0)], [Vector2i(-18, 27), Vector2i(15, 0)],
	[Vector2i(29, -22), Vector2i(16, 0)], [Vector2i(25, 24), Vector2i(17, 0)],
	[Vector2i(-5, -26), Vector2i(14, 1)], [Vector2i(8, 29), Vector2i(15, 1)],
]
const HIVE_PROPS := [
	[Vector2i(-26, -20), Vector2i(0, 14)], [Vector2i(27, -17), Vector2i(1, 14)],
	[Vector2i(-23, 24), Vector2i(2, 15)], [Vector2i(25, 26), Vector2i(3, 15)],
	[Vector2i(-10, 12), Vector2i(14, 0)], [Vector2i(13, -9), Vector2i(16, 0)],
	[Vector2i(4, 30), Vector2i(4, 16)], [Vector2i(-31, 3), Vector2i(5, 16)],
]
const BLACK_LAKE_PROPS := [
	[Vector2i(-23, -5), Vector2i(14, 0)], [Vector2i(-19, -11), Vector2i(15, 0)],
	[Vector2i(18, 5), Vector2i(16, 0)], [Vector2i(22, 12), Vector2i(17, 0)],
	[Vector2i(-14, 23), Vector2i(0, 15)], [Vector2i(18, -25), Vector2i(1, 15)],
	[Vector2i(5, -30), Vector2i(14, 1)], [Vector2i(-29, 17), Vector2i(15, 1)],
]
const BROKEN_CITY_PROPS := [
	[Vector2i(-28, -20), Vector2i(4, 1)], [Vector2i(-25, -20), Vector2i(5, 1)],
	[Vector2i(25, -15), Vector2i(8, 19)], [Vector2i(29, -15), Vector2i(9, 19)],
	[Vector2i(-20, 25), Vector2i(0, 4)], [Vector2i(-19, 25), Vector2i(1, 4)],
	[Vector2i(22, 27), Vector2i(12, 3)], [Vector2i(27, 21), Vector2i(13, 3)],
	[Vector2i(-5, -28), Vector2i(17, 10)], [Vector2i(8, 29), Vector2i(18, 10)],
	[Vector2i(-31, 4), Vector2i(6, 19)], [Vector2i(31, 7), Vector2i(7, 19)],
]
const CORE_PROPS := [
	[Vector2i(-27, -22), Vector2i(4, 1)], [Vector2i(-24, -22), Vector2i(5, 1)],
	[Vector2i(25, -20), Vector2i(8, 19)], [Vector2i(28, -20), Vector2i(9, 19)],
	[Vector2i(-25, 23), Vector2i(0, 4)], [Vector2i(-24, 23), Vector2i(1, 4)],
	[Vector2i(23, 25), Vector2i(12, 3)], [Vector2i(27, 21), Vector2i(13, 3)],
	[Vector2i(-8, -29), Vector2i(17, 10)], [Vector2i(10, 29), Vector2i(18, 10)],
]


func _ready() -> void:
	var props: Array = []
	match ProgressionManager.selected_level_id:
		&"dead_factory": props = DEAD_FACTORY_PROPS
		&"white_forest": props = WHITE_FOREST_PROPS
		&"the_hive": props = HIVE_PROPS
		&"black_lake": props = BLACK_LAKE_PROPS
		&"broken_city": props = BROKEN_CITY_PROPS
		&"the_core": props = CORE_PROPS
		_: return
	_build_tileset(props)
	for definition: Array in props:
		set_cell(definition[0], 0, definition[1])


func _build_tileset(props: Array) -> void:
	var generated_tileset := TileSet.new()
	generated_tileset.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = ATLAS
	source.texture_region_size = TILE_SIZE
	var created: Dictionary[Vector2i, bool] = {}
	for definition: Array in props:
		var coordinate: Vector2i = definition[1]
		if created.has(coordinate):
			continue
		source.create_tile(coordinate)
		created[coordinate] = true
	generated_tileset.add_source(source, 0)
	tile_set = generated_tileset
