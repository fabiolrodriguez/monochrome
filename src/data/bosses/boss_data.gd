class_name BossData
extends Resource

@export var id: StringName
@export var name_key: StringName
@export var description_key: StringName
@export var scene: PackedScene
@export_range(1.0, 100000.0, 1.0) var maximum_health: float = 1200.0
@export_range(0.0, 200.0, 1.0) var movement_speed: float = 18.0
@export_range(0.0, 200.0, 1.0) var contact_damage: float = 20.0
@export_range(1.0, 500.0, 1.0) var projectile_speed: float = 72.0
@export_range(0.0, 100.0, 1.0) var projectile_damage: float = 9.0
@export var phase_thresholds: Array[float] = [0.7, 0.3]
@export_range(0, 100000, 1) var coin_reward: int = 15
@export_range(0.0, 100000.0, 1.0) var experience_reward: float = 100.0
@export_range(0.0, 10000.0, 1.0) var healing_reward: float = 40.0
