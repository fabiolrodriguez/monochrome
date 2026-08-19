class_name Enemy
extends CharacterBody2D

signal defeated(enemy: Enemy)

@export var data: EnemyData
@export var enemy_projectile_scene: PackedScene
@export var experience_pickup_scene: PackedScene
@export var coin_pickup_scene: PackedScene

@onready var health: HealthComponent = $Health
@onready var shot_cooldown: Timer = $ShotCooldown

var _target: Player
var _hit_flash_remaining := 0.0


func _ready() -> void:
	assert(data != null, "Enemy requires an EnemyData resource.")
	_target = get_tree().get_first_node_in_group("player") as Player
	health.depleted.connect(_on_depleted)
	health.maximum_health = data.maximum_health
	health.current_health = data.maximum_health
	shot_cooldown.wait_time = data.shot_interval
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = maxf(_hit_flash_remaining - delta, 0.0)
		queue_redraw()
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	var to_target := _target.global_position - global_position
	match data.behavior:
		EnemyData.Behavior.CHASER, EnemyData.Behavior.TANK:
			velocity = to_target.normalized() * data.movement_speed
		EnemyData.Behavior.SHOOTER:
			velocity = _shooter_velocity(to_target)
			if shot_cooldown.is_stopped():
				_shoot(to_target.normalized())
	move_and_slide()
	_apply_contact_damage()


func take_damage(amount: float) -> void:
	health.damage(amount)
	_hit_flash_remaining = 0.08
	queue_redraw()


func _shooter_velocity(to_target: Vector2) -> Vector2:
	var distance := to_target.length()
	if distance < data.preferred_distance - data.distance_tolerance:
		return -to_target.normalized() * data.movement_speed
	if distance > data.preferred_distance + data.distance_tolerance:
		return to_target.normalized() * data.movement_speed
	return Vector2.ZERO


func _shoot(direction: Vector2) -> void:
	if enemy_projectile_scene == null:
		return
	var projectile := enemy_projectile_scene.instantiate() as EnemyProjectile
	if projectile == null:
		return
	var container := get_tree().get_first_node_in_group("projectile_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(projectile)
	projectile.global_position = global_position
	projectile.set_direction(direction)
	shot_cooldown.start()


func _apply_contact_damage() -> void:
	for collision_index: int in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider() as Player
		if collider != null:
			collider.take_damage(data.contact_damage)


func _on_depleted() -> void:
	AudioManager.play_sfx(&"enemy_defeat", -20.0, 0.06)
	_drop_experience()
	_try_drop_coin()
	defeated.emit(self)
	queue_free()


func _drop_experience() -> void:
	if experience_pickup_scene == null:
		return
	var pickup := experience_pickup_scene.instantiate() as ExperiencePickup
	if pickup == null:
		return
	pickup.value = data.experience_value
	var container := get_tree().get_first_node_in_group("pickup_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(pickup)
	pickup.global_position = global_position


func _try_drop_coin() -> void:
	if coin_pickup_scene == null or randf() > data.coin_drop_chance:
		return
	var coin := coin_pickup_scene.instantiate() as CoinPickup
	if coin == null:
		return
	coin.value = data.coin_value
	var container := get_tree().get_first_node_in_group("pickup_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(coin)
	coin.global_position = global_position


func _draw() -> void:
	if data == null:
		return
	if data.is_elite:
		draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color("ffd84a"), 2.0)
		draw_polyline(PackedVector2Array([Vector2(-6, -10), Vector2(-3, -14), Vector2(0, -10), Vector2(3, -14), Vector2(6, -10)]), Color("ffd84a"), 1.5)
	var body_color := Color("9fcfff") if _hit_flash_remaining > 0.0 else Color.WHITE
	match data.behavior:
		EnemyData.Behavior.CHASER:
			draw_rect(Rect2(-5.0, -5.0, 10.0, 10.0), body_color)
			draw_rect(Rect2(-2.0, -2.0, 4.0, 4.0), Color.BLACK)
		EnemyData.Behavior.SHOOTER:
			draw_circle(Vector2.ZERO, 7.0, body_color)
			draw_circle(Vector2.ZERO, 4.0, Color.BLACK)
			draw_circle(Vector2.ZERO, 1.0, body_color)
		EnemyData.Behavior.TANK:
			draw_rect(Rect2(-8.0, -8.0, 16.0, 16.0), body_color)
			draw_rect(Rect2(-5.0, -5.0, 10.0, 10.0), Color("181a1f"))
