class_name PlayerProjectile
extends Area2D

signal released(projectile: PlayerProjectile)

@export_range(1.0, 1000.0, 1.0) var speed: float = 220.0
@export_range(0.1, 20.0, 0.1) var lifetime: float = 2.0
@export_range(0.0, 1000.0, 1.0) var damage: float = 10.0

var _direction := Vector2.RIGHT
var _base_speed: float
var _base_damage: float
var _remaining_lifetime := 0.0
var _piercing_hits := 0
var _ricochets := 0
var _active := false
var _is_critical := false


func _ready() -> void:
	_base_speed = speed
	_base_damage = damage
	body_entered.connect(_on_body_entered)
	queue_redraw()
	_deactivate(false)


func activate(spawn_transform: Transform2D, damage_scale: float, speed_scale: float, piercing: int, ricochets: int, is_critical: bool = false) -> void:
	global_transform = spawn_transform
	_direction = Vector2.RIGHT.rotated(global_rotation)
	damage = _base_damage * damage_scale
	speed = _base_speed * speed_scale
	_piercing_hits = piercing
	_ricochets = ricochets
	_is_critical = is_critical
	_remaining_lifetime = lifetime
	_active = true
	show()
	queue_redraw()
	set_physics_process(true)
	set_deferred("monitoring", true)
	$CollisionShape2D.set_deferred("disabled", false)


func _physics_process(delta: float) -> void:
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		_deactivate()
		return
	global_position += _direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if _piercing_hits > 0:
		_piercing_hits -= 1
		return
	if _ricochets > 0 and _redirect_to_nearest_enemy(body):
		_ricochets -= 1
		return
	_deactivate()


func _redirect_to_nearest_enemy(excluded: Node2D) -> bool:
	var nearest: Node2D
	var nearest_distance := INF
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node2D
		if enemy == null or enemy == excluded or not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	if nearest == null:
		return false
	_direction = global_position.direction_to(nearest.global_position)
	global_rotation = _direction.angle()
	return true


func _deactivate(notify_pool := true) -> void:
	if not _active and notify_pool:
		return
	_active = false
	hide()
	set_physics_process(false)
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	if notify_pool:
		released.emit(self)


func _draw() -> void:
	# Blue identifies the initial kinetic projectile family.
	var core_color := Color("ffd84a") if _is_critical else Color("4aa3ff")
	var trail_color := Color("fff0a6") if _is_critical else Color("b9dcff")
	draw_circle(Vector2.ZERO, 3.0 if _is_critical else 2.0, core_color)
	draw_line(Vector2(-5.0 if _is_critical else -4.0, 0.0), Vector2.ZERO, trail_color, 1.0)
