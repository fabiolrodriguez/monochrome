class_name HuntElitesObjectiveData
extends ObjectiveData

@export var elite_data: EnemyData
@export_range(1, 10, 1) var elite_count := 3
@export var elite_positions: Array[Vector2] = []
