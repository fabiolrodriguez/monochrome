extends Control

const ENEMY_ATLAS := preload("res://assets/art/dungeon_bw/dungeon_16x16_bw.png")
const ENEMY_CODEX := [
	preload("res://src/data/enemies/chaser.tres"),
	preload("res://src/data/enemies/shooter.tres"),
	preload("res://src/data/enemies/tank.tres"),
	preload("res://src/data/enemies/hive_drone.tres"),
	preload("res://src/data/enemies/elite_hunter.tres"),
]
const BOSS_CODEX := [
	preload("res://src/data/bosses/the_watcher.tres"),
	preload("res://src/data/bosses/the_machine.tres"),
	preload("res://src/data/bosses/the_stag.tres"),
	preload("res://src/data/bosses/the_mother.tres"),
	preload("res://src/data/bosses/the_drowned_one.tres"),
	preload("res://src/data/bosses/the_tower.tres"),
	preload("res://src/data/bosses/the_heart.tres"),
]
const ACHIEVEMENT_CATALOG: AchievementCatalog = preload("res://src/data/progression/default_achievements.tres")

@export var skill_tree: SkillTreeCatalog

@onready var coins_label: Label = $Panel/Layout/Coins
@onready var play_button: Button = $Panel/Layout/Play
@onready var progression_button: Button = $Panel/Layout/Progression
@onready var codex_button: Button = $Panel/Layout/Codex
@onready var statistics_button: Button = $Panel/Layout/Statistics
@onready var controls_button: Button = $Panel/Layout/Controls
@onready var settings_button: Button = $Panel/Layout/Settings
@onready var quit_button: Button = $Panel/Layout/Quit
@onready var controls_overlay: Control = $Controls
@onready var controls_back_button: Button = $Controls/Panel/Layout/Back
@onready var statistics_overlay: Control = $Statistics
@onready var statistics_summary: Label = $Statistics/Panel/Layout/Summary
@onready var statistics_back_button: Button = $Statistics/Panel/Layout/Back
@onready var codex_overlay: Control = $Codex
@onready var codex_enemies_button: Button = $Codex/Panel/Layout/Categories/Enemies
@onready var codex_bosses_button: Button = $Codex/Panel/Layout/Categories/Bosses
@onready var codex_achievements_button: Button = $Codex/Panel/Layout/Categories/Achievements
@onready var codex_entries: VBoxContainer = $Codex/Panel/Layout/Body/Entries
@onready var codex_portrait: TextureRect = $Codex/Panel/Layout/Body/Details/Portrait
@onready var codex_name: Label = $Codex/Panel/Layout/Body/Details/Name
@onready var codex_description: Label = $Codex/Panel/Layout/Body/Details/Description
@onready var codex_stats: Label = $Codex/Panel/Layout/Body/Details/Stats
@onready var codex_back_button: Button = $Codex/Panel/Layout/Back
@onready var level_select_overlay: Control = $LevelSelect
@onready var void_garden_button: Button = $LevelSelect/Panel/Layout/VoidGarden
@onready var dead_factory_button: Button = $LevelSelect/Panel/Layout/DeadFactory
@onready var white_forest_button: Button = $LevelSelect/Panel/Layout/WhiteForest
@onready var hive_button: Button = $LevelSelect/Panel/Layout/TheHive
@onready var black_lake_button: Button = $LevelSelect/Panel/Layout/BlackLake
@onready var broken_city_button: Button = $LevelSelect/Panel/Layout/BrokenCity
@onready var core_button: Button = $LevelSelect/Panel/Layout/TheCore
@onready var level_select_back_button: Button = $LevelSelect/Panel/Layout/Back
@onready var tree_overlay: Control = $SkillTree
@onready var tree_canvas: SkillTreeView = $SkillTree/Panel/TreeCanvas
@onready var tree_back_button: Button = $SkillTree/Panel/Back
@onready var tree_coins_label: Label = $SkillTree/Panel/Coins
@onready var zoom_out_button: Button = $SkillTree/Panel/Zoom/Out
@onready var zoom_in_button: Button = $SkillTree/Panel/Zoom/In
@onready var zoom_label: Label = $SkillTree/Panel/Zoom/Value
@onready var hint_label: Label = $SkillTree/Panel/Hint
@onready var settings_overlay: Control = $Settings
@onready var volume_slider: HSlider = $Settings/Panel/Layout/Volume
@onready var volume_value: Label = $Settings/Panel/Layout/VolumeHeader/Value
@onready var fullscreen_toggle: CheckButton = $Settings/Panel/Layout/Fullscreen
@onready var flash_intensity_select: OptionButton = $Settings/Panel/Layout/FlashIntensity
@onready var screen_shake_toggle: CheckButton = $Settings/Panel/Layout/ScreenShake
@onready var language_select: OptionButton = $Settings/Panel/Layout/Language
@onready var settings_back_button: Button = $Settings/Panel/Layout/Back
@onready var unlock_all_button: Button = $Settings/Panel/Layout/UnlockAll
@onready var reset_save_button: Button = $Settings/Panel/Layout/ResetSave
@onready var reset_confirmation: ConfirmationDialog = $ResetConfirmation
@onready var version_label: Label = $Version

var _node_buttons: Dictionary[StringName, SkillTreeNodeButton] = {}
var _inspected_node: SkillNodeData


func _ready() -> void:
	get_tree().paused = false
	AudioManager.play_ambience(&"menu")
	play_button.pressed.connect(_open_level_select)
	progression_button.pressed.connect(_open_skill_tree)
	codex_button.pressed.connect(_open_codex)
	statistics_button.pressed.connect(_open_statistics)
	controls_button.pressed.connect(_open_controls)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit_game)
	controls_back_button.pressed.connect(_close_controls)
	statistics_back_button.pressed.connect(_close_statistics)
	codex_enemies_button.pressed.connect(_show_codex_category.bind(0))
	codex_bosses_button.pressed.connect(_show_codex_category.bind(1))
	codex_achievements_button.pressed.connect(_show_codex_category.bind(2))
	codex_back_button.pressed.connect(_close_codex)
	settings_back_button.pressed.connect(_close_settings)
	unlock_all_button.pressed.connect(_unlock_all_levels)
	reset_save_button.pressed.connect(_request_reset_save)
	reset_confirmation.confirmed.connect(_confirm_reset_save)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	flash_intensity_select.item_selected.connect(_on_flash_intensity_selected)
	screen_shake_toggle.toggled.connect(SettingsManager.set_screen_shake)
	language_select.item_selected.connect(_on_language_selected)
	void_garden_button.pressed.connect(_start_level.bind(&"void_garden"))
	dead_factory_button.pressed.connect(_start_level.bind(&"dead_factory"))
	white_forest_button.pressed.connect(_start_level.bind(&"white_forest"))
	hive_button.pressed.connect(_start_level.bind(&"the_hive"))
	black_lake_button.pressed.connect(_start_level.bind(&"black_lake"))
	broken_city_button.pressed.connect(_start_level.bind(&"broken_city"))
	core_button.pressed.connect(_start_level.bind(&"the_core"))
	level_select_back_button.pressed.connect(_close_level_select)
	tree_back_button.pressed.connect(_close_skill_tree)
	zoom_out_button.pressed.connect(_change_zoom.bind(-0.15))
	zoom_in_button.pressed.connect(_change_zoom.bind(0.15))
	tree_canvas.zoom_changed.connect(_update_zoom_label)
	ProgressionManager.coins_changed.connect(_update_coins)
	ProgressionManager.progression_changed.connect(_refresh_skill_tree)
	ProgressionManager.evaluate_achievements(ACHIEVEMENT_CATALOG.achievements)
	_sync_platform_achievements()
	_update_coins(ProgressionManager.coins)
	_build_skill_tree()
	_configure_menu_focus()
	_change_zoom(0.0)
	tree_overlay.hide()
	controls_overlay.hide()
	statistics_overlay.hide()
	codex_overlay.hide()
	level_select_overlay.hide()
	settings_overlay.hide()
	version_label.text = "v%s" % str(ProjectSettings.get_setting("application/config/version", "dev"))
	play_button.grab_focus()


func _update_coins(total: int) -> void:
	coins_label.text = "%s: %d" % [tr("UI_COINS"), total]
	tree_coins_label.text = "%s: %d" % [tr("UI_COINS"), total]


func _open_level_select() -> void:
	_refresh_level_select()
	level_select_overlay.show()
	void_garden_button.grab_focus()


func _close_level_select() -> void:
	level_select_overlay.hide()
	play_button.grab_focus()


func _refresh_level_select() -> void:
	var dead_unlocked := ProgressionManager.unlocked_levels.has(&"dead_factory")
	var white_unlocked := ProgressionManager.unlocked_levels.has(&"white_forest")
	var hive_unlocked := ProgressionManager.unlocked_levels.has(&"the_hive")
	var lake_unlocked := ProgressionManager.unlocked_levels.has(&"black_lake")
	var city_unlocked := ProgressionManager.unlocked_levels.has(&"broken_city")
	var core_unlocked := ProgressionManager.unlocked_levels.has(&"the_core")
	void_garden_button.text = "%s\n%s" % [tr("LEVEL_VOID_GARDEN_NAME"), tr("UI_VOID_GARDEN_SUMMARY")]
	dead_factory_button.text = "%s\n%s" % [tr("LEVEL_DEAD_FACTORY_NAME"), tr("UI_DEAD_FACTORY_SUMMARY") if dead_unlocked else tr("UI_LEVEL_LOCKED")]
	dead_factory_button.disabled = not dead_unlocked
	dead_factory_button.focus_mode = Control.FOCUS_ALL if dead_unlocked else Control.FOCUS_NONE
	white_forest_button.text = "%s\n%s" % [tr("LEVEL_WHITE_FOREST_NAME"), tr("UI_WHITE_FOREST_SUMMARY") if white_unlocked else tr("UI_LEVEL_LOCKED")]
	white_forest_button.disabled = not white_unlocked
	white_forest_button.focus_mode = Control.FOCUS_ALL if white_unlocked else Control.FOCUS_NONE
	hive_button.text = "%s\n%s" % [tr("LEVEL_HIVE_NAME"), tr("UI_HIVE_SUMMARY") if hive_unlocked else tr("UI_LEVEL_LOCKED")]
	hive_button.disabled = not hive_unlocked
	hive_button.focus_mode = Control.FOCUS_ALL if hive_unlocked else Control.FOCUS_NONE
	black_lake_button.text = "%s\n%s" % [tr("LEVEL_BLACK_LAKE_NAME"), tr("UI_BLACK_LAKE_SUMMARY") if lake_unlocked else tr("UI_LEVEL_LOCKED")]
	black_lake_button.disabled = not lake_unlocked
	black_lake_button.focus_mode = Control.FOCUS_ALL if lake_unlocked else Control.FOCUS_NONE
	broken_city_button.text = "%s\n%s" % [tr("LEVEL_BROKEN_CITY_NAME"), tr("UI_BROKEN_CITY_SUMMARY") if city_unlocked else tr("UI_LEVEL_LOCKED")]
	broken_city_button.disabled = not city_unlocked
	broken_city_button.focus_mode = Control.FOCUS_ALL if city_unlocked else Control.FOCUS_NONE
	core_button.text = "%s\n%s" % [tr("LEVEL_CORE_NAME"), tr("UI_CORE_SUMMARY") if core_unlocked else tr("UI_LEVEL_LOCKED")]
	core_button.disabled = not core_unlocked
	core_button.focus_mode = Control.FOCUS_ALL if core_unlocked else Control.FOCUS_NONE
	_configure_level_select_focus()


func _start_level(level_id: StringName) -> void:
	if ProgressionManager.select_level(level_id):
		get_tree().change_scene_to_file("res://src/app/main.tscn")


func _open_skill_tree() -> void:
	_refresh_skill_tree()
	tree_overlay.show()
	tree_canvas.call_deferred("frame_all_nodes")
	var focus_target := tree_back_button as Control
	for node: SkillNodeData in skill_tree.nodes:
		var button := _node_buttons[node.id]
		if ProgressionManager.can_purchase_node(node):
			focus_target = button
			break
	focus_target.grab_focus()


func _close_skill_tree() -> void:
	tree_overlay.hide()
	progression_button.grab_focus()


func _open_controls() -> void:
	controls_overlay.show()
	controls_back_button.grab_focus()


func _close_controls() -> void:
	controls_overlay.hide()
	controls_button.grab_focus()


func _open_statistics() -> void:
	var total_seconds := floori(ProgressionManager.get_career_stat(&"play_time"))
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	statistics_summary.text = tr("UI_STATISTICS_SUMMARY") % [
		roundi(ProgressionManager.get_career_stat(&"runs")),
		roundi(ProgressionManager.get_career_stat(&"victories")),
		roundi(ProgressionManager.get_career_stat(&"failed_runs")),
		roundi(ProgressionManager.get_career_stat(&"enemies_defeated")),
		roundi(ProgressionManager.get_career_stat(&"damage_dealt")),
		roundi(ProgressionManager.get_career_stat(&"coins_collected")),
		roundi(ProgressionManager.get_career_stat(&"highest_level")),
		hours,
		minutes,
	]
	statistics_overlay.show()
	statistics_back_button.grab_focus()


func _close_statistics() -> void:
	statistics_overlay.hide()
	statistics_button.grab_focus()


func _open_codex() -> void:
	ProgressionManager.evaluate_achievements(ACHIEVEMENT_CATALOG.achievements)
	_sync_platform_achievements()
	codex_overlay.show()
	_show_codex_category(0)


func _close_codex() -> void:
	codex_overlay.hide()
	codex_button.grab_focus()


func _show_codex_category(category: int) -> void:
	for child: Node in codex_entries.get_children():
		child.free()
	var catalog: Array = ENEMY_CODEX
	if category == 1:
		catalog = BOSS_CODEX
	elif category == 2:
		catalog = ACHIEVEMENT_CATALOG.achievements
	var first_button: Button
	for entry: Resource in catalog:
		var entry_id := StringName(str(entry.get("id")))
		var name_key := StringName(str(entry.get("name_key")))
		if category == 2:
			name_key = StringName(str(entry.get("title_key")))
		var discovered := ProgressionManager.discovered_enemies.has(entry_id)
		if category == 1:
			discovered = ProgressionManager.discovered_bosses.has(entry_id)
		elif category == 2:
			discovered = ProgressionManager.unlocked_achievements.has(entry_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(104.0, 12.0)
		button.add_theme_font_size_override("font_size", 5)
		button.text = tr(name_key) if discovered or category == 2 else tr("UI_CODEX_UNKNOWN")
		if category == 2 and discovered:
			button.text = "[X] %s" % button.text
		button.pressed.connect(_show_codex_entry.bind(entry, category))
		button.focus_entered.connect(_show_codex_entry.bind(entry, category))
		codex_entries.add_child(button)
		if first_button == null:
			first_button = button
	codex_enemies_button.disabled = category == 0
	codex_bosses_button.disabled = category == 1
	codex_achievements_button.disabled = category == 2
	if first_button != null:
		_show_codex_entry(catalog.front(), category)
		first_button.grab_focus()


func _show_codex_entry(entry: Resource, category: int) -> void:
	var entry_id := StringName(str(entry.get("id")))
	var name_key := StringName(str(entry.get("name_key")))
	var description_key := StringName(str(entry.get("description_key")))
	if category == 2:
		_show_achievement_entry(entry as AchievementData)
		return
	var is_boss := category == 1
	var discovered := ProgressionManager.discovered_bosses.has(entry_id) if is_boss else ProgressionManager.discovered_enemies.has(entry_id)
	codex_portrait.texture = _boss_texture(entry as BossData) if is_boss else _enemy_texture(entry as EnemyData)
	codex_portrait.modulate = Color.WHITE if discovered else Color(0.09, 0.1, 0.12, 1.0)
	codex_name.text = tr(name_key) if discovered else tr("UI_CODEX_UNKNOWN")
	if not discovered:
		codex_description.text = tr("UI_CODEX_UNKNOWN_DESC")
		codex_stats.text = ""
		return
	codex_description.text = tr(description_key)
	if is_boss:
		var boss := entry as BossData
		codex_stats.text = tr("UI_CODEX_BOSS_STATS") % [roundi(boss.maximum_health), roundi(boss.contact_damage), boss.coin_reward]
	else:
		var enemy := entry as EnemyData
		codex_stats.text = tr("UI_CODEX_ENEMY_STATS") % [roundi(enemy.maximum_health), roundi(enemy.movement_speed), roundi(enemy.contact_damage)]


func _show_achievement_entry(achievement: AchievementData) -> void:
	var progress := minf(ProgressionManager.get_achievement_progress(achievement), achievement.target_value)
	var completed := ProgressionManager.unlocked_achievements.has(achievement.id)
	codex_portrait.texture = achievement.icon
	codex_portrait.modulate = Color("ffd84a") if completed else Color(0.55, 0.56, 0.6, 1.0)
	codex_name.text = tr(achievement.title_key)
	codex_description.text = tr(achievement.description_key)
	if completed:
		codex_stats.text = "%s\n%s" % [tr("UI_ACHIEVEMENT_COMPLETED"), tr("UI_ACHIEVEMENT_REWARD") % achievement.coin_reward]
	else:
		codex_stats.text = "%s\n%s" % [tr("UI_ACHIEVEMENT_PROGRESS") % [roundi(progress), roundi(achievement.target_value)], tr("UI_ACHIEVEMENT_REWARD") % achievement.coin_reward]


func _enemy_texture(enemy: EnemyData) -> Texture2D:
	var coordinate := Vector2i(9, 18)
	if enemy.is_elite:
		coordinate = Vector2i(11, 18)
	else:
		match enemy.behavior:
			EnemyData.Behavior.SHOOTER:
				coordinate = Vector2i(14, 18)
			EnemyData.Behavior.TANK:
				coordinate = Vector2i(12, 18)
	var texture := AtlasTexture.new()
	texture.atlas = ENEMY_ATLAS
	texture.region = Rect2(Vector2(coordinate * 16), Vector2(16, 16))
	return texture


func _boss_texture(boss: BossData) -> Texture2D:
	if boss == null or boss.scene == null:
		return null
	var preview := boss.scene.instantiate()
	var animated_sprite := preview.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var texture: Texture2D
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		texture = animated_sprite.sprite_frames.get_frame_texture(&"idle", 0)
	preview.free()
	return texture


func _open_settings() -> void:
	_refresh_settings()
	settings_overlay.show()
	volume_slider.grab_focus()


func _close_settings() -> void:
	settings_overlay.hide()
	settings_button.grab_focus()


func _refresh_settings() -> void:
	volume_slider.set_value_no_signal(SettingsManager.master_volume * 100.0)
	volume_value.text = "%d%%" % roundi(SettingsManager.master_volume * 100.0)
	fullscreen_toggle.set_pressed_no_signal(SettingsManager.fullscreen)
	flash_intensity_select.select(clampi(roundi(SettingsManager.flash_intensity * 2.0), 0, 2))
	screen_shake_toggle.set_pressed_no_signal(SettingsManager.screen_shake)
	var locale_index := SettingsManager.SUPPORTED_LOCALES.find(SettingsManager.locale)
	language_select.select(maxi(locale_index, 0))


func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)
	SettingsManager.set_master_volume(value / 100.0)


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func _on_flash_intensity_selected(index: int) -> void:
	SettingsManager.set_flash_intensity(clampf(float(index) * 0.5, 0.0, 1.0))


func _on_language_selected(index: int) -> void:
	if index < 0 or index >= SettingsManager.SUPPORTED_LOCALES.size():
		return
	SettingsManager.set_locale(SettingsManager.SUPPORTED_LOCALES[index])
	get_tree().reload_current_scene()


func _unlock_all_levels() -> void:
	ProgressionManager.unlock_all_levels_for_playtest()
	unlock_all_button.text = tr("UI_PLAYTEST_UNLOCKED")


func _request_reset_save() -> void:
	reset_confirmation.popup_centered()


func _confirm_reset_save() -> void:
	ProgressionManager.reset_progression()
	get_tree().reload_current_scene()


func _build_skill_tree() -> void:
	assert(skill_tree != null, "Main menu requires a SkillTreeCatalog.")
	tree_canvas.catalog = skill_tree
	for node: SkillNodeData in skill_tree.nodes:
		var button := SkillTreeNodeButton.new()
		button.configure(node)
		button.inspected.connect(_show_node_hint)
		button.pressed.connect(_purchase_node.bind(node))
		tree_canvas.add_child(button)
		tree_canvas.register_node(node, button)
		_node_buttons[node.id] = button
	_configure_skill_tree_focus()
	_refresh_skill_tree()


func _configure_menu_focus() -> void:
	play_button.focus_neighbor_top = play_button.get_path_to(quit_button)
	quit_button.focus_neighbor_bottom = quit_button.get_path_to(play_button)
	volume_slider.focus_neighbor_top = volume_slider.get_path_to(settings_back_button)
	settings_back_button.focus_neighbor_bottom = settings_back_button.get_path_to(volume_slider)
	settings_back_button.focus_neighbor_top = settings_back_button.get_path_to(reset_save_button)


func _configure_level_select_focus() -> void:
	var enabled_buttons: Array[Button] = [void_garden_button]
	for button: Button in [dead_factory_button, white_forest_button, hive_button, black_lake_button, broken_city_button, core_button]:
		if not button.disabled:
			enabled_buttons.append(button)
	var last_button: Button = enabled_buttons.back()
	void_garden_button.focus_neighbor_top = void_garden_button.get_path_to(level_select_back_button)
	last_button.focus_neighbor_bottom = last_button.get_path_to(level_select_back_button)
	level_select_back_button.focus_neighbor_top = level_select_back_button.get_path_to(last_button)
	level_select_back_button.focus_neighbor_bottom = level_select_back_button.get_path_to(void_garden_button)


func _configure_skill_tree_focus() -> void:
	var fallback: Button = null
	var lowest_y := -INF
	for node: SkillNodeData in skill_tree.nodes:
		var button := _node_buttons[node.id] as Button
		if node.tree_position.y > lowest_y:
			lowest_y = node.tree_position.y
			fallback = button
		var has_child := false
		for candidate: SkillNodeData in skill_tree.nodes:
			if candidate.prerequisites.has(node.id):
				has_child = true
				break
		if not has_child:
			button.focus_neighbor_bottom = button.get_path_to(tree_back_button)
	if fallback != null:
		tree_back_button.focus_neighbor_top = tree_back_button.get_path_to(fallback)


func _refresh_skill_tree() -> void:
	if skill_tree == null:
		return
	for node: SkillNodeData in skill_tree.nodes:
		var button := _node_buttons.get(node.id) as SkillTreeNodeButton
		if button == null:
			continue
		var is_owned := ProgressionManager.unlocked_skill_nodes.has(node.id)
		var prerequisites_met := true
		for prerequisite: StringName in node.prerequisites:
			if not ProgressionManager.unlocked_skill_nodes.has(prerequisite):
				prerequisites_met = false
		var affordable := ProgressionManager.coins >= node.cost
		var status := tr("UI_SKILL_OWNED") if is_owned else "%s · %s: %d" % [tr("UI_SKILL_AVAILABLE") if affordable else tr("UI_SKILL_NEED_COINS"), tr("UI_COST"), node.cost]
		if not is_owned and not prerequisites_met:
			status = tr("UI_SKILL_LOCKED")
		var hint := "%s\n%s\n%s" % [tr(node.title_key), tr(node.description_key), status]
		button.set_state(is_owned, prerequisites_met, affordable, hint)
	tree_canvas.queue_redraw()
	if _inspected_node != null:
		_show_node_hint(_inspected_node)


func _purchase_node(node: SkillNodeData) -> void:
	if not ProgressionManager.purchase_node(node):
		AudioManager.play_sfx(&"ui_error", -18.0, 0.15)
	ProgressionManager.evaluate_achievements(ACHIEVEMENT_CATALOG.achievements)
	_sync_platform_achievements()
	_show_node_hint(node)


func _sync_platform_achievements() -> void:
	PlatformAchievements.sync_catalog(ACHIEVEMENT_CATALOG, ProgressionManager.unlocked_achievements)


func _show_node_hint(node: SkillNodeData) -> void:
	_inspected_node = node
	var is_owned := ProgressionManager.is_node_unlocked(node.id)
	var prerequisites_met := true
	for prerequisite: StringName in node.prerequisites:
		if not ProgressionManager.is_node_unlocked(prerequisite):
			prerequisites_met = false
	var affordable := ProgressionManager.coins >= node.cost
	var status := tr("UI_SKILL_OWNED") if is_owned else "%s · %s: %d" % [tr("UI_SKILL_AVAILABLE") if affordable else tr("UI_SKILL_NEED_COINS"), tr("UI_COST"), node.cost]
	if not is_owned and not prerequisites_met:
		status = tr("UI_SKILL_LOCKED")
	hint_label.text = "%s — %s  [%s]" % [tr(node.title_key), tr(node.description_key), status]


func _change_zoom(delta: float) -> void:
	tree_canvas.set_zoom(tree_canvas.zoom + delta)


func _update_zoom_label(value: float) -> void:
	zoom_label.text = "%d%%" % roundi(value * 100.0)


func _input(event: InputEvent) -> void:
	if tree_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_skill_tree()
		get_viewport().set_input_as_handled()
	elif controls_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_controls()
		get_viewport().set_input_as_handled()
	elif statistics_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_statistics()
		get_viewport().set_input_as_handled()
	elif codex_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_codex()
		get_viewport().set_input_as_handled()
	elif level_select_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_level_select()
		get_viewport().set_input_as_handled()
	elif settings_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()
		get_viewport().set_input_as_handled()


func _quit_game() -> void:
	ProgressionManager.flush_save()
	get_tree().quit()
