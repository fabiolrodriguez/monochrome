class_name SurviveObjective
extends BaseObjective


func configure(objective_data: ObjectiveData, context: Dictionary) -> void:
	super.configure(objective_data, context)
	var survive_data := objective_data as SurviveObjectiveData
	assert(survive_data != null, "SurviveObjective requires SurviveObjectiveData.")
	var level_duration: float = context.get("level_duration", 1.0)
	required_progress = survive_data.required_duration if survive_data.required_duration > 0.0 else level_duration


func update_level_time(elapsed: float, _duration: float) -> void:
	if is_complete or is_failed:
		return
	current_progress = minf(elapsed, required_progress)
	progress_changed.emit(current_progress, required_progress)
	if current_progress >= required_progress:
		complete()

