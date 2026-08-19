class_name TransportEnergyObjectiveData
extends ObjectiveData

@export var energy_start_position := Vector2.ZERO
@export var destination_positions: Array[Vector2] = []
@export_range(1, 10, 1) var destination_count := 3
@export_range(0.25, 1.0, 0.05) var carried_movement_multiplier := 0.85
