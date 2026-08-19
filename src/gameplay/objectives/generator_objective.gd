class_name GeneratorObjective
extends BaseObjective

const GENERATOR_SCENE := preload("res://src/gameplay/objectives/factory_generator.tscn")

var _director: ThreatDirector
var _activating_count := 0


func configure(objective_data: ObjectiveData, context: Dictionary) -> void:
	super.configure(objective_data, context)
	var generator_data := objective_data as GeneratorObjectiveData
	assert(generator_data != null, "GeneratorObjective requires GeneratorObjectiveData.")
	required_progress = generator_data.generator_count
	_director = context.get("threat_director") as ThreatDirector
	for index: int in generator_data.generator_count:
		var generator := GENERATOR_SCENE.instantiate() as FactoryGenerator
		add_child(generator)
		generator.position = generator_data.generator_positions[index] if index < generator_data.generator_positions.size() else Vector2.RIGHT.rotated(TAU * index / generator_data.generator_count) * 380.0
		generator.activation_duration = generator_data.activation_duration
		generator.activation_started.connect(_on_activation_started)
		generator.activation_stopped.connect(_on_activation_stopped)
		generator.activated.connect(_on_generator_activated)


func _on_activation_started() -> void:
	_activating_count += 1
	if _director != null:
		_director.set_objective_pressure(true)


func _on_activation_stopped() -> void:
	_activating_count = maxi(_activating_count - 1, 0)
	if _director != null and _activating_count == 0:
		_director.set_objective_pressure(false)


func _on_generator_activated() -> void:
	_activating_count = maxi(_activating_count - 1, 0)
	current_progress += 1.0
	progress_changed.emit(current_progress, required_progress)
	if _director != null and _activating_count == 0:
		_director.set_objective_pressure(false)
	if current_progress >= required_progress:
		complete()
