extends Node2D

@onready var player: Player = $Player
@onready var health_bar: HealthSegments = $HUD/Health
@onready var experience_bar: ProgressBar = $HUD/Experience
@onready var level_label: Label = $HUD/Level
@onready var death_panel: PanelContainer = $DeathUI/Panel
@onready var restart_button: Button = $DeathUI/Panel/Layout/Restart
@onready var result_title: Label = $DeathUI/Panel/Layout/Title
@onready var timer_label: Label = $HUD/Timer
@onready var level_controller: LevelController = $LevelController
@onready var objective_manager: ObjectiveManager = $ObjectiveManager
@onready var objective_label: Label = $HUD/Objective
@onready var objective_progress: ProgressBar = $HUD/ObjectiveProgress
@onready var boss_controller: BossController = $BossController
@onready var boss_name: Label = $HUD/BossName
@onready var boss_health: ProgressBar = $HUD/BossHealth
@onready var auto_fire_label: Label = $HUD/AutoFire
@onready var run_currency: RunCurrency = $RunCurrency
@onready var coins_label: Label = $HUD/Coins
@onready var main_menu_button: Button = $DeathUI/Panel/Layout/MainMenu
@onready var reward_label: Label = $DeathUI/Panel/Layout/Reward

var _objective_instruction_key: StringName = &""
var _boss_previous_health := -1.0
var _boss_health_tween: Tween
@onready var upgrade_controller: UpgradeController = $UpgradeController
@onready var telemetry: RunTelemetry = $RunTelemetry
@onready var summary_label: Label = $DeathUI/Panel/Layout/Summary


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_ambience(&"void_garden")
	var forest_level := level_controller.data.id == &"void_garden" or level_controller.data.id == &"white_forest"
	$PineObstacles.visible = forest_level
	$RuinWallDetails.visible = level_controller.data.id == &"void_garden" or level_controller.data.id == &"dead_factory"
	$IndustrialCaveDetails.visible = level_controller.data.id == &"dead_factory" or level_controller.data.id == &"the_hive" or level_controller.data.id == &"black_lake" or level_controller.data.id == &"broken_city" or level_controller.data.id == &"the_core"
	if not forest_level:
		for child: Node in $PineObstacles.get_children():
			var collision_body := child as CollisionObject2D
			if collision_body != null:
				collision_body.collision_layer = 0
				collision_body.collision_mask = 0
	player.health.health_changed.connect(_on_player_health_changed)
	player.experience.experience_changed.connect(_on_experience_changed)
	player.experience.level_changed.connect(_on_level_changed)
	player.died.connect(_on_player_died)
	player.auto_fire_changed.connect(_on_auto_fire_changed)
	level_controller.time_changed.connect(_on_level_time_changed)
	objective_manager.objective_progress_changed.connect(_on_objective_progress_changed)
	objective_manager.objective_completed.connect(_on_objective_completed)
	objective_manager.objective_failed.connect(_on_objective_failed)
	objective_manager.objective_instruction_changed.connect(_on_objective_instruction_changed)
	boss_controller.boss_spawned.connect(_on_boss_spawned)
	boss_controller.boss_health_changed.connect(_on_boss_health_changed)
	boss_controller.boss_defeated.connect(_on_boss_defeated)
	run_currency.coins_changed.connect(_on_run_coins_changed)
	SettingsManager.settings_changed.connect(_refresh_localized_hud)
	restart_button.pressed.connect(_restart_run)
	main_menu_button.pressed.connect(_return_to_main_menu)
	death_panel.hide()
	reward_label.hide()
	boss_name.hide()
	boss_health.hide()
	auto_fire_label.hide()
	_on_player_health_changed(player.health.current_health, player.health.maximum_health)
	_on_experience_changed(player.experience.current_experience, player.experience.required_experience)
	_on_level_changed(player.experience.level)
	_on_level_time_changed(level_controller.elapsed_time, level_controller.data.duration)
	_objective_instruction_key = objective_manager.active_objective.instruction_key
	objective_label.text = tr(_objective_instruction_key) if not _objective_instruction_key.is_empty() else tr(level_controller.data.objective.title_key)
	_on_run_coins_changed(run_currency.current_run_coins)


func _on_player_health_changed(current: float, maximum: float) -> void:
	health_bar.set_health(current, maximum)


func _on_experience_changed(current: float, required: float) -> void:
	experience_bar.max_value = required
	experience_bar.value = current


func _on_level_changed(level: int) -> void:
	level_label.text = str(level)
	telemetry.set_level(level)


func _on_auto_fire_changed(enabled: bool) -> void:
	auto_fire_label.visible = enabled


func _on_run_coins_changed(current_run: int) -> void:
	coins_label.text = "%s: %d" % [tr("UI_COINS_SHORT"), current_run]
	telemetry.set_coins(current_run)


func _refresh_localized_hud() -> void:
	_on_run_coins_changed(run_currency.current_run_coins)
	if objective_manager.active_objective.is_complete:
		objective_label.text = tr("OBJECTIVE_DEFEAT_BOSS") % tr(level_controller.data.boss.name_key)
	elif not _objective_instruction_key.is_empty():
		objective_label.text = tr(_objective_instruction_key)
	else:
		objective_label.text = tr(level_controller.data.objective.title_key)
	if boss_controller.active_boss != null:
		boss_name.text = tr(boss_controller.active_boss.data.name_key)


func _on_player_died() -> void:
	AudioManager.play_sfx(&"enemy_defeat", -7.0)
	upgrade_controller.finalize_run()
	ProgressionManager.flush_save()
	result_title.text = tr("UI_RUN_ENDED")
	reward_label.hide()
	_show_run_summary(&"player_defeated")
	death_panel.show()
	get_tree().paused = true
	restart_button.grab_focus()


func _on_level_time_changed(elapsed: float, duration: float) -> void:
	var remaining_seconds := ceili(maxf(duration - elapsed, 0.0))
	var minutes := remaining_seconds / 60
	var seconds := remaining_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _on_objective_progress_changed(_data: ObjectiveData, current: float, required: float) -> void:
	objective_progress.max_value = required
	objective_progress.value = current


func _on_objective_instruction_changed(_data: ObjectiveData, text_key: StringName) -> void:
	_objective_instruction_key = text_key
	objective_label.text = tr(text_key)


func _on_objective_completed(_data: ObjectiveData) -> void:
	_objective_instruction_key = &""
	objective_label.text = tr("OBJECTIVE_DEFEAT_BOSS") % tr(level_controller.data.boss.name_key)
	objective_progress.hide()


func _on_objective_failed(_data: ObjectiveData) -> void:
	upgrade_controller.finalize_run()
	result_title.text = tr("UI_OBJECTIVE_FAILED")
	reward_label.hide()
	_show_run_summary(&"objective_failed")
	death_panel.show()
	get_tree().paused = true
	restart_button.grab_focus()


func _on_boss_spawned(boss: TheWatcher) -> void:
	AudioManager.play_sfx(&"boss_spawn", -8.0)
	boss_name.text = tr(boss.data.name_key)
	boss_name.show()
	boss_health.show()
	_boss_previous_health = boss.health.current_health
	var shake := get_tree().get_first_node_in_group("screen_shake") as ScreenShake
	if shake != null:
		shake.add_trauma(0.5)


func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_health.max_value = maximum
	boss_health.value = current
	if _boss_previous_health >= 0.0 and current < _boss_previous_health:
		if _boss_health_tween != null and _boss_health_tween.is_valid():
			_boss_health_tween.kill()
		boss_health.modulate = Color.WHITE.lerp(Color("ffd84a"), SettingsManager.flash_intensity)
		_boss_health_tween = create_tween()
		_boss_health_tween.tween_property(boss_health, "modulate", Color.WHITE, 0.12)
	_boss_previous_health = current


func _on_boss_defeated() -> void:
	var shake := get_tree().get_first_node_in_group("screen_shake") as ScreenShake
	if shake != null:
		shake.add_trauma(0.7)
	upgrade_controller.finalize_run()
	var boss_data := level_controller.data.boss
	player.experience.add_experience(boss_data.experience_reward)
	player.health.heal(boss_data.healing_reward)
	ProgressionManager.complete_level(level_controller.data.id, level_controller.data.next_levels)
	boss_name.hide()
	boss_health.hide()
	result_title.text = tr("UI_STAGE_COMPLETE")
	reward_label.text = tr("UI_BOSS_REWARD") % [roundi(boss_data.experience_reward), boss_data.coin_reward, roundi(boss_data.healing_reward)]
	reward_label.show()
	_show_run_summary(&"stage_complete")
	AudioManager.play_sfx(&"confirm", -6.0)
	death_panel.show()
	get_tree().paused = true
	restart_button.grab_focus()


func _show_run_summary(reason: StringName) -> void:
	telemetry.finish(reason, level_controller.data.id)
	summary_label.text = tr("UI_RUN_SUMMARY") % [
		telemetry.get_formatted_time(), telemetry.enemies_defeated, telemetry.highest_level,
		roundi(telemetry.damage_dealt), roundi(telemetry.damage_received),
		telemetry.coins_collected, telemetry.upgrades_collected,
	]


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_main_menu() -> void:
	ProgressionManager.flush_save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/app/main_menu.tscn")
