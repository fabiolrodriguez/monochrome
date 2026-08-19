class_name UpgradeController
extends Node

@export var player_path: NodePath
@export var level_up_ui_path: NodePath
@export var pool: Array[UpgradeData] = []

var _player: Player
var _level_up_ui: LevelUpUI
var _levels: Dictionary[StringName, int] = {}
var _pending_choices := 0
var _random := RandomNumberGenerator.new()
var _rerolls_remaining := 0


func _ready() -> void:
	_levels.clear()
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
		total_weight += option.weight
	var roll := _random.randf_range(0.0, total_weight)
	for option: UpgradeData in options:
		roll -= option.weight
		if roll <= 0.0:
			return option
	return options.back()


func _on_upgrade_selected(upgrade: UpgradeData) -> void:
	AudioManager.play_sfx(&"confirm", -10.0)
	_levels[upgrade.id] = _levels.get(upgrade.id, 0) + 1
	_player.apply_upgrade(upgrade)
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
