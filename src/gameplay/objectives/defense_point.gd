class_name DefensePoint
extends Area2D

signal defense_started
signal defense_stopped
signal progress_changed(current: float, required: float)
signal defended

@export var required_duration := 45.0
@export_range(24.0, 96.0, 1.0) var defense_radius := 31.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _elapsed := 0.0
var _player_inside := false
var _completed := false
var _pulse := 0.0


func _ready() -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		# The scene shape is shared by default, so duplicate it before applying objective-specific sizing.
		circle = circle.duplicate() as CircleShape2D
		circle.radius = defense_radius
		collision_shape.shape = circle
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("objective_target")
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	if _player_inside and not _completed:
		_elapsed = minf(_elapsed + delta, required_duration)
		progress_changed.emit(_elapsed, required_duration)
		if _elapsed >= required_duration:
			_completed = true
			remove_from_group("objective_target")
			defended.emit()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body is Player and not _completed:
		_player_inside = true
		defense_started.emit()


func _on_body_exited(body: Node) -> void:
	if body is Player and not _completed:
		_player_inside = false
		defense_stopped.emit()


func _draw() -> void:
	var ratio := _elapsed / maxf(required_duration, 1.0)
	var radius := defense_radius + sin(_pulse * 3.0) * 1.5
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.35, 0.2, 0.05))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color("aeb4bd"), 1.0)
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, Color("ff7a4d"), 2.0)
	draw_line(Vector2(-8, 0), Vector2(8, 0), Color.WHITE, 1.0)
	draw_line(Vector2(0, -8), Vector2(0, 8), Color.WHITE, 1.0)
