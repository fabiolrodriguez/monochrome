class_name EnemyData
extends Resource

enum Behavior { CHASER, SHOOTER, TANK }

@export var id: StringName
@export var behavior := Behavior.CHASER
@export_range(1.0, 10000.0, 1.0) var maximum_health: float = 25.0
@export_range(1.0, 300.0, 1.0) var movement_speed: float = 40.0
@export_range(0.0, 100.0, 1.0) var contact_damage: float = 10.0
@export_range(0.1, 10.0, 0.05) var shot_interval: float = 1.35
@export_range(0.0, 500.0, 1.0) var preferred_distance: float = 90.0
@export_range(0.0, 200.0, 1.0) var distance_tolerance: float = 15.0
@export_range(0.1, 100.0, 0.1) var experience_value: float = 5.0
@export_range(0.1, 100.0, 0.1) var threat_cost: float = 1.0
@export_range(0.0, 1.0, 0.01) var coin_drop_chance: float = 0.08
@export_range(1, 1000, 1) var coin_value: int = 1
@export var is_elite := false
@export_range(0.0, 1.0, 0.01) var healing_drop_chance := 0.025
@export_range(1.0, 1000.0, 1.0) var healing_value := 12.0
