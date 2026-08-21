class_name TheWatcher
extends CharacterBody2D

const BOSS_BLAST_SCENE := preload("res://src/gameplay/bosses/boss_blast.tscn")

signal health_changed(current: float, maximum: float)
signal phase_changed(phase: int)
signal defeated

@export var data: BossData
@export var projectile_scene: PackedScene

@onready var health: HealthComponent = $Health
@onready var attack_timer: Timer = $AttackTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player: Player
var _phase := 0
var _pattern_step := 0
var _rotation_offset := 0.0
var _stag_dash_cooldown := 1.5
var _stag_dash_remaining := 0.0
var _stag_dash_direction := Vector2.ZERO
var _drowned_shield_remaining := 0.0
var _tower_reflect_remaining := 0.0
var _tower_reflect_cooldown := 0.0
var _hit_flash_remaining := 0.0
var _hit_was_reduced := false


func _ready() -> void:
	assert(data != null, "TheWatcher requires BossData.")
	ProgressionManager.discover_boss(data.id)
	_player = get_tree().get_first_node_in_group("player") as Player
	health.maximum_health = data.maximum_health
	health.current_health = data.maximum_health
	health.health_changed.connect(_on_health_changed)
	health.depleted.connect(_on_depleted)
	attack_timer.timeout.connect(_attack)
	attack_timer.start()
	sprite.play(&"idle")
	health_changed.emit(health.current_health, health.maximum_health)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var hit_was_active := _hit_flash_remaining > 0.0
	_hit_flash_remaining = maxf(_hit_flash_remaining - delta, 0.0)
	var raw_hit_color := Color("63dcff") if _hit_was_reduced else Color("ffd84a")
	sprite.modulate = Color.WHITE.lerp(raw_hit_color, SettingsManager.flash_intensity) if _hit_flash_remaining > 0.0 else Color.WHITE
	if hit_was_active:
		queue_redraw()
	var shield_was_active := _drowned_shield_remaining > 0.0
	_drowned_shield_remaining = maxf(_drowned_shield_remaining - delta, 0.0)
	var reflect_was_active := _tower_reflect_remaining > 0.0
	_tower_reflect_remaining = maxf(_tower_reflect_remaining - delta, 0.0)
	_tower_reflect_cooldown = maxf(_tower_reflect_cooldown - delta, 0.0)
	if data != null and data.id == &"the_drowned_one" and shield_was_active:
		queue_redraw()
	if data != null and data.id == &"the_tower":
		if reflect_was_active:
			queue_redraw()
		velocity = Vector2.ZERO
		return
	if not is_instance_valid(_player):
		velocity = Vector2.ZERO
		return
	if data.id == &"the_stag":
		_update_stag_movement(delta)
		move_and_slide()
		_apply_contact_damage()
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


func _update_stag_movement(delta: float) -> void:
	_stag_dash_cooldown -= delta
	_stag_dash_remaining -= delta
	if _stag_dash_remaining > 0.0:
		velocity = _stag_dash_direction * data.movement_speed * 4.2
		return
	if _stag_dash_cooldown <= 0.0:
		_stag_dash_direction = (_player.global_position - global_position).normalized()
		_stag_dash_remaining = 0.32
		_stag_dash_cooldown = maxf(2.4 - _phase * 0.35, 1.4)
		velocity = _stag_dash_direction * data.movement_speed * 4.2
		return
	velocity = (_player.global_position - global_position).normalized() * data.movement_speed


func take_damage(amount: float) -> void:
	_hit_was_reduced = false
	if data.id == &"the_drowned_one" and _drowned_shield_remaining > 0.0:
		amount *= 0.5
		_hit_was_reduced = true
	if data.id == &"the_tower" and _tower_reflect_remaining > 0.0:
		amount *= 0.55
		_hit_was_reduced = true
		if _tower_reflect_cooldown <= 0.0 and is_instance_valid(_player):
			_spawn_projectile(global_position.direction_to(_player.global_position))
			_tower_reflect_cooldown = 0.28
	var applied_damage := minf(maxf(amount, 0.0), health.current_health)
	health.damage(amount)
	var telemetry := get_tree().get_first_node_in_group("run_telemetry") as RunTelemetry
	if telemetry != null:
		telemetry.record_damage_dealt(applied_damage)
	_hit_flash_remaining = 0.11
	queue_redraw()


func _attack() -> void:
	if not is_instance_valid(_player):
		return
	_pattern_step += 1
	if data.id == &"the_machine":
		_fire_aimed_spread(3 + _phase * 2, 0.14)
		if _pattern_step % 2 == 0:
			_fire_radial(6 + _phase * 3, _rotation_offset)
		_rotation_offset += 0.19
		return
	if data.id == &"the_stag":
		_fire_aimed_spread(2 + _phase, 0.22)
		if _pattern_step % 3 == 0:
			_fire_radial(5 + _phase * 2, _rotation_offset)
		_rotation_offset += 0.24
		return
	if data.id == &"the_mother":
		_fire_radial(7 + _phase * 2, _rotation_offset)
		if _pattern_step % 3 == 0:
			_spawn_mother_blasts(1 if _phase < 2 else 2)
		_rotation_offset += 0.17
		return
	if data.id == &"the_drowned_one":
		_fire_aimed_spread(3 + _phase, 0.2)
		if _pattern_step % 4 == 0:
			_drowned_shield_remaining = 1.4 + _phase * 0.25
			_fire_radial(6 + _phase * 2, _rotation_offset)
			queue_redraw()
		_rotation_offset += 0.11
		return
	if data.id == &"the_tower":
		if _pattern_step % 2 == 0:
			_fire_radial(12 + _phase * 4, _rotation_offset)
		else:
			_fire_aimed_spread(5 + _phase * 2, 0.13)
		if _pattern_step % 4 == 0:
			_tower_reflect_remaining = 1.5 + _phase * 0.25
			queue_redraw()
		_rotation_offset += 0.09
		return
	if data.id == &"the_heart":
		_fire_radial(9 + _phase * 3, _rotation_offset)
		if _pattern_step % 2 == 0:
			_fire_aimed_spread(3 + _phase * 2, 0.16)
		if _pattern_step % 4 == 0:
			_spawn_mother_blasts(1 + _phase)
		_rotation_offset += 0.14
		return
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


func _spawn_mother_blasts(count: int) -> void:
	var center := float(count - 1) * 0.5
	var lateral_direction := _player.aim_direction.rotated(PI * 0.5)
	for index: int in count:
		var blast := BOSS_BLAST_SCENE.instantiate() as BossBlast
		if blast == null:
			continue
		blast.radius = 32.0 + _phase * 4.0
		blast.damage = data.projectile_damage * 1.6
		blast.delay = 1.15 if _phase < 2 else 1.0
		get_tree().current_scene.add_child(blast)
		var prediction := _player.velocity * 0.22
		var lateral_offset := lateral_direction * (float(index) - center) * 100.0
		blast.global_position = _player.global_position + prediction + lateral_offset


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
		if data.id == &"the_mother":
			attack_timer.wait_time = [1.7, 1.4, 1.1][_phase]
		elif data.id == &"the_drowned_one":
			attack_timer.wait_time = [1.75, 1.4, 1.1][_phase]
		elif data.id == &"the_tower":
			attack_timer.wait_time = [1.35, 1.05, 0.82][_phase]
		elif data.id == &"the_heart":
			attack_timer.wait_time = [1.55, 1.2, 0.92][_phase]
		sprite.play([&"idle", &"phase_1", &"phase_2"][_phase])
		phase_changed.emit(_phase)
		var shake := get_tree().get_first_node_in_group("screen_shake") as ScreenShake
		if shake != null:
			shake.add_trauma(0.24)
		queue_redraw()


func _apply_contact_damage() -> void:
	for collision_index: int in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider() as Player
		if collider != null:
			collider.take_damage(data.contact_damage)


func _on_depleted() -> void:
	attack_timer.stop()
	var telemetry := get_tree().get_first_node_in_group("run_telemetry") as RunTelemetry
	if telemetry != null:
		telemetry.record_defeat()
	defeated.emit()
	queue_free()


func _draw() -> void:
	var accent := Color("ffd84a") if data != null and data.id == &"the_machine" else Color("ff4b4b")
	if data != null and data.id == &"the_stag":
		accent = Color("7ed7ff")
		draw_polyline(PackedVector2Array([Vector2(-4, -8), Vector2(-9, -16), Vector2(-14, -17), Vector2(-10, -20)]), Color.WHITE, 2.0)
		draw_polyline(PackedVector2Array([Vector2(4, -8), Vector2(9, -16), Vector2(14, -17), Vector2(10, -20)]), Color.WHITE, 2.0)
	if data != null and data.id == &"the_mother":
		accent = Color("9b5cff")
		for index: int in 8:
			var direction := Vector2.RIGHT.rotated(TAU * float(index) / 8.0)
			draw_line(direction * 10.0, direction * 24.0, Color.WHITE, 2.0)
	if data != null and data.id == &"the_drowned_one":
		accent = Color("63dcff")
		if _drowned_shield_remaining > 0.0:
			draw_circle(Vector2.ZERO, 25.0, Color(0.2, 0.75, 1.0, 0.12))
			draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 32, Color("63dcff"), 2.0)
	if data != null and data.id == &"the_tower":
		accent = Color("ff7a4d")
		draw_rect(Rect2(-13, -22, 26, 44), Color(0.05, 0.05, 0.06, 0.85), false, 2.0)
		if _tower_reflect_remaining > 0.0:
			draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 36, Color("ff7a4d"), 2.0)
	if data != null and data.id == &"the_heart":
		accent = Color("ff426d")
	if data == null or data.id != &"the_heart":
		draw_circle(Vector2.ZERO, 2.0, accent)
	if _hit_flash_remaining > 0.0:
		var hit_color := Color("63dcff") if _hit_was_reduced else Color("ffd84a")
		hit_color.a = SettingsManager.flash_intensity
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 28, hit_color, 2.0)
	if _phase == 2 and (data == null or data.id != &"the_heart"):
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, accent, 1.0)
