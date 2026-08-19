class_name MapMenu
extends CanvasLayer

@export var pause_overlay_path: NodePath
@export var level_up_panel_path: NodePath
@export var run_result_panel_path: NodePath

@onready var overlay: Control = $Overlay

var _pause_overlay: Control
var _level_up_panel: Control
var _run_result_panel: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_overlay = get_node(pause_overlay_path) as Control
	_level_up_panel = get_node(level_up_panel_path) as Control
	_run_result_panel = get_node(run_result_panel_path) as Control
	overlay.hide()


func _input(event: InputEvent) -> void:
	if not _is_map_input(event):
		return
	if overlay.visible:
		close()
	elif not _has_blocking_modal():
		open()
	get_viewport().set_input_as_handled()


func _is_map_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo and (key_event.keycode == KEY_TAB or key_event.physical_keycode == KEY_TAB)
	return event.is_action_pressed("map")


func open() -> void:
	overlay.show()
	$Overlay/MapView.queue_redraw()
	get_tree().paused = true


func close() -> void:
	overlay.hide()
	get_tree().paused = false


func _has_blocking_modal() -> bool:
	return _pause_overlay.visible or _level_up_panel.visible or _run_result_panel.visible
