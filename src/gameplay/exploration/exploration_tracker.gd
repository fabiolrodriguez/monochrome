class_name ExplorationTracker
extends Node

signal exploration_changed

@export var player_path: NodePath
@export_range(16.0, 256.0, 16.0) var sector_world_size: float = 64.0
@export_range(0, 4, 1) var reveal_radius: int = 1
@export_range(0.05, 2.0, 0.05) var update_interval: float = 0.2

var explored_sectors: Dictionary[Vector2i, bool] = {}
var _player: Player
var _time_until_update := 0.0


func _ready() -> void:
	_player = get_node(player_path) as Player
	assert(_player != null, "ExplorationTracker requires a Player.")
	_reveal_current_sector()


func _process(delta: float) -> void:
	_time_until_update -= delta
	if _time_until_update > 0.0:
		return
	_time_until_update = update_interval
	_reveal_current_sector()


func world_to_sector(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / sector_world_size), floori(world_position.y / sector_world_size))


func is_explored(sector: Vector2i) -> bool:
	return explored_sectors.has(sector)


func _reveal_current_sector() -> void:
	var center := world_to_sector(_player.global_position)
	var changed := false
	for y: int in range(-reveal_radius, reveal_radius + 1):
		for x: int in range(-reveal_radius, reveal_radius + 1):
			var sector := center + Vector2i(x, y)
			if not explored_sectors.has(sector):
				explored_sectors[sector] = true
				changed = true
	if changed:
		exploration_changed.emit()

