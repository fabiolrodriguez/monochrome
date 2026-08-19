class_name EnergyCore
extends Area2D

signal carrying_changed(carried: bool)

@export var movement_multiplier := 0.85

var director: ThreatDirector
var is_carried := false
var _player: Player
var _near_player := false
var _pickup_locked := false
var _pulse := 0.0


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("objective_target")
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	if is_carried and is_instance_valid(_player):
		global_position = _player.global_position + Vector2(0, -14)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _pickup_locked or not event.is_action_pressed("interact"):
		return
	if is_carried or _near_player:
		set_carried(not is_carried)
		get_viewport().set_input_as_handled()


func set_carried(carried: bool) -> void:
	if is_carried == carried or not is_instance_valid(_player):
		return
	is_carried = carried
	_player.set_movement_modifier(&"energy_core", movement_multiplier if carried else 1.0)
	if director != null:
		director.set_objective_pressure(carried)
	if carried:
		remove_from_group("objective_target")
	else:
		global_position = _player.global_position
		add_to_group("objective_target")
	carrying_changed.emit(carried)


func complete_delivery(delivery_position: Vector2) -> void:
	set_carried(false)
	global_position = delivery_position
	_pickup_locked = true
	await get_tree().create_timer(0.8).timeout
	_pickup_locked = false


func seal_at(delivery_position: Vector2) -> void:
	set_carried(false)
	global_position = delivery_position
	_pickup_locked = true
	remove_from_group("objective_target")


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_near_player = true


func _on_body_exited(body: Node) -> void:
	if body is Player:
		_near_player = false


func _draw() -> void:
	var aura_radius := 13.0 + sin(_pulse * 3.0) * 2.0
	draw_circle(Vector2.ZERO, aura_radius, Color(0.25, 0.85, 1.0, 0.1))
	draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 24, Color("63dcff"), 1.0)
	draw_circle(Vector2.ZERO, 4.0, Color("63dcff"))
	draw_circle(Vector2.ZERO, 1.5, Color.WHITE)
