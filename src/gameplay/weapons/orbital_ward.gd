class_name OrbitalWard
extends Area2D

var damage := 8.0
var _touching_bodies: Dictionary[Node2D, float] = {}
var _block_flash := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_block_flash = maxf(_block_flash - delta, 0.0)
	for body: Node2D in _touching_bodies.keys():
		if not is_instance_valid(body):
			_touching_bodies.erase(body)
			continue
		var cooldown: float = _touching_bodies[body] - delta
		if cooldown <= 0.0:
			_damage_body(body)
			cooldown = 0.45
		_touching_bodies[body] = cooldown
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_touching_bodies[body] = 0.0


func _on_body_exited(body: Node2D) -> void:
	_touching_bodies.erase(body)


func _on_area_entered(area: Area2D) -> void:
	if area is EnemyProjectile:
		area.queue_free()
		_block_flash = 0.12
		AudioManager.play_sfx(&"impact_hit", -29.0, 0.08)


func _damage_body(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)


func _draw() -> void:
	var color := Color.WHITE if _block_flash > 0.0 else Color("63dcff")
	draw_circle(Vector2.ZERO, 4.0, Color("08090b"))
	draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 12, color, 2.0)
	draw_circle(Vector2.ZERO, 1.5, color)

