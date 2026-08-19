class_name SpawnSegmentData
extends Resource

@export_range(0.0, 1.0, 0.01) var starts_at_ratio: float = 0.0
@export_range(0.0, 10.0, 0.05) var budget_multiplier: float = 1.0
@export_range(0.1, 3.0, 0.05) var spawn_interval_multiplier: float = 1.0
@export_range(1, 500, 1) var maximum_active_enemies: int = 25

