class_name PlayerProjectile
extends Area2D

@export_range(1.0, 1000.0, 1.0) var speed: float = 220.0
@export_range(0.1, 20.0, 0.1) var lifetime: float = 2.0

var _direction := Vector2.RIGHT


func _ready() -> void:
	_direction = Vector2.RIGHT.rotated(global_rotation)
	queue_redraw()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta


func _draw() -> void:
	# Blue identifies the initial kinetic projectile family.
	draw_circle(Vector2.ZERO, 2.0, Color("4aa3ff"))
	draw_line(Vector2(-4.0, 0.0), Vector2.ZERO, Color("b9dcff"), 1.0)

