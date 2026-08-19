extends Node

signal coins_changed(total: int)
signal progression_changed

var coins := 0
var unlocked_levels: Array[StringName] = []
var completed_levels: Array[StringName] = []
var unlocked_skill_nodes: Array[StringName] = []
var permanent_stats: Dictionary[StringName, float] = {}
var _save_timer: Timer


func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.wait_time = 0.5
	_save_timer.one_shot = true
	_save_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_save_timer)
	_save_timer.timeout.connect(_save_progression)
	_load_progression()


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	if _save_timer.is_stopped():
		_save_timer.start()
	coins_changed.emit(coins)


func complete_level(level_id: StringName, next_levels: Array[StringName]) -> void:
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
	for next_level: StringName in next_levels:
		if not unlocked_levels.has(next_level):
			unlocked_levels.append(next_level)
	flush_save()
	progression_changed.emit()


func can_purchase_node(node: SkillNodeData) -> bool:
	if unlocked_skill_nodes.has(node.id) or coins < node.cost:
		return false
	for prerequisite: StringName in node.prerequisites:
		if not unlocked_skill_nodes.has(prerequisite):
			return false
	return true


func purchase_node(node: SkillNodeData) -> bool:
	if not can_purchase_node(node):
		return false
	coins -= node.cost
	unlocked_skill_nodes.append(node.id)
	if node.node_type == SkillNodeData.NodeType.STAT and node.stat_key != &"":
		permanent_stats[node.stat_key] = permanent_stats.get(node.stat_key, 0.0) + node.stat_value
	flush_save()
	coins_changed.emit(coins)
	progression_changed.emit()
	return true


func get_permanent_stat(stat_key: StringName) -> float:
	return permanent_stats.get(stat_key, 0.0)


func is_node_unlocked(node_id: StringName) -> bool:
	return unlocked_skill_nodes.has(node_id)


func flush_save() -> void:
	if _save_timer != null:
		_save_timer.stop()
	_save_progression()


func _load_progression() -> void:
	var data := SaveManager.load_game()
	coins = maxi(int(data.get("coins", 0)), 0)
	unlocked_levels.clear()
	var saved_unlocked: Array = data.get("unlocked_levels", [])
	for level_id: Variant in saved_unlocked:
		unlocked_levels.append(StringName(str(level_id)))
	completed_levels.clear()
	var saved_completed: Array = data.get("completed_levels", [])
	for level_id: Variant in saved_completed:
		completed_levels.append(StringName(str(level_id)))
	unlocked_skill_nodes.clear()
	var saved_nodes: Array = data.get("unlocked_skill_nodes", ["core"])
	for node_id: Variant in saved_nodes:
		unlocked_skill_nodes.append(StringName(str(node_id)))
	if not unlocked_skill_nodes.has(&"core"):
		unlocked_skill_nodes.append(&"core")
	permanent_stats.clear()
	var saved_stats: Dictionary = data.get("permanent_stats", {})
	for stat_key: Variant in saved_stats:
		var migrated_key := StringName(str(stat_key))
		if migrated_key == &"fragment_gain":
			migrated_key = &"coin_gain"
		permanent_stats[migrated_key] = float(saved_stats[stat_key])
	coins_changed.emit(coins)


func _save_progression() -> void:
	SaveManager.save_game({
		"coins": coins,
		"unlocked_levels": _to_string_array(unlocked_levels),
		"completed_levels": _to_string_array(completed_levels),
		"unlocked_skill_nodes": _to_string_array(unlocked_skill_nodes),
		"permanent_stats": _serialize_stats(),
	})


func _to_string_array(values: Array[StringName]) -> Array[String]:
	var serialized: Array[String] = []
	for value: StringName in values:
		serialized.append(str(value))
	return serialized


func _serialize_stats() -> Dictionary:
	var serialized := {}
	for stat_key: StringName in permanent_stats:
		serialized[str(stat_key)] = permanent_stats[stat_key]
	return serialized
