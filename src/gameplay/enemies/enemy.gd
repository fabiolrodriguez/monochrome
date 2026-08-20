class_name Enemy
extends CharacterBody2D

signal defeated(enemy: Enemy)

@export var data: EnemyData
@export var enemy_projectile_scene: PackedScene
@export var experience_pickup_scene: PackedScene
@export var coin_pickup_scene: PackedScene
@export var healing_pickup_scene: PackedScene

@onready var health: HealthComponent = $Health
@onready var shot_cooldown: Timer = $ShotCooldown
@onready var sprite: Sprite2D = $Sprite2D

var _target: Player
var _hit_flash_remaining := 0.0
var _shot_windup_active := false
var _shot_windup_remaining := 0.0
var _pending_shot_direction := Vector2.RIGHT


func _ready() -> void:
	assert(data != null, "Enemy requires an EnemyData resource.")
	_target = get_tree().get_first_node_in_group("player") as Player
	health.depleted.connect(_on_depleted)
	health.maximum_health = data.maximum_health
	health.current_health = data.maximum_health
	shot_cooldown.wait_time = data.shot_interval
	_configure_sprite()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = maxf(_hit_flash_remaining - delta, 0.0)
		queue_redraw()
	if _shot_windup_active:
		_shot_windup_remaining = maxf(_shot_windup_remaining - delta, 0.0)
		queue_redraw()
		if _shot_windup_remaining <= 0.0:
			_shot_windup_active = false
			_shoot(_pending_shot_direction)
			queue_redraw()
	var hit_color := Color.WHITE.lerp(Color("9fcfff"), SettingsManager.flash_intensity)
	sprite.modulate = hit_color if _hit_flash_remaining > 0.0 else (Color("ff9a9a") if _shot_windup_active else Color.WHITE)
	if absf(velocity.x) > 0.1:
		sprite.flip_h = velocity.x < 0.0
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	var to_target := _target.global_position - global_position
	match data.behavior:
		EnemyData.Behavior.CHASER, EnemyData.Behavior.TANK:
			velocity = to_target.normalized() * data.movement_speed
		EnemyData.Behavior.SHOOTER:
			velocity = _shooter_velocity(to_target)
			if shot_cooldown.is_stopped() and not _shot_windup_active:
				_begin_shot(to_target.normalized())
	move_and_slide()
	_apply_contact_damage()


func take_damage(amount: float) -> void:
	var applied_damage := minf(maxf(amount, 0.0), health.current_health)
	health.damage(amount)
	var telemetry := get_tree().get_first_node_in_group("run_telemetry") as RunTelemetry
	if telemetry != null:
		telemetry.record_damage_dealt(applied_damage)
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


func _begin_shot(direction: Vector2) -> void:
	_shot_windup_active = true
	_shot_windup_remaining = 0.38
	_pending_shot_direction = direction
	queue_redraw()


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
	_try_drop_healing()
	var telemetry := get_tree().get_first_node_in_group("run_telemetry") as RunTelemetry
	if telemetry != null:
		telemetry.record_defeat()
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


func _try_drop_healing() -> void:
	if healing_pickup_scene == null or randf() > data.healing_drop_chance:
		return
	var pickup := healing_pickup_scene.instantiate() as HealingPickup
	if pickup == null:
		return
	pickup.healing_amount = data.healing_value
	var container := get_tree().get_first_node_in_group("pickup_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(pickup)
	pickup.global_position = global_position


func _draw() -> void:
	if data == null:
		return
	if data.is_elite:
		draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color("ffd84a"), 2.0)
		draw_polyline(PackedVector2Array([Vector2(-6, -10), Vector2(-3, -14), Vector2(0, -10), Vector2(3, -14), Vector2(6, -10)]), Color("ffd84a"), 1.5)


func _configure_sprite() -> void:
	var atlas_coordinate := Vector2i(9, 18)
	if data.is_elite:
		atlas_coordinate = Vector2i(11, 18)
	else:
		match data.behavior:
			EnemyData.Behavior.CHASER:
				atlas_coordinate = Vector2i(9, 18)
			EnemyData.Behavior.SHOOTER:
				atlas_coordinate = Vector2i(14, 18)
			EnemyData.Behavior.TANK:
				atlas_coordinate = Vector2i(12, 18)
	sprite.region_rect = Rect2(Vector2(atlas_coordinate * 16), Vector2(16, 16))
