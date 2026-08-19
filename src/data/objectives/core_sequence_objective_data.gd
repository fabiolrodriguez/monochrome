class_name CoreSequenceObjectiveData
extends ObjectiveData

@export var core_positions: Array[Vector2] = []
@export var terminal_position := Vector2.ZERO
@export_range(5.0, 120.0, 1.0) var terminal_duration := 35.0
@export_range(5.0, 180.0, 1.0) var final_event_duration := 45.0
@export_range(10.0, 5000.0, 10.0) var core_health := 420.0
