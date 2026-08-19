class_name HuntElitesObjective
extends BaseObjective

const MARKER_SCRIPT := preload("res://src/gameplay/objectives/elite_target_marker.gd")

var _hunt_data: HuntElitesObjectiveData
var _director: ThreatDirector
var _marker: Node2D


func configure(objective_data: ObjectiveData, context: Dictionary) -> void:
	super.configure(objective_data, context)
	_hunt_data = objective_data as HuntElitesObjectiveData
	assert(_hunt_data != null and _hunt_data.elite_data != null, "Hunt objective requires elite data.")
	_director = context.get("threat_director") as ThreatDirector
	required_progress = _hunt_data.elite_count


func begin() -> void:
	super.begin()
	_spawn_next_elite()


func _spawn_next_elite() -> void:
	if _director == null or current_progress >= required_progress:
		return
	var index := int(current_progress)
	var position := _hunt_data.elite_positions[index] if index < _hunt_data.elite_positions.size() else Vector2.RIGHT.rotated(TAU * index / required_progress) * 420.0
	var elite := _director.spawn_objective_enemy(_hunt_data.elite_data, position)
	if elite == null:
		return
	elite.defeated.connect(_on_elite_defeated)
	_marker = Node2D.new()
	_marker.set_script(MARKER_SCRIPT)
	_marker.add_to_group("objective_target")
	get_tree().current_scene.add_child.call_deferred(_marker)
	_marker.set_deferred("target", elite)


func _on_elite_defeated(_elite: Enemy) -> void:
	if is_instance_valid(_marker):
		_marker.queue_free()
	current_progress += 1.0
	progress_changed.emit(current_progress, required_progress)
	if current_progress >= required_progress:
		complete()
	else:
		call_deferred("_spawn_next_elite")
