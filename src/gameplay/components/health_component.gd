class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal depleted

@export_range(1.0, 10000.0, 1.0) var maximum_health: float = 100.0

var current_health: float


func _ready() -> void:
	current_health = maximum_health
	health_changed.emit(current_health, maximum_health)


func damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, maximum_health)
	if is_zero_approx(current_health):
		depleted.emit()


func heal(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = minf(current_health + amount, maximum_health)
	health_changed.emit(current_health, maximum_health)


func increase_maximum(amount: float, heal_added_health := true) -> void:
	if amount <= 0.0:
		return
	maximum_health += amount
	if heal_added_health:
		current_health += amount
	health_changed.emit(current_health, maximum_health)
