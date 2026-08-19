extends Control

@export var skill_tree: SkillTreeCatalog

@onready var coins_label: Label = $Panel/Layout/Coins
@onready var play_button: Button = $Panel/Layout/Play
@onready var progression_button: Button = $Panel/Layout/Progression
@onready var controls_button: Button = $Panel/Layout/Controls
@onready var settings_button: Button = $Panel/Layout/Settings
@onready var quit_button: Button = $Panel/Layout/Quit
@onready var controls_overlay: Control = $Controls
@onready var controls_back_button: Button = $Controls/Panel/Layout/Back
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
	controls_button.pressed.connect(_open_controls)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit_game)
	controls_back_button.pressed.connect(_close_controls)
	settings_back_button.pressed.connect(_close_settings)
	unlock_all_button.pressed.connect(_unlock_all_levels)
	reset_save_button.pressed.connect(_request_reset_save)
	reset_confirmation.confirmed.connect(_confirm_reset_save)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
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
	_update_coins(ProgressionManager.coins)
	_build_skill_tree()
	_change_zoom(0.0)
	tree_overlay.hide()
	controls_overlay.hide()
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
	var locale_index := SettingsManager.SUPPORTED_LOCALES.find(SettingsManager.locale)
	language_select.select(maxi(locale_index, 0))


func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)
	SettingsManager.set_master_volume(value / 100.0)


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


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
	_refresh_skill_tree()


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
		var status := tr("UI_SKILL_OWNED") if is_owned else "%s: %d" % [tr("UI_COST"), node.cost]
		if not is_owned and not prerequisites_met:
			status = tr("UI_SKILL_LOCKED")
		var hint := "%s\n%s\n%s" % [tr(node.title_key), tr(node.description_key), status]
		button.set_state(is_owned, prerequisites_met and ProgressionManager.coins >= node.cost, hint)
	tree_canvas.queue_redraw()
	if _inspected_node != null:
		_show_node_hint(_inspected_node)


func _purchase_node(node: SkillNodeData) -> void:
	ProgressionManager.purchase_node(node)
	_show_node_hint(node)


func _show_node_hint(node: SkillNodeData) -> void:
	_inspected_node = node
	var is_owned := ProgressionManager.is_node_unlocked(node.id)
	var prerequisites_met := true
	for prerequisite: StringName in node.prerequisites:
		if not ProgressionManager.is_node_unlocked(prerequisite):
			prerequisites_met = false
	var status := tr("UI_SKILL_OWNED") if is_owned else "%s: %d" % [tr("UI_COST"), node.cost]
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
	elif level_select_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_level_select()
		get_viewport().set_input_as_handled()
	elif settings_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()
		get_viewport().set_input_as_handled()


func _quit_game() -> void:
	ProgressionManager.flush_save()
	get_tree().quit()
