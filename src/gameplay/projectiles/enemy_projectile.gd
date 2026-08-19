class_name EnemyProjectile
extends Area2D

@export_range(1.0, 1000.0, 1.0) var speed: float = 75.0
@export_range(0.1, 20.0, 0.1) var lifetime: float = 4.0
@export_range(0.0, 100.0, 1.0) var damage: float = 10.0

var _direction := Vector2.RIGHT


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta


func set_direction(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		_direction = direction.normalized()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color("ff4b4b"))
	draw_circle(Vector2.ZERO, 1.0, Color("ffd0d0"))

