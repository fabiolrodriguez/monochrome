extends Node2D

@onready var player: Player = $Player
@onready var health_bar: ProgressBar = $HUD/Health
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


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_ambience(&"void_garden")
	player.health.health_changed.connect(_on_player_health_changed)
	player.experience.experience_changed.connect(_on_experience_changed)
	player.experience.level_changed.connect(_on_level_changed)
	player.died.connect(_on_player_died)
	player.auto_fire_changed.connect(_on_auto_fire_changed)
	level_controller.time_changed.connect(_on_level_time_changed)
	objective_manager.objective_progress_changed.connect(_on_objective_progress_changed)
	objective_manager.objective_completed.connect(_on_objective_completed)
	boss_controller.boss_spawned.connect(_on_boss_spawned)
	boss_controller.boss_health_changed.connect(_on_boss_health_changed)
	boss_controller.boss_defeated.connect(_on_boss_defeated)
	run_currency.coins_changed.connect(_on_run_coins_changed)
	restart_button.pressed.connect(_restart_run)
	main_menu_button.pressed.connect(_return_to_main_menu)
	death_panel.hide()
	boss_name.hide()
	boss_health.hide()
	auto_fire_label.hide()
	_on_player_health_changed(player.health.current_health, player.health.maximum_health)
	_on_experience_changed(player.experience.current_experience, player.experience.required_experience)
	_on_level_changed(player.experience.level)
	_on_level_time_changed(level_controller.elapsed_time, level_controller.data.duration)
	objective_label.text = tr(level_controller.data.objective.title_key)
	_on_run_coins_changed(run_currency.current_run_coins)


func _on_player_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_experience_changed(current: float, required: float) -> void:
	experience_bar.max_value = required
	experience_bar.value = current


func _on_level_changed(level: int) -> void:
	level_label.text = str(level)


func _on_auto_fire_changed(enabled: bool) -> void:
	auto_fire_label.visible = enabled


func _on_run_coins_changed(current_run: int) -> void:
	coins_label.text = "%s: %d" % [tr("UI_COINS_SHORT"), current_run]


func _on_player_died() -> void:
	AudioManager.play_sfx(&"enemy_defeat", -7.0)
	ProgressionManager.flush_save()
	result_title.text = tr("UI_RUN_ENDED")
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


func _on_objective_completed(_data: ObjectiveData) -> void:
	objective_label.text = tr("OBJECTIVE_DEFEAT_WATCHER")
	objective_progress.hide()


func _on_boss_spawned(boss: TheWatcher) -> void:
	AudioManager.play_sfx(&"boss_spawn", -8.0)
	boss_name.text = tr(boss.data.name_key)
	boss_name.show()
	boss_health.show()


func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_health.max_value = maximum
	boss_health.value = current


func _on_boss_defeated() -> void:
	ProgressionManager.complete_level(level_controller.data.id, level_controller.data.next_levels)
	boss_name.hide()
	boss_health.hide()
	result_title.text = tr("UI_STAGE_COMPLETE")
	death_panel.show()
	get_tree().paused = true
	restart_button.grab_focus()


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_main_menu() -> void:
	ProgressionManager.flush_save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/app/main_menu.tscn")
