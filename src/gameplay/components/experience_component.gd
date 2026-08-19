class_name ExperienceComponent
extends Node

signal experience_changed(current: float, required: float)
signal level_changed(level: int)
signal leveled_up(level: int)

@export_range(1.0, 1000.0, 1.0) var base_requirement: float = 20.0
@export_range(1.0, 3.0, 0.05) var curve_exponent: float = 1.25

var level := 1
var current_experience := 0.0
var required_experience := 20.0


func _ready() -> void:
	required_experience = _requirement_for_level(level)
	experience_changed.emit(current_experience, required_experience)
	level_changed.emit(level)


func add_experience(amount: float) -> void:
	if amount <= 0.0:
		return
	current_experience += amount
	while current_experience >= required_experience:
		current_experience -= required_experience
		level += 1
		required_experience = _requirement_for_level(level)
		level_changed.emit(level)
		leveled_up.emit(level)
	experience_changed.emit(current_experience, required_experience)


func _requirement_for_level(target_level: int) -> float:
	return ceilf(base_requirement * pow(float(target_level), curve_exponent))

