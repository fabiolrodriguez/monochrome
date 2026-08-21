extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 4


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open savegame for reading.")
		return _default_data()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Savegame is invalid; defaults will be used.")
		return _default_data()
	return _migrate(parsed as Dictionary)


func save_game(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open savegame for writing.")
		return false
	var payload := data.duplicate(true)
	payload["version"] = SAVE_VERSION
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	return true


func reset_game() -> bool:
	return save_game(_default_data())


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 0,
		"unlocked_levels": ["void_garden"],
		"completed_levels": [],
		"unlocked_skill_nodes": ["core"],
		"permanent_stats": {},
		"career_stats": {},
	}


func _migrate(data: Dictionary) -> Dictionary:
	var migrated := _default_data()
	# Save v1/v2 used "fragments" for the permanent currency.
	migrated["coins"] = maxi(int(data.get("coins", data.get("fragments", 0))), 0)
	migrated["unlocked_levels"] = data.get("unlocked_levels", migrated["unlocked_levels"])
	migrated["completed_levels"] = data.get("completed_levels", migrated["completed_levels"])
	migrated["unlocked_skill_nodes"] = data.get("unlocked_skill_nodes", migrated["unlocked_skill_nodes"])
	migrated["permanent_stats"] = data.get("permanent_stats", migrated["permanent_stats"])
	migrated["career_stats"] = data.get("career_stats", migrated["career_stats"])
	return migrated
