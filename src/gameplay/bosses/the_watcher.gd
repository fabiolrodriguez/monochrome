class_name TheWatcher
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal phase_changed(phase: int)
signal defeated

@export var data: BossData
@export var projectile_scene: PackedScene

@onready var health: HealthComponent = $Health
@onready var attack_timer: Timer = $AttackTimer

var _player: Player
var _phase := 0
var _pattern_step := 0
var _rotation_offset := 0.0


func _ready() -> void:
	assert(data != null, "TheWatcher requires BossData.")
	_player = get_tree().get_first_node_in_group("player") as Player
	health.maximum_health = data.maximum_health
	health.current_health = data.maximum_health
	health.health_changed.connect(_on_health_changed)
	health.depleted.connect(_on_depleted)
	attack_timer.timeout.connect(_attack)
	attack_timer.start()
	health_changed.emit(health.current_health, health.maximum_health)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		velocity = Vector2.ZERO
		return
	var offset := _player.global_position - global_position
	if offset.length() > 115.0:
		velocity = offset.normalized() * data.movement_speed
	elif offset.length() < 80.0:
		velocity = -offset.normalized() * data.movement_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_apply_contact_damage()


func take_damage(amount: float) -> void:
	health.damage(amount)


func _attack() -> void:
	if not is_instance_valid(_player):
		return
	_pattern_step += 1
	match _phase:
		0:
			_fire_radial(8, _rotation_offset)
		1:
			if _pattern_step % 2 == 0:
				_fire_radial(10, _rotation_offset)
			else:
				_fire_aimed_spread(5, 0.16)
		2:
			_fire_radial(12, _rotation_offset)
			_fire_aimed_spread(3, 0.2)
	_rotation_offset += 0.13


func _fire_radial(count: int, angle_offset: float) -> void:
	for index: int in count:
		var direction := Vector2.RIGHT.rotated(angle_offset + TAU * float(index) / float(count))
		_spawn_projectile(direction)


func _fire_aimed_spread(count: int, spacing: float) -> void:
	var base_angle := (_player.global_position - global_position).angle()
	var center := float(count - 1) * 0.5
	for index: int in count:
		_spawn_projectile(Vector2.RIGHT.rotated(base_angle + (float(index) - center) * spacing))


func _spawn_projectile(direction: Vector2) -> void:
	var projectile := projectile_scene.instantiate() as EnemyProjectile
	if projectile == null:
		return
	projectile.speed = data.projectile_speed
	projectile.damage = data.projectile_damage
	var container := get_tree().get_first_node_in_group("projectile_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(projectile)
	projectile.global_position = global_position
	projectile.set_direction(direction)


func _on_health_changed(current: float, maximum: float) -> void:
	health_changed.emit(current, maximum)
	var ratio := current / maximum
	var next_phase := 0
	if ratio <= data.phase_thresholds[1]:
		next_phase = 2
	elif ratio <= data.phase_thresholds[0]:
		next_phase = 1
	if next_phase != _phase:
		_phase = next_phase
		attack_timer.wait_time = [1.6, 1.15, 0.8][_phase]
		phase_changed.emit(_phase)
		queue_redraw()


func _apply_contact_damage() -> void:
	for collision_index: int in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider() as Player
		if collider != null:
			collider.take_damage(data.contact_damage)


func _on_depleted() -> void:
	attack_timer.stop()
	defeated.emit()
	queue_free()


func _draw() -> void:
	var outline := Color("d9dadd")
	if _phase == 2:
		outline = Color.WHITE
	draw_circle(Vector2.ZERO, 18.0, outline)
	draw_circle(Vector2.ZERO, 14.0, Color("111318"))
	draw_circle(Vector2.ZERO, 8.0, outline)
	draw_circle(Vector2.ZERO, 4.0, Color("111318"))
	draw_circle(Vector2.ZERO, 2.0, Color("ff4b4b"))

