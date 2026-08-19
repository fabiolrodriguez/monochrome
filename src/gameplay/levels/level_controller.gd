class_name LevelController
extends Node

signal time_changed(elapsed: float, duration: float)
signal segment_changed(index: int)
signal level_time_reached

@export var data: LevelData
@export var level_catalog: Array[LevelData] = []
@export var threat_director_path: NodePath

var elapsed_time := 0.0
var _current_segment := -1
var _completed := false
var _director: ThreatDirector


func _ready() -> void:
	for candidate: LevelData in level_catalog:
		if candidate != null and candidate.id == ProgressionManager.selected_level_id:
			data = candidate
			break
	assert(data != null, "LevelController requires LevelData.")
	_director = get_node(threat_director_path) as ThreatDirector
	assert(_director != null, "LevelController requires a ThreatDirector.")
	_director.configure_pool(data.enemy_pool, data.elite_pool)
	_update_segment(true)
	time_changed.emit(elapsed_time, data.duration)


func begin_boss_encounter() -> void:
	_completed = true
	_director.stop_spawning()


func _process(delta: float) -> void:
	if _completed:
		return
	elapsed_time = minf(elapsed_time + delta, data.duration)
	_update_segment(false)
	time_changed.emit(elapsed_time, data.duration)
	if elapsed_time >= data.duration:
		_completed = true
		_director.stop_spawning()
		level_time_reached.emit()


func _update_segment(force: bool) -> void:
	if data.spawn_segments.is_empty():
		return
	var progress := elapsed_time / data.duration
	var selected_index := 0
	for index: int in data.spawn_segments.size():
		if progress >= data.spawn_segments[index].starts_at_ratio:
			selected_index = index
	if not force and selected_index == _current_segment:
		return
	_current_segment = selected_index
	var segment := data.spawn_segments[_current_segment]
	_director.set_pressure(segment.budget_multiplier, segment.spawn_interval_multiplier, segment.maximum_active_enemies)
	segment_changed.emit(_current_segment)
