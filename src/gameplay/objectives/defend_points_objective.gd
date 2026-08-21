class_name DefendPointsObjective
extends BaseObjective

const POINT_SCENE := preload("res://src/gameplay/objectives/defense_point.tscn")

var _defense_data: DefendPointsObjectiveData
var _director: ThreatDirector
var _active_point: DefensePoint
var _completed_points := 0


func configure(objective_data: ObjectiveData, context: Dictionary) -> void:
	super.configure(objective_data, context)
	_defense_data = objective_data as DefendPointsObjectiveData
	assert(_defense_data != null, "Defense objective requires DefendPointsObjectiveData.")
	_director = context.get("threat_director") as ThreatDirector
	required_progress = _defense_data.point_count * _defense_data.duration_per_point
	_spawn_next_point()


func _spawn_next_point() -> void:
	if _completed_points >= _defense_data.point_count:
		return
	_active_point = POINT_SCENE.instantiate() as DefensePoint
	_active_point.required_duration = _defense_data.duration_per_point
	_active_point.defense_radius = _defense_data.defense_radius
	add_child(_active_point)
	_active_point.position = _defense_data.point_positions[_completed_points] if _completed_points < _defense_data.point_positions.size() else Vector2.RIGHT.rotated(TAU * _completed_points / _defense_data.point_count) * 400.0
	_active_point.defense_started.connect(_on_defense_started)
	_active_point.defense_stopped.connect(_on_defense_stopped)
	_active_point.progress_changed.connect(_on_point_progress)
	_active_point.defended.connect(_on_point_defended)


func _on_defense_started() -> void:
	if _director != null:
		_director.set_objective_pressure(true)


func _on_defense_stopped() -> void:
	if _director != null:
		_director.set_objective_pressure(false)


func _on_point_progress(point_progress: float, _required: float) -> void:
	current_progress = _completed_points * _defense_data.duration_per_point + point_progress
	progress_changed.emit(current_progress, required_progress)


func _on_point_defended() -> void:
	if _director != null:
		_director.set_objective_pressure(false)
	_completed_points += 1
	current_progress = _completed_points * _defense_data.duration_per_point
	progress_changed.emit(current_progress, required_progress)
	_active_point.queue_free()
	if _completed_points >= _defense_data.point_count:
		complete()
	else:
		call_deferred("_spawn_next_point")
