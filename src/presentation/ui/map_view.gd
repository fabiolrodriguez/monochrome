class_name MapView
extends Control

@export var tracker_path: NodePath
@export var player_path: NodePath
@export_range(4.0, 24.0, 1.0) var sector_draw_size: float = 12.0

const MIN_ZOOM := 0.55
const MAX_ZOOM := 3.0
const MAP_HALF_EXTENT := 640.0

var _tracker: ExplorationTracker
var _player: Player
var _obstacle_layers: Array[TileMapLayer] = []
var _pan_world := Vector2.ZERO
var _zoom := 1.0
var _dragging := false
var _drag_origin := Vector2.ZERO
var _drag_pan_origin := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_tracker = get_node(tracker_path) as ExplorationTracker
	_player = get_node(player_path) as Player
	for node: Node in get_tree().get_nodes_in_group("map_obstacle"):
		var layer := node as TileMapLayer
		if layer != null:
			_obstacle_layers.append(layer)
	_tracker.exploration_changed.connect(queue_redraw)
	queue_redraw()


func reset_view() -> void:
	_pan_world = Vector2.ZERO
	_zoom = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.01:
		_pan_world += direction * 260.0 * delta / _zoom
		_clamp_pan()
	if Input.is_action_pressed("map_zoom_in"):
		_set_zoom(_zoom + delta * 1.4)
	if Input.is_action_pressed("map_zoom_out"):
		_set_zoom(_zoom - delta * 1.4)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_zoom_at(_zoom + 0.18, mouse_event.position)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_zoom_at(_zoom - 0.18, mouse_event.position)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT or mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mouse_event.pressed
			if _dragging:
				_drag_origin = mouse_event.position
				_drag_pan_origin = _pan_world
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_pan_world = _drag_pan_origin - (motion.position - _drag_origin) / _world_scale()
		_clamp_pan()
		queue_redraw()
		accept_event()


func _draw() -> void:
	if _tracker == null or _player == null:
		return
	_draw_discovered_obstacles()
	_draw_pickups()
	_draw_objective_targets()
	var player_position := _world_to_map(_player.global_position)
	draw_circle(player_position, 3.0, Color.WHITE)
	draw_circle(player_position, 1.25, Color("101216"))


func _draw_discovered_obstacles() -> void:
	var tile_pixel_size := maxf(_world_scale() * 13.0, 1.0)
	for layer: TileMapLayer in _obstacle_layers:
		if not layer.visible:
			continue
		for cell: Vector2i in layer.get_used_cells():
			var world_position := layer.to_global(layer.map_to_local(cell))
			if not _tracker.is_explored(_tracker.world_to_sector(world_position)):
				continue
			var map_position := _world_to_map(world_position)
			if _is_inside_view(map_position):
				draw_rect(Rect2(map_position - Vector2.ONE * tile_pixel_size * 0.5, Vector2.ONE * tile_pixel_size), Color("b7b9bd"))


func _draw_pickups() -> void:
	for candidate: Node in get_tree().get_nodes_in_group("map_pickup"):
		var pickup := candidate as Node2D
		if pickup == null or not _tracker.is_explored(_tracker.world_to_sector(pickup.global_position)):
			continue
		var map_position := _world_to_map(pickup.global_position)
		if not _is_inside_view(map_position):
			continue
		var color := Color("b67cff") if pickup.is_in_group("map_upgrade") else Color("7ed7ff")
		draw_circle(map_position, 2.0, color)


func _draw_objective_targets() -> void:
	for candidate: Node in get_tree().get_nodes_in_group("objective_target"):
		var target := candidate as Node2D
		if target == null:
			continue
		var map_position := _world_to_map(target.global_position)
		map_position.x = clampf(map_position.x, 5.0, size.x - 5.0)
		map_position.y = clampf(map_position.y, 5.0, size.y - 5.0)
		var diamond := PackedVector2Array([map_position + Vector2(0, -3), map_position + Vector2(3, 0), map_position + Vector2(0, 3), map_position + Vector2(-3, 0)])
		draw_colored_polygon(diamond, Color("ffd84a"))


func _world_to_map(world_position: Vector2) -> Vector2:
	var view_center_world := _player.global_position + _pan_world
	return size * 0.5 + (world_position - view_center_world) * _world_scale()


func _world_scale() -> float:
	return sector_draw_size * _zoom / _tracker.sector_world_size


func _zoom_at(value: float, anchor: Vector2) -> void:
	var scale_before := _world_scale()
	var anchor_world := _player.global_position + _pan_world + (anchor - size * 0.5) / scale_before
	_set_zoom(value)
	_pan_world = anchor_world - _player.global_position - (anchor - size * 0.5) / _world_scale()
	_clamp_pan()


func _set_zoom(value: float) -> void:
	_zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	queue_redraw()


func _clamp_pan() -> void:
	var view_center := _player.global_position + _pan_world
	view_center.x = clampf(view_center.x, -MAP_HALF_EXTENT, MAP_HALF_EXTENT)
	view_center.y = clampf(view_center.y, -MAP_HALF_EXTENT, MAP_HALF_EXTENT)
	_pan_world = view_center - _player.global_position


func _is_inside_view(point: Vector2) -> bool:
	return point.x >= 0.0 and point.y >= 0.0 and point.x <= size.x and point.y <= size.y
