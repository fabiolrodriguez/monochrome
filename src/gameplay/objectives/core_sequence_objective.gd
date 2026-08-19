class_name CoreSequenceObjective
extends BaseObjective

const CORE_SCENE := preload("res://src/gameplay/objectives/hive_nest.tscn")
const POINT_SCENE := preload("res://src/gameplay/objectives/defense_point.tscn")

enum Stage { CORES, TERMINAL, EVENT }

var _sequence_data: CoreSequenceObjectiveData
var _director: ThreatDirector
var _stage := Stage.CORES
var _cores_destroyed := 0
var _event_elapsed := 0.0
var _terminal: DefensePoint


func configure(objective_data: ObjectiveData, context: Dictionary) -> void:
	super.configure(objective_data, context)
	_sequence_data = objective_data as CoreSequenceObjectiveData
	assert(_sequence_data != null, "Core sequence requires CoreSequenceObjectiveData.")
	_director = context.get("threat_director") as ThreatDirector
	required_progress = 4.0
	for index: int in 2:
		var core := CORE_SCENE.instantiate() as HiveNest
		core.maximum_health = _sequence_data.core_health
		core.spawn_interval = 999.0
		add_child(core)
		core.position = _sequence_data.core_positions[index] if index < _sequence_data.core_positions.size() else Vector2(-300 + index * 600, -260)
		core.destroyed.connect(_on_core_destroyed)


func update_level_time(_elapsed: float, _duration: float) -> void:
	if _stage != Stage.EVENT or is_complete:
		return
	_event_elapsed = minf(_event_elapsed + get_process_delta_time(), _sequence_data.final_event_duration)
	current_progress = 3.0 + _event_elapsed / _sequence_data.final_event_duration
	progress_changed.emit(current_progress, required_progress)
	if _event_elapsed >= _sequence_data.final_event_duration:
		if _director != null:
			_director.set_objective_pressure(false)
		complete()


func _on_core_destroyed(_core: HiveNest) -> void:
	_cores_destroyed += 1
	current_progress = float(_cores_destroyed)
	progress_changed.emit(current_progress, required_progress)
	if _cores_destroyed >= 2:
		_stage = Stage.TERMINAL
		call_deferred("_spawn_terminal")


func _spawn_terminal() -> void:
	_terminal = POINT_SCENE.instantiate() as DefensePoint
	_terminal.required_duration = _sequence_data.terminal_duration
	add_child(_terminal)
	_terminal.position = _sequence_data.terminal_position
	_terminal.defense_started.connect(_on_terminal_started)
	_terminal.defense_stopped.connect(_on_terminal_stopped)
	_terminal.progress_changed.connect(_on_terminal_progress)
	_terminal.defended.connect(_on_terminal_defended)


func _on_terminal_started() -> void:
	if _director != null:
		_director.set_objective_pressure(true)


func _on_terminal_stopped() -> void:
	if _director != null:
		_director.set_objective_pressure(false)


func _on_terminal_progress(value: float, required: float) -> void:
	current_progress = 2.0 + value / required
	progress_changed.emit(current_progress, required_progress)


func _on_terminal_defended() -> void:
	if _director != null:
		_director.set_objective_pressure(true)
	_terminal.queue_free()
	_stage = Stage.EVENT
	current_progress = 3.0
	progress_changed.emit(current_progress, required_progress)
