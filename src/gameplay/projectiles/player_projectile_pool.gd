class_name PlayerProjectilePool
extends Node2D

@export var projectile_scene: PackedScene
@export_range(0, 256, 1) var prewarm_count := 48
@export_range(1, 512, 1) var maximum_size := 256

var _available: Array[PlayerProjectile] = []
var _total_created := 0


func _ready() -> void:
	for _index: int in mini(prewarm_count, maximum_size):
		var projectile := _create_projectile()
		if projectile != null:
			_available.append(projectile)


func acquire(spawn_transform: Transform2D, damage_scale: float, speed_scale: float, piercing: int, ricochets: int, is_critical: bool) -> PlayerProjectile:
	var projectile: PlayerProjectile
	if not _available.is_empty():
		projectile = _available.pop_back()
	elif _total_created < maximum_size:
		projectile = _create_projectile()
	if projectile == null:
		return null
	projectile.activate(spawn_transform, damage_scale, speed_scale, piercing, ricochets, is_critical)
	return projectile


func _create_projectile() -> PlayerProjectile:
	if projectile_scene == null:
		push_warning("PlayerProjectilePool requires a projectile scene.")
		return null
	var projectile := projectile_scene.instantiate() as PlayerProjectile
	if projectile == null:
		push_error("Projectile pool scene must instantiate PlayerProjectile.")
		return null
	add_child(projectile)
	projectile.released.connect(_release)
	_total_created += 1
	return projectile


func _release(projectile: PlayerProjectile) -> void:
	if not _available.has(projectile):
		_available.append(projectile)
