class_name RunCurrency
extends Node

signal coins_changed(current_run: int)

@export var boss_controller_path: NodePath
@export var level_controller_path: NodePath

var current_run_coins := 0
var _level_controller: LevelController
var _coin_remainder := 0.0


func _ready() -> void:
	var boss_controller := get_node(boss_controller_path) as BossController
	_level_controller = get_node(level_controller_path) as LevelController
	assert(boss_controller != null and _level_controller != null)
	boss_controller.boss_defeated.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	collect_coins(_level_controller.data.boss.coin_reward)


func collect_coins(amount: int) -> void:
	if amount <= 0:
		return
	var multiplier := 1.0 + ProgressionManager.get_permanent_stat(&"coin_gain")
	var adjusted_amount := float(amount) * multiplier + _coin_remainder
	var awarded := floori(adjusted_amount)
	_coin_remainder = adjusted_amount - float(awarded)
	current_run_coins += awarded
	ProgressionManager.add_coins(awarded)
	coins_changed.emit(current_run_coins)
