class_name DestroyNestsObjectiveData
extends ObjectiveData

@export var spawn_enemy_data: EnemyData
@export_range(1, 10, 1) var nest_count := 4
@export_range(10.0, 5000.0, 10.0) var nest_health := 280.0
@export_range(1.0, 20.0, 0.25) var nest_spawn_interval := 6.0
@export var nest_positions: Array[Vector2] = []
@export_range(0.0, 1000.0, 1.0) var experience_reward := 30.0
@export_range(0, 1000, 1) var coin_reward := 4
@export_range(0.0, 1000.0, 1.0) var healing_reward := 8.0
