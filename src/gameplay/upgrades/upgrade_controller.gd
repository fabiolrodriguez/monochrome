class_name UpgradeController
extends Node

signal evolution_unlocked(name_key: StringName)

@export var player_path: NodePath
@export var level_up_ui_path: NodePath
@export var pool: Array[UpgradeData] = []

var _player: Player
var _level_up_ui: LevelUpUI
var _levels: Dictionary[StringName, int] = {}
var _pending_choices := 0
var _random := RandomNumberGenerator.new()
var _rerolls_remaining := 0
var _accepting_choices := true
var _evolutions: Array[StringName] = []
var _queued_evolutions: Array[StringName] = []

const EVOLUTION_CHEST_SCENE := preload("res://src/gameplay/pickups/upgrade_chest.tscn")

const EVOLUTIONS := {
	&"void_storm": {"name_key": &"EVOLUTION_VOID_STORM_NAME", "first": &"radial_pulse", "first_level": 2, "second": &"multishot", "second_level": 1},
	&"chain_wisp": {"name_key": &"EVOLUTION_CHAIN_WISP_NAME", "first": &"seeker", "first_level": 2, "second": &"ricochet", "second_level": 1},
	&"orbital_aegis": {"name_key": &"EVOLUTION_ORBITAL_AEGIS_NAME", "first": &"orbital_ward", "first_level": 2, "second": &"barrier", "second_level": 1},
}


func _ready() -> void:
	_levels.clear()
	_evolutions.clear()
	_queued_evolutions.clear()
	_pending_choices = 0
	_rerolls_remaining = 1 if ProgressionManager.is_node_unlocked(&"reroll") else 0
	_player = get_node(player_path) as Player
	_level_up_ui = get_node(level_up_ui_path) as LevelUpUI
	assert(_player != null and _level_up_ui != null)
	_random.randomize()
	_player.experience.leveled_up.connect(_on_leveled_up)
	_level_up_ui.upgrade_selected.connect(_on_upgrade_selected)
	_level_up_ui.reroll_requested.connect(_on_reroll_requested)
	_level_up_ui.call_deferred("set_rerolls_remaining", _rerolls_remaining)


func _on_leveled_up(_new_level: int) -> void:
	if not _accepting_choices:
		return
	_pending_choices += 1
	if not _level_up_ui.is_open():
		_present_next_choice()


func _present_next_choice() -> void:
	var options := _roll_options(3)
	if options.is_empty():
		_pending_choices = 0
		get_tree().paused = false
		return
	_level_up_ui.present(options, _levels)
	AudioManager.play_sfx(&"upgrade_reveal", -18.0, 0.12)
	_level_up_ui.set_rerolls_remaining(_rerolls_remaining)


func _roll_options(count: int) -> Array[UpgradeData]:
	var available: Array[UpgradeData] = []
	for upgrade: UpgradeData in pool:
		var is_unlocked := upgrade.unlock_requirement == &"" or ProgressionManager.is_node_unlocked(upgrade.unlock_requirement)
		if is_unlocked and _levels.get(upgrade.id, 0) < upgrade.max_level:
			available.append(upgrade)
	var result: Array[UpgradeData] = []
	while not available.is_empty() and result.size() < count:
		var selected := _weighted_pick(available)
		result.append(selected)
		available.erase(selected)
	return result


func _weighted_pick(options: Array[UpgradeData]) -> UpgradeData:
	var total_weight := 0.0
	for option: UpgradeData in options:
		total_weight += _effective_weight(option)
	var roll := _random.randf_range(0.0, total_weight)
	for option: UpgradeData in options:
		roll -= _effective_weight(option)
		if roll <= 0.0:
			return option
	return options.back()


func _effective_weight(option: UpgradeData) -> float:
	# Luck preserves authored weights while progressively favoring uncommon and rarer offers.
	var rarity_bonus := 1.0 + _player.luck * float(option.rarity) * 0.75
	return option.weight * rarity_bonus


func roll_world_upgrade() -> UpgradeData:
	var options := _roll_options(1)
	return options[0] if not options.is_empty() else null


func grant_world_upgrade(upgrade: UpgradeData) -> bool:
	if upgrade == null:
		return false
	var is_unlocked := upgrade.unlock_requirement == &"" or ProgressionManager.is_node_unlocked(upgrade.unlock_requirement)
	if not is_unlocked or _levels.get(upgrade.id, 0) >= upgrade.max_level:
		upgrade = roll_world_upgrade()
	if upgrade == null:
		return false
	_levels[upgrade.id] = _levels.get(upgrade.id, 0) + 1
	_player.apply_upgrade(upgrade)
	_record_upgrade()
	AudioManager.play_sfx(&"confirm", -7.0)
	return true


func grant_ready_evolution() -> bool:
	for evolution_id: StringName in EVOLUTIONS:
		if _evolutions.has(evolution_id) or not _is_evolution_ready(evolution_id):
			continue
		_evolutions.append(evolution_id)
		_queued_evolutions.erase(evolution_id)
		_player.apply_evolution(evolution_id)
		evolution_unlocked.emit(StringName(EVOLUTIONS[evolution_id]["name_key"]))
		AudioManager.play_sfx(&"level_up", -11.0, 0.15)
		var queued_chest := get_tree().get_first_node_in_group("evolution_chests")
		if queued_chest != null:
			queued_chest.queue_free()
		return true
	return false


func get_build_summary() -> String:
	var lines: Array[String] = []
	for upgrade: UpgradeData in pool:
		var level: int = _levels.get(upgrade.id, 0)
		if level > 0:
			lines.append("%s  %d/%d" % [tr(upgrade.name_key), level, upgrade.max_level])
	for evolution_id: StringName in EVOLUTIONS:
		var recipe: Dictionary = EVOLUTIONS[evolution_id]
		var name_key := StringName(recipe["name_key"])
		if _evolutions.has(evolution_id):
			lines.append("★ %s" % tr(name_key))
		else:
			var first := _find_upgrade(StringName(recipe["first"]))
			var second := _find_upgrade(StringName(recipe["second"]))
			var status := tr("UI_EVOLUTION_READY") if _is_evolution_ready(evolution_id) else "%s %d/%d + %s %d/%d" % [
				tr(first.name_key), _levels.get(first.id, 0), int(recipe["first_level"]),
				tr(second.name_key), _levels.get(second.id, 0), int(recipe["second_level"]),
			]
			lines.append("◇ %s  [%s]" % [tr(name_key), status])
	if lines.is_empty():
		return tr("UI_BUILD_EMPTY")
	return "\n".join(lines)


func _is_evolution_ready(evolution_id: StringName) -> bool:
	var recipe: Dictionary = EVOLUTIONS[evolution_id]
	return _levels.get(recipe["first"], 0) >= int(recipe["first_level"]) and _levels.get(recipe["second"], 0) >= int(recipe["second_level"])


func _find_upgrade(upgrade_id: StringName) -> UpgradeData:
	for upgrade: UpgradeData in pool:
		if upgrade.id == upgrade_id:
			return upgrade
	return null


func _on_upgrade_selected(upgrade: UpgradeData) -> void:
	AudioManager.play_sfx(&"confirm", -10.0)
	_levels[upgrade.id] = _levels.get(upgrade.id, 0) + 1
	_player.apply_upgrade(upgrade)
	_record_upgrade()
	_pending_choices = maxi(_pending_choices - 1, 0)
	if _pending_choices > 0:
		_present_next_choice()
	else:
		_level_up_ui.close()


func _on_reroll_requested() -> void:
	if _rerolls_remaining <= 0 or not _level_up_ui.is_open():
		return
	_rerolls_remaining -= 1
	_present_next_choice()


func finalize_run() -> void:
	_accepting_choices = false
	_pending_choices = 0
	if _level_up_ui.is_open():
		_level_up_ui.close()


func _record_upgrade() -> void:
	var telemetry := get_tree().get_first_node_in_group("run_telemetry") as RunTelemetry
	if telemetry != null:
		telemetry.record_upgrade()
	_check_evolution_chests()


func _check_evolution_chests() -> void:
	for evolution_id: StringName in EVOLUTIONS:
		if _evolutions.has(evolution_id) or _queued_evolutions.has(evolution_id) or not _is_evolution_ready(evolution_id):
			continue
		var chest := EVOLUTION_CHEST_SCENE.instantiate() as UpgradeChest
		if chest == null:
			return
		chest.evolution_only = true
		var container := get_tree().get_first_node_in_group("pickup_container")
		if container == null:
			container = get_tree().current_scene
		container.add_child(chest)
		var angle := TAU * float(_queued_evolutions.size()) / 3.0
		chest.global_position = _player.global_position + Vector2.RIGHT.rotated(angle) * 26.0
		_queued_evolutions.append(evolution_id)
