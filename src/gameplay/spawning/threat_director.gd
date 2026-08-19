class_name ThreatDirector
extends Node


@export var enemy_scene: PackedScene
@export var enemy_pool: Array[EnemyData] = []
@export var elite_pool: Array[EnemyData] = []
@export_range(10.0, 300.0, 1.0) var first_elite_at := 75.0
@export_range(10.0, 300.0, 1.0) var elite_interval := 90.0
@export_range(0.1, 10.0, 0.1) var spawn_interval: float = 0.8
@export_range(1, 500, 1) var maximum_active_enemies: int = 45
@export_range(50.0, 1000.0, 1.0) var spawn_distance: float = 190.0
@export_range(0.0, 100.0, 0.1) var starting_budget: float = 3.0
@export_range(0.0, 20.0, 0.1) var budget_per_second: float = 0.7
@export var spawn_bounds := Rect2(-608.0, -608.0, 1216.0, 1216.0)

@onready var spawn_timer: Timer = $SpawnTimer

var _player: Player
var _available_budget := 0.0
var _elapsed_time := 0.0
var _active_enemies := 0
var _random := RandomNumberGenerator.new()
var _reserved_enemy: EnemyData
var _spawn_bag: Array[EnemyData] = []
var _budget_multiplier := 1.0
var _base_spawn_interval: float
var _next_elite_at: float


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	_available_budget = starting_budget
	_random.randomize()
	_base_spawn_interval = spawn_interval
	_next_elite_at = first_elite_at
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_try_spawn)
	spawn_timer.start()


func _process(delta: float) -> void:
	_elapsed_time += delta
	# Pressure grows smoothly; objective modifiers can alter this rate later.
	_available_budget += budget_per_second * _budget_multiplier * (1.0 + _elapsed_time / 180.0) * delta
	if _elapsed_time >= _next_elite_at and _active_enemies < maximum_active_enemies and not elite_pool.is_empty():
		_spawn_enemy(elite_pool.pick_random())
		_next_elite_at += elite_interval


func _try_spawn() -> void:
	if enemy_scene == null or enemy_pool.is_empty():
		return
	if _active_enemies >= maximum_active_enemies:
		return
	# A shuffled bag guarantees variety. Its next archetype stays reserved until
	# the cost is met, so cheap enemies cannot consume the whole budget first.
	if _reserved_enemy == null:
		if _spawn_bag.is_empty():
			for data: EnemyData in enemy_pool:
				_spawn_bag.append(data)
			_spawn_bag.shuffle()
		_reserved_enemy = _spawn_bag.pop_back()
	if _reserved_enemy.threat_cost > _available_budget:
		return
	_spawn_enemy(_reserved_enemy)
	_available_budget -= _reserved_enemy.threat_cost
	_reserved_enemy = null


func configure_pool(new_pool: Array[EnemyData], new_elite_pool: Array[EnemyData] = []) -> void:
	enemy_pool = new_pool
	elite_pool = new_elite_pool
	_reserved_enemy = null
	_spawn_bag.clear()


func set_pressure(budget_multiplier: float, interval_multiplier: float, active_limit: int) -> void:
	_budget_multiplier = maxf(budget_multiplier, 0.0)
	spawn_timer.wait_time = maxf(_base_spawn_interval * interval_multiplier, 0.1)
	maximum_active_enemies = maxi(active_limit, 1)


func stop_spawning() -> void:
	spawn_timer.stop()
	set_process(false)


func _spawn_enemy(data: EnemyData) -> void:
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null or not is_instance_valid(_player):
		return
	enemy.data = data
	var enemy_container := get_tree().get_first_node_in_group("enemy_container")
	if enemy_container == null:
		enemy_container = get_tree().current_scene
	enemy_container.add_child(enemy)
	enemy.global_position = _choose_spawn_position()
	enemy.defeated.connect(_on_enemy_defeated)
	_active_enemies += 1


func _choose_spawn_position() -> Vector2:
	for _attempt: int in 12:
		var angle := _random.randf_range(0.0, TAU)
		var distance := spawn_distance + _random.randf_range(0.0, 35.0)
		var candidate := _player.global_position + Vector2.RIGHT.rotated(angle) * distance
		if spawn_bounds.has_point(candidate):
			return candidate
	var fallback := _player.global_position + Vector2.RIGHT.rotated(_random.randf_range(0.0, TAU)) * spawn_distance
	return Vector2(
		clampf(fallback.x, spawn_bounds.position.x, spawn_bounds.end.x),
		clampf(fallback.y, spawn_bounds.position.y, spawn_bounds.end.y)
	)


func _on_enemy_defeated(_enemy: Enemy) -> void:
	_active_enemies = maxi(_active_enemies - 1, 0)
