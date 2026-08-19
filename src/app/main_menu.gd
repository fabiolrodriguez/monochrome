extends Control

@export var skill_tree: SkillTreeCatalog

@onready var coins_label: Label = $Panel/Layout/Coins
@onready var play_button: Button = $Panel/Layout/Play
@onready var progression_button: Button = $Panel/Layout/Progression
@onready var controls_button: Button = $Panel/Layout/Controls
@onready var quit_button: Button = $Panel/Layout/Quit
@onready var controls_overlay: Control = $Controls
@onready var controls_back_button: Button = $Controls/Panel/Layout/Back
@onready var tree_overlay: Control = $SkillTree
@onready var tree_canvas: SkillTreeView = $SkillTree/Panel/TreeCanvas
@onready var tree_back_button: Button = $SkillTree/Panel/Back
@onready var tree_coins_label: Label = $SkillTree/Panel/Coins
@onready var zoom_out_button: Button = $SkillTree/Panel/Zoom/Out
@onready var zoom_in_button: Button = $SkillTree/Panel/Zoom/In
@onready var zoom_label: Label = $SkillTree/Panel/Zoom/Value
@onready var hint_label: Label = $SkillTree/Panel/Hint

var _node_buttons: Dictionary[StringName, SkillTreeNodeButton] = {}
var _inspected_node: SkillNodeData


func _ready() -> void:
	get_tree().paused = false
	AudioManager.play_ambience(&"menu")
	play_button.pressed.connect(_start_run)
	progression_button.pressed.connect(_open_skill_tree)
	controls_button.pressed.connect(_open_controls)
	quit_button.pressed.connect(_quit_game)
	controls_back_button.pressed.connect(_close_controls)
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
	play_button.grab_focus()


func _update_coins(total: int) -> void:
	coins_label.text = "%s: %d" % [tr("UI_COINS"), total]
	tree_coins_label.text = "%s: %d" % [tr("UI_COINS"), total]


func _start_run() -> void:
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


func _quit_game() -> void:
	ProgressionManager.flush_save()
	get_tree().quit()
