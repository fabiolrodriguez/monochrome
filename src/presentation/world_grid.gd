extends Node2D

const GRID_SIZE := 16
const GRID_EXTENT := 1024
const GRID_COLOR := Color(0.10, 0.10, 0.12, 1.0)
const AXIS_COLOR := Color(0.16, 0.16, 0.18, 1.0)


func _draw() -> void:
	for coordinate: int in range(-GRID_EXTENT, GRID_EXTENT + 1, GRID_SIZE):
		var color := AXIS_COLOR if coordinate == 0 else GRID_COLOR
		draw_line(Vector2(coordinate, -GRID_EXTENT), Vector2(coordinate, GRID_EXTENT), color)
		draw_line(Vector2(-GRID_EXTENT, coordinate), Vector2(GRID_EXTENT, coordinate), color)

