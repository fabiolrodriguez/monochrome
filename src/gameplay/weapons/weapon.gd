class_name Weapon
extends Node2D

signal fired(projectile: PlayerProjectile)

@export var projectile_scene: PackedScene
@export_range(0.05, 2.0, 0.01) var base_fire_interval: float = 0.32

var damage_multiplier := 1.0
var fire_rate_multiplier := 1.0
var projectile_speed_multiplier := 1.0
var projectile_count := 1
var piercing_hits := 0
var ricochet_count := 0
var critical_chance := 0.05
var critical_damage_multiplier := 1.5

const SPREAD_ANGLE := deg_to_rad(9.0)

@onready var muzzle: Marker2D = $Muzzle
@onready var fire_cooldown: Timer = $FireCooldown

var _trigger_pressed := false
func _ready() -> void:
	# Run-scoped combat values always start from authored defaults.
	damage_multiplier = 1.0
	fire_rate_multiplier = 1.0
	projectile_speed_multiplier = 1.0
	projectile_count = 1
	piercing_hits = 0
	ricochet_count = 0
	critical_chance = 0.05
	critical_damage_multiplier = 1.5
	fire_cooldown.wait_time = base_fire_interval


func _physics_process(_delta: float) -> void:
	if _trigger_pressed and fire_cooldown.is_stopped():
		_fire()


func aim_at(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		rotation = direction.angle()


func set_trigger_pressed(pressed: bool) -> void:
	_trigger_pressed = pressed


func refresh_fire_rate() -> void:
	fire_cooldown.wait_time = base_fire_interval / fire_rate_multiplier


func fire_passive(direction: Vector2, damage_factor: float, projectile_color: Color, extra_ricochets := 0) -> void:
	if direction.is_zero_approx() or projectile_scene == null:
		return
	var spawn_transform := Transform2D(direction.angle(), global_position + direction.normalized() * 8.0)
	_spawn_projectile(spawn_transform, damage_factor, projectile_color, null, null, extra_ricochets)


func _fire() -> void:
	if projectile_scene == null:
		push_warning("Weapon has no projectile scene configured.")
		return
	AudioManager.play_sfx(&"player_shot", -22.0, 0.055)
	var projectile_container := get_tree().get_first_node_in_group("projectile_container")
	if projectile_container == null:
		projectile_container = get_tree().current_scene
	var pool := get_tree().get_first_node_in_group("player_projectile_pool") as PlayerProjectilePool
	for index: int in projectile_count:
		var spread_offset := (float(index) - float(projectile_count - 1) * 0.5) * SPREAD_ANGLE
		var shot_transform := muzzle.global_transform.rotated_local(spread_offset)
		_spawn_projectile(shot_transform, 1.0, Color("4aa3ff"), pool, projectile_container)
	fire_cooldown.start()


func _spawn_projectile(spawn_transform: Transform2D, damage_factor: float, projectile_color: Color, existing_pool: PlayerProjectilePool = null, existing_container: Node = null, extra_ricochets := 0) -> void:
	var projectile_container := existing_container
	if projectile_container == null:
		projectile_container = get_tree().get_first_node_in_group("projectile_container")
		if projectile_container == null:
			projectile_container = get_tree().current_scene
	var pool := existing_pool
	if pool == null:
		pool = get_tree().get_first_node_in_group("player_projectile_pool") as PlayerProjectilePool
	var is_critical := randf() < critical_chance
	var shot_damage_multiplier := damage_multiplier * damage_factor * (critical_damage_multiplier if is_critical else 1.0)
	var projectile: PlayerProjectile
	if pool != null:
		projectile = pool.acquire(spawn_transform, shot_damage_multiplier, projectile_speed_multiplier, piercing_hits, ricochet_count + extra_ricochets, is_critical, projectile_color)
	else:
		projectile = projectile_scene.instantiate() as PlayerProjectile
		if projectile != null:
			projectile_container.add_child(projectile)
			projectile.activate(spawn_transform, shot_damage_multiplier, projectile_speed_multiplier, piercing_hits, ricochet_count + extra_ricochets, is_critical, projectile_color)
	if projectile != null:
		fired.emit(projectile)
