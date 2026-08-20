class_name TransportEnergyObjective
extends BaseObjective

const CORE_SCENE := preload("res://src/gameplay/objectives/energy_core.tscn")
const STATION_SCENE := preload("res://src/gameplay/objectives/energy_station.tscn")

var _transport_data: TransportEnergyObjectiveData
var _core: EnergyCore
var _station: EnergyStation
var _director: ThreatDirector


func configure(objective_data: ObjectiveData, context: Dictionary) -> void:
	super.configure(objective_data, context)
	_transport_data = objective_data as TransportEnergyObjectiveData
	assert(_transport_data != null, "Transport objective requires TransportEnergyObjectiveData.")
	_director = context.get("threat_director") as ThreatDirector
	required_progress = _transport_data.destination_count
	_core = CORE_SCENE.instantiate() as EnergyCore
	_core.movement_multiplier = _transport_data.carried_movement_multiplier
	_core.director = _director
	add_child(_core)
	_core.position = _transport_data.energy_start_position
	_core.carrying_changed.connect(_on_carrying_changed)
	_spawn_next_station()


func begin() -> void:
	super.begin()
	set_instruction(&"OBJECTIVE_ENERGY_FIND")


func _spawn_next_station() -> void:
	if current_progress >= required_progress:
		return
	var index := int(current_progress)
	_station = STATION_SCENE.instantiate() as EnergyStation
	add_child(_station)
	_station.position = _transport_data.destination_positions[index] if index < _transport_data.destination_positions.size() else Vector2.RIGHT.rotated(TAU * index / required_progress) * 420.0
	_station.body_entered.connect(_on_station_body_entered)


func _on_station_body_entered(body: Node) -> void:
	if not body is Player or not _core.is_carried:
		return
	var delivered_position := _station.global_position
	_station.remove_from_group("objective_target")
	_station.queue_free()
	var is_final_delivery := current_progress + 1.0 >= required_progress
	if is_final_delivery:
		_core.seal_at(delivered_position)
	else:
		_core.complete_delivery(delivered_position)
	current_progress += 1.0
	progress_changed.emit(current_progress, required_progress)
	AudioManager.play_sfx(&"confirm", -8.0)
	if current_progress >= required_progress:
		complete()
	else:
		call_deferred("_spawn_next_station")


func _on_carrying_changed(carried: bool) -> void:
	set_instruction(&"OBJECTIVE_ENERGY_CARRY" if carried else &"OBJECTIVE_ENERGY_FIND")
