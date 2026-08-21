class_name FactoryGenerator
extends Area2D

signal activation_started
signal activation_stopped
signal activated

@export var activation_duration := 2.5

var _player_inside := false
var _progress := 0.0
var _active := false


func _ready() -> void:
	add_to_group("objective_target")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _process(delta: float) -> void:
	if _active or not _player_inside:
		return
	_progress += delta
	queue_redraw()
	if _progress >= activation_duration:
		_active = true
		remove_from_group("objective_target")
		modulate = Color("ffd84a")
		activated.emit()


func _on_body_entered(body: Node) -> void:
	if body is Player and not _active:
		_player_inside = true
		activation_started.emit()


func _on_body_exited(body: Node) -> void:
	if body is Player and not _active:
		_player_inside = false
		_progress = 0.0
		activation_stopped.emit()
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 25.0, Color(0.7, 0.7, 0.72, 0.12), false, 1.0)
	if _active:
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 32, Color("ffd84a"), 2.0)
	elif _progress > 0.0:
		draw_arc(Vector2.ZERO, 25.0, -PI * 0.5, -PI * 0.5 + TAU * _progress / activation_duration, 32, Color.WHITE, 2.0)
