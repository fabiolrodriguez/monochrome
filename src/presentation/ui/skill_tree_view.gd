class_name SkillTreeView
extends Control

signal zoom_changed(value: float)

var catalog: SkillTreeCatalog
var node_buttons: Dictionary[StringName, Button] = {}
var zoom := 1.0
var camera_position := Vector2.ZERO
var _dragging := false
var _drag_origin := Vector2.ZERO
var _camera_origin := Vector2.ZERO

const NODE_SIZE := 30.0
const MIN_ZOOM := 0.5
const MAX_ZOOM := 1.35
const VIEW_PADDING := 8.0


func _ready() -> void:
	resized.connect(_update_node_transforms)
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func register_node(node: SkillNodeData, button: Button) -> void:
	node_buttons[node.id] = button
	_apply_node_transform(node, button)
	queue_redraw()


func set_zoom(value: float) -> void:
	set_zoom_at(value, size * 0.5)


func set_zoom_at(value: float, anchor: Vector2) -> void:
	var old_zoom := zoom
	zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	if not is_zero_approx(old_zoom):
		var world_anchor := camera_position + (anchor - size * 0.5) / old_zoom
		camera_position = world_anchor - (anchor - size * 0.5) / zoom
	_update_node_transforms()
	zoom_changed.emit(zoom)


func frame_all_nodes() -> void:
	if catalog == null or catalog.nodes.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var bounds := Rect2(catalog.nodes[0].tree_position, Vector2.ZERO)
	for node: SkillNodeData in catalog.nodes:
		bounds = bounds.expand(node.tree_position)
	camera_position = bounds.get_center()
	var usable := size - Vector2.ONE * VIEW_PADDING * 2.0
	var required := bounds.size + Vector2.ONE * NODE_SIZE
	zoom = clampf(minf(usable.x / required.x, usable.y / required.y), MIN_ZOOM, 1.0)
	_update_node_transforms()
	zoom_changed.emit(zoom)


func _update_node_transforms() -> void:
	if catalog == null:
		return
	for node: SkillNodeData in catalog.nodes:
		var button := node_buttons.get(node.id) as Button
		if button != null:
			_apply_node_transform(node, button)
	queue_redraw()


func _apply_node_transform(node: SkillNodeData, button: Button) -> void:
	button.size = Vector2.ONE * NODE_SIZE * zoom
	button.position = _world_to_screen(node.tree_position) - button.size * 0.5


func _world_to_screen(world_position: Vector2) -> Vector2:
	return (world_position - camera_position) * zoom + size * 0.5


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			set_zoom_at(zoom + 0.1, mouse_event.position)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			set_zoom_at(zoom - 0.1, mouse_event.position)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT or mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mouse_event.pressed
			if _dragging:
				_drag_origin = mouse_event.position
				_camera_origin = camera_position
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		camera_position = _camera_origin - (motion.position - _drag_origin) / zoom
		_update_node_transforms()
		accept_event()


func _draw() -> void:
	if catalog == null:
		return
	for node: SkillNodeData in catalog.nodes:
		var target := node_buttons.get(node.id) as Button
		if target == null:
			continue
		for prerequisite_id: StringName in node.prerequisites:
			var source := node_buttons.get(prerequisite_id) as Button
			if source == null:
				continue
			var source_owned := ProgressionManager.is_node_unlocked(prerequisite_id)
			var target_owned := ProgressionManager.is_node_unlocked(node.id)
			var path_unlocked := true
			for required_id: StringName in node.prerequisites:
				if not ProgressionManager.is_node_unlocked(required_id):
					path_unlocked = false
					break
			var color := Color("f0f1f3") if source_owned and target_owned else (Color("858a94") if path_unlocked else Color("25282e"))
			var width := 2.0 if source_owned and target_owned else 1.5
			draw_line(source.position + source.size * 0.5, target.position + target.size * 0.5, color, width)
