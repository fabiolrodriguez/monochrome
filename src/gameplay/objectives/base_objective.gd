class_name BaseObjective
extends Node

signal started
signal progress_changed(current: float, required: float)
signal completed
signal failed

var data: ObjectiveData
var current_progress := 0.0
var required_progress := 1.0
var is_complete := false
var is_failed := false


func configure(objective_data: ObjectiveData, _context: Dictionary) -> void:
	data = objective_data


func begin() -> void:
	started.emit()
	progress_changed.emit(current_progress, required_progress)


func update_level_time(_elapsed: float, _duration: float) -> void:
	pass


func complete() -> void:
	if is_complete or is_failed:
		return
	is_complete = true
	completed.emit()


func fail() -> void:
	if is_complete or is_failed:
		return
	is_failed = true
	failed.emit()

