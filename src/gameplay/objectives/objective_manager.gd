class_name ObjectiveManager
extends Node

signal objective_started(data: ObjectiveData)
signal objective_progress_changed(data: ObjectiveData, current: float, required: float)
signal objective_completed(data: ObjectiveData)
signal objective_failed(data: ObjectiveData)

@export var level_controller_path: NodePath

var active_objective: BaseObjective
var _level_controller: LevelController


func _ready() -> void:
	_level_controller = get_node(level_controller_path) as LevelController
	assert(_level_controller != null, "ObjectiveManager requires a LevelController.")
	_create_objective(_level_controller.data.objective)
	_level_controller.time_changed.connect(_on_level_time_changed)
	active_objective.begin()


func _create_objective(data: ObjectiveData) -> void:
	assert(data != null and data.objective_scene != null, "Level requires valid ObjectiveData.")
	active_objective = data.objective_scene.instantiate() as BaseObjective
	assert(active_objective != null, "Objective scene must instantiate BaseObjective.")
	add_child(active_objective)
	active_objective.configure(data, {"level_duration": _level_controller.data.duration})
	active_objective.started.connect(func() -> void: objective_started.emit(data))
	active_objective.progress_changed.connect(func(current: float, required: float) -> void: objective_progress_changed.emit(data, current, required))
	active_objective.completed.connect(func() -> void: objective_completed.emit(data))
	active_objective.failed.connect(func() -> void: objective_failed.emit(data))


func _on_level_time_changed(elapsed: float, duration: float) -> void:
	active_objective.update_level_time(elapsed, duration)
