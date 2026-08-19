class_name PauseMenu
extends CanvasLayer

@export var level_up_panel_path: NodePath
@export var run_result_panel_path: NodePath
@export var map_overlay_path: NodePath

@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/Panel/Layout/Resume
@onready var restart_button: Button = $Overlay/Panel/Layout/Restart
@onready var main_menu_button: Button = $Overlay/Panel/Layout/MainMenu

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
	overlay.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or event.is_echo():
		return
	if is_open():
		resume()
	elif not _has_blocking_modal():
		pause()
	get_viewport().set_input_as_handled()


func pause() -> void:
	overlay.show()
	get_tree().paused = true
	resume_button.grab_focus()


func resume() -> void:
	overlay.hide()
	get_tree().paused = false


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
