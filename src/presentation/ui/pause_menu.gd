class_name PauseMenu
extends CanvasLayer

@export var level_up_panel_path: NodePath
@export var run_result_panel_path: NodePath
@export var map_overlay_path: NodePath

@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/Panel/Layout/Resume
@onready var restart_button: Button = $Overlay/Panel/Layout/Restart
@onready var main_menu_button: Button = $Overlay/Panel/Layout/MainMenu
@onready var settings_button: Button = $Overlay/Panel/Layout/Settings
@onready var settings_panel: PanelContainer = $Overlay/SettingsPanel
@onready var volume_slider: HSlider = $Overlay/SettingsPanel/Layout/Volume
@onready var volume_value: Label = $Overlay/SettingsPanel/Layout/VolumeHeader/Value
@onready var fullscreen_toggle: CheckButton = $Overlay/SettingsPanel/Layout/Fullscreen
@onready var flash_intensity_select: OptionButton = $Overlay/SettingsPanel/Layout/FlashIntensity
@onready var screen_shake_toggle: CheckButton = $Overlay/SettingsPanel/Layout/ScreenShake
@onready var language_select: OptionButton = $Overlay/SettingsPanel/Layout/Language
@onready var settings_back_button: Button = $Overlay/SettingsPanel/Layout/Back

var _level_up_panel: Control
var _run_result_panel: Control
var _map_overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_level_up_panel = get_node(level_up_panel_path) as Control
	_run_result_panel = get_node(run_result_panel_path) as Control
	_map_overlay = get_node(map_overlay_path) as Control
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(_restart_run)
	main_menu_button.pressed.connect(_return_to_main_menu)
	settings_button.pressed.connect(_open_settings)
	settings_back_button.pressed.connect(_close_settings)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_toggle.toggled.connect(SettingsManager.set_fullscreen)
	flash_intensity_select.item_selected.connect(_on_flash_intensity_selected)
	screen_shake_toggle.toggled.connect(SettingsManager.set_screen_shake)
	language_select.item_selected.connect(_on_language_selected)
	settings_panel.hide()
	overlay.hide()
	_configure_focus()


func _configure_focus() -> void:
	resume_button.focus_neighbor_top = resume_button.get_path_to(main_menu_button)
	main_menu_button.focus_neighbor_bottom = main_menu_button.get_path_to(resume_button)
	volume_slider.focus_neighbor_top = volume_slider.get_path_to(settings_back_button)
	settings_back_button.focus_neighbor_bottom = settings_back_button.get_path_to(volume_slider)
	settings_back_button.focus_neighbor_top = settings_back_button.get_path_to(language_select)


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			_close_settings()
		else:
			resume()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("pause") or event.is_echo():
		return
	if settings_panel.visible:
		_close_settings()
	elif is_open():
		resume()
	elif not _has_blocking_modal():
		pause()
	get_viewport().set_input_as_handled()


func pause() -> void:
	settings_panel.hide()
	$Overlay/Panel.show()
	overlay.show()
	get_tree().paused = true
	resume_button.grab_focus()


func resume() -> void:
	overlay.hide()
	get_tree().paused = false


func _open_settings() -> void:
	volume_slider.set_value_no_signal(SettingsManager.master_volume * 100.0)
	volume_value.text = "%d%%" % roundi(SettingsManager.master_volume * 100.0)
	fullscreen_toggle.set_pressed_no_signal(SettingsManager.fullscreen)
	flash_intensity_select.select(clampi(roundi(SettingsManager.flash_intensity * 2.0), 0, 2))
	screen_shake_toggle.set_pressed_no_signal(SettingsManager.screen_shake)
	language_select.select(maxi(SettingsManager.SUPPORTED_LOCALES.find(SettingsManager.locale), 0))
	$Overlay/Panel.hide()
	settings_panel.show()
	volume_slider.grab_focus()


func _close_settings() -> void:
	settings_panel.hide()
	$Overlay/Panel.show()
	settings_button.grab_focus()


func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)
	SettingsManager.set_master_volume(value / 100.0)


func _on_language_selected(index: int) -> void:
	if index >= 0 and index < SettingsManager.SUPPORTED_LOCALES.size():
		SettingsManager.set_locale(SettingsManager.SUPPORTED_LOCALES[index])


func _on_flash_intensity_selected(index: int) -> void:
	SettingsManager.set_flash_intensity(clampf(float(index) * 0.5, 0.0, 1.0))


func is_open() -> bool:
	return overlay.visible


func _has_blocking_modal() -> bool:
	return (_level_up_panel != null and _level_up_panel.visible) or (_run_result_panel != null and _run_result_panel.visible) or (_map_overlay != null and _map_overlay.visible)


func _restart_run() -> void:
	overlay.hide()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_main_menu() -> void:
	overlay.hide()
	ProgressionManager.flush_save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/app/main_menu.tscn")
