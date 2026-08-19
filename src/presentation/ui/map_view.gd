class_name MapView
extends Control

@export var tracker_path: NodePath
@export var player_path: NodePath
@export_range(4.0, 24.0, 1.0) var sector_draw_size: float = 12.0

var _tracker: ExplorationTracker
var _player: Player
var _obstacle_layers: Array[TileMapLayer] = []


func _ready() -> void:
	_tracker = get_node(tracker_path) as ExplorationTracker
	_player = get_node(player_path) as Player
	for node: Node in get_tree().get_nodes_in_group("map_obstacle"):
		var layer := node as TileMapLayer
		if layer != null:
			_obstacle_layers.append(layer)
	_tracker.exploration_changed.connect(queue_redraw)
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if _tracker == null or _player == null:
		return
	var center := size * 0.5
	for sector: Vector2i in _tracker.explored_sectors:
		var sector_world_center := Vector2(
			(float(sector.x) + 0.5) * _tracker.sector_world_size,
			(float(sector.y) + 0.5) * _tracker.sector_world_size
		)
		var relative_position := sector_world_center - _player.global_position
		var map_position := center + relative_position / _tracker.sector_world_size * sector_draw_size
		draw_rect(Rect2(map_position - Vector2.ONE * sector_draw_size * 0.5, Vector2.ONE * (sector_draw_size - 1.0)), Color("202329"))
	_draw_discovered_obstacles(center)
	_draw_objective_target(center)
	draw_circle(center, 2.5, Color.WHITE)
	draw_circle(center, 1.0, Color("101216"))


func _draw_discovered_obstacles(center: Vector2) -> void:
	var tile_pixel_size := sector_draw_size / 4.0
	for layer: TileMapLayer in _obstacle_layers:
		for cell: Vector2i in layer.get_used_cells():
			var world_position := layer.to_global(layer.map_to_local(cell))
			var sector := _tracker.world_to_sector(world_position)
			if not _tracker.is_explored(sector):
				continue
			var relative_world := world_position - _player.global_position
			var map_position := center + relative_world / _tracker.sector_world_size * sector_draw_size
			draw_rect(Rect2(map_position - Vector2.ONE * tile_pixel_size * 0.5, Vector2.ONE * tile_pixel_size), Color("b7b9bd"))


func _draw_objective_target(center: Vector2) -> void:
	var targets := get_tree().get_nodes_in_group("objective_target")
	if targets.is_empty():
		return
	for candidate: Node in targets:
		var target := candidate as Node2D
		if target == null:
			continue
		var relative_world := target.global_position - _player.global_position
		var map_position := center + relative_world / _tracker.sector_world_size * sector_draw_size
		map_position.x = clampf(map_position.x, 5.0, size.x - 5.0)
		map_position.y = clampf(map_position.y, 5.0, size.y - 5.0)
		var diamond := PackedVector2Array([map_position + Vector2(0, -3), map_position + Vector2(3, 0), map_position + Vector2(0, 3), map_position + Vector2(-3, 0)])
		draw_colored_polygon(diamond, Color("ffd84a"))
