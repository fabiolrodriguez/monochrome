class_name Player
extends CharacterBody2D

signal died
signal auto_fire_changed(enabled: bool)

@export_range(1.0, 500.0, 1.0) var movement_speed: float = 80.0
@export_range(0.0, 1.0, 0.05) var gamepad_aim_deadzone: float = 0.25
@export_range(1.0, 500.0, 1.0) var pickup_radius: float = 48.0
@export_range(50.0, 600.0, 1.0) var dash_speed := 260.0
@export_range(0.05, 1.0, 0.01) var dash_duration := 0.14
@export_range(0.1, 10.0, 0.05) var dash_cooldown := 1.2

@onready var weapon: Weapon = $Weapon
@onready var health: HealthComponent = $Health
@onready var experience: ExperienceComponent = $Experience
@onready var damage_cooldown: Timer = $DamageCooldown

var aim_direction := Vector2.RIGHT
var _base_movement_speed: float
var _movement_multiplier := 1.0
var _is_dead := false
var _auto_fire_enabled := false
var _dash_remaining := 0.0
var _dash_cooldown_remaining := 0.0
var _dash_direction := Vector2.ZERO
var armor_reduction := 0.0
var regeneration_per_second := 0.0
var barrier_cooldown_seconds := 0.0
var _barrier_remaining := 0.0
var _barrier_ready := false
var _regeneration_accumulator := 0.0


func _ready() -> void:
	_base_movement_speed = movement_speed
	health.depleted.connect(_on_health_depleted)
	_apply_permanent_progression()


func take_damage(amount: float) -> void:
	if _is_dead or _dash_remaining > 0.0 or not damage_cooldown.is_stopped():
		return
	if _barrier_ready:
		_barrier_ready = false
		_barrier_remaining = barrier_cooldown_seconds
		AudioManager.play_sfx(&"confirm", -14.0)
		queue_redraw()
		return
	health.damage(amount * (1.0 - armor_reduction))
	AudioManager.play_sfx(&"player_hit", -10.0, 0.1)
	damage_cooldown.start()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	_dash_cooldown_remaining = maxf(_dash_cooldown_remaining - delta, 0.0)
	_update_defenses(delta)
	var movement_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dash") and _dash_cooldown_remaining <= 0.0:
		_dash_direction = movement_input.normalized() if not movement_input.is_zero_approx() else aim_direction
		_dash_remaining = dash_duration
		_dash_cooldown_remaining = dash_cooldown
		AudioManager.play_sfx(&"dash", -13.0)
	if _dash_remaining > 0.0:
		_dash_remaining = maxf(_dash_remaining - delta, 0.0)
		velocity = _dash_direction * dash_speed
	else:
		velocity = movement_input * movement_speed
	move_and_slide()
	_update_aim()
	weapon.set_trigger_pressed(_auto_fire_enabled or Input.is_action_pressed("shoot"))
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _is_dead or not event.is_action_pressed("auto_fire_toggle"):
		return
	_auto_fire_enabled = not _auto_fire_enabled
	auto_fire_changed.emit(_auto_fire_enabled)
	get_viewport().set_input_as_handled()


func apply_upgrade(upgrade: UpgradeData) -> void:
	match upgrade.stat:
		UpgradeData.Stat.DAMAGE:
			weapon.damage_multiplier += upgrade.amount_per_level
		UpgradeData.Stat.FIRE_RATE:
			weapon.fire_rate_multiplier += upgrade.amount_per_level
			weapon.refresh_fire_rate()
		UpgradeData.Stat.MOVEMENT_SPEED:
			_movement_multiplier += upgrade.amount_per_level
			movement_speed = _base_movement_speed * _movement_multiplier
		UpgradeData.Stat.MAX_HEALTH:
			health.increase_maximum(upgrade.amount_per_level)
		UpgradeData.Stat.PROJECTILE_SPEED:
			weapon.projectile_speed_multiplier += upgrade.amount_per_level
		UpgradeData.Stat.MULTISHOT:
			weapon.projectile_count += roundi(upgrade.amount_per_level)
		UpgradeData.Stat.PIERCING:
			weapon.piercing_hits += roundi(upgrade.amount_per_level)
		UpgradeData.Stat.RICOCHET:
			weapon.ricochet_count += roundi(upgrade.amount_per_level)
		UpgradeData.Stat.ARMOR:
			armor_reduction = minf(armor_reduction + upgrade.amount_per_level, 0.6)
		UpgradeData.Stat.REGENERATION:
			regeneration_per_second += upgrade.amount_per_level
		UpgradeData.Stat.BARRIER:
			barrier_cooldown_seconds = 9.0 if barrier_cooldown_seconds <= 0.0 else maxf(barrier_cooldown_seconds - upgrade.amount_per_level, 3.0)
			_barrier_ready = true
			queue_redraw()


func _apply_permanent_progression() -> void:
	var health_bonus := ProgressionManager.get_permanent_stat(&"max_health")
	if health_bonus > 0.0:
		health.increase_maximum(health_bonus)
	_movement_multiplier += ProgressionManager.get_permanent_stat(&"movement_speed")
	movement_speed = _base_movement_speed * _movement_multiplier
	weapon.damage_multiplier += ProgressionManager.get_permanent_stat(&"damage")
	weapon.fire_rate_multiplier += ProgressionManager.get_permanent_stat(&"fire_rate")
	weapon.projectile_speed_multiplier += ProgressionManager.get_permanent_stat(&"projectile_speed")
	weapon.refresh_fire_rate()
	pickup_radius += ProgressionManager.get_permanent_stat(&"pickup_radius")


func _on_health_depleted() -> void:
	_is_dead = true
	_auto_fire_enabled = false
	velocity = Vector2.ZERO
	weapon.set_trigger_pressed(false)
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	died.emit()
	queue_redraw()


func _update_aim() -> void:
	var gamepad_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if gamepad_aim.length() >= gamepad_aim_deadzone:
		aim_direction = gamepad_aim.normalized()
	else:
		var mouse_offset := get_global_mouse_position() - global_position
		if not mouse_offset.is_zero_approx():
			aim_direction = mouse_offset.normalized()
	weapon.aim_at(aim_direction)


func _update_defenses(delta: float) -> void:
	if regeneration_per_second > 0.0 and health.current_health < health.maximum_health:
		_regeneration_accumulator += delta
		if _regeneration_accumulator >= 0.25:
			health.heal(regeneration_per_second * _regeneration_accumulator)
			_regeneration_accumulator = 0.0
	if barrier_cooldown_seconds > 0.0 and not _barrier_ready:
		_barrier_remaining = maxf(_barrier_remaining - delta, 0.0)
		if _barrier_remaining <= 0.0:
			_barrier_ready = true
			queue_redraw()


func _draw() -> void:
	# Logic and collision remain independent from this replaceable placeholder art.
	var body_color := Color("55575c") if _is_dead else (Color("ff8585") if not damage_cooldown.is_stopped() else Color.WHITE)
	draw_circle(Vector2.ZERO, 6.0, body_color)
	draw_circle(Vector2.ZERO, 3.0, Color(0.04, 0.04, 0.05, 1.0))
	draw_line(Vector2.ZERO, aim_direction * 10.0, Color.WHITE, 2.0)
	if _barrier_ready:
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 20, Color("70c8ff"), 1.0)
