class_name BossController
extends Node

signal boss_spawned(boss: TheWatcher)
signal boss_health_changed(current: float, maximum: float)
signal boss_defeated

@export var level_controller_path: NodePath
@export var objective_manager_path: NodePath
@export var boss_scene: PackedScene
@export var spawn_bounds := Rect2(-580.0, -580.0, 1160.0, 1160.0)

var active_boss: TheWatcher
var _level_controller: LevelController
var _player: Player
var _objective_manager: ObjectiveManager


func _ready() -> void:
	_level_controller = get_node(level_controller_path) as LevelController
	_objective_manager = get_node(objective_manager_path) as ObjectiveManager
	_player = get_tree().get_first_node_in_group("player") as Player
	assert(_level_controller != null and _objective_manager != null)
	_objective_manager.objective_completed.connect(func(_data: ObjectiveData) -> void: _spawn_boss())


func _spawn_boss() -> void:
	if active_boss != null or not is_instance_valid(_player):
		return
	var selected_scene: PackedScene = _level_controller.data.boss.scene if _level_controller.data.boss.scene != null else boss_scene
	if selected_scene == null:
		return
	_level_controller.begin_boss_encounter()
	active_boss = selected_scene.instantiate() as TheWatcher
	if active_boss == null:
		return
	active_boss.data = _level_controller.data.boss
	active_boss.health_changed.connect(_on_boss_health_changed)
	active_boss.defeated.connect(_on_boss_defeated)
	var container := get_tree().get_first_node_in_group("enemy_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(active_boss)
	active_boss.add_to_group("objective_target")
	active_boss.global_position = _choose_clear_spawn_position()
	boss_spawned.emit(active_boss)


func _choose_clear_spawn_position() -> Vector2:
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	for index: int in 16:
		var direction := Vector2.UP.rotated(TAU * float(index) / 16.0)
		var candidate := _player.global_position + direction * 140.0
		if not spawn_bounds.has_point(candidate):
			continue
		query.transform = Transform2D(0.0, candidate)
		if get_viewport().world_2d.direct_space_state.intersect_shape(query, 1).is_empty():
			return candidate
	var fallback := _player.global_position + Vector2.UP * 90.0
	return Vector2(
		clampf(fallback.x, spawn_bounds.position.x, spawn_bounds.end.x),
		clampf(fallback.y, spawn_bounds.position.y, spawn_bounds.end.y)
	)


func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_health_changed.emit(current, maximum)


func _on_boss_defeated() -> void:
	active_boss = null
	boss_defeated.emit()
