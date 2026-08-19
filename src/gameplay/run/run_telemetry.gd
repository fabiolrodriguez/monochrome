class_name RunTelemetry
extends Node

const HISTORY_PATH := "user://run_history.jsonl"

var active_time := 0.0
var enemies_defeated := 0
var damage_dealt := 0.0
var damage_received := 0.0
var coins_collected := 0
var upgrades_collected := 0
var highest_level := 1
var _finished := false


func _process(delta: float) -> void:
	if not _finished:
		active_time += delta


func record_damage_dealt(amount: float) -> void:
	damage_dealt += maxf(amount, 0.0)


func record_damage_received(amount: float) -> void:
	damage_received += maxf(amount, 0.0)


func record_defeat() -> void:
	enemies_defeated += 1


func record_upgrade() -> void:
	upgrades_collected += 1


func set_coins(total: int) -> void:
	coins_collected = maxi(total, 0)


func set_level(level: int) -> void:
	highest_level = maxi(highest_level, level)


func finish(reason: StringName, level_id: StringName) -> void:
	if _finished:
		return
	_finished = true
	var file: FileAccess
	if FileAccess.file_exists(HISTORY_PATH):
		file = FileAccess.open(HISTORY_PATH, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	else:
		file = FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write run telemetry history.")
		return
	file.store_line(JSON.stringify({
		"timestamp": Time.get_unix_time_from_system(),
		"build_version": str(ProjectSettings.get_setting("application/config/version", "dev")),
		"level": str(level_id),
		"reason": str(reason),
		"active_time": active_time,
		"enemies_defeated": enemies_defeated,
		"damage_dealt": damage_dealt,
		"damage_received": damage_received,
		"coins_collected": coins_collected,
		"upgrades_collected": upgrades_collected,
		"highest_level": highest_level,
	}))


func get_formatted_time() -> String:
	var total_seconds := floori(active_time)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
