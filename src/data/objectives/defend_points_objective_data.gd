class_name DefendPointsObjectiveData
extends ObjectiveData

@export_range(1, 10, 1) var point_count := 3
@export_range(5.0, 180.0, 1.0) var duration_per_point := 45.0
@export_range(24.0, 96.0, 1.0) var defense_radius := 31.0
@export var point_positions: Array[Vector2] = []
