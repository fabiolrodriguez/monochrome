class_name Weapon
extends Node2D

signal fired(projectile: PlayerProjectile)

@export var projectile_scene: PackedScene

@onready var muzzle: Marker2D = $Muzzle
@onready var fire_cooldown: Timer = $FireCooldown

var _trigger_pressed := false


func _physics_process(_delta: float) -> void:
	if _trigger_pressed and fire_cooldown.is_stopped():
		_fire()


func aim_at(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		rotation = direction.angle()


func set_trigger_pressed(pressed: bool) -> void:
	_trigger_pressed = pressed


func _fire() -> void:
	if projectile_scene == null:
		push_warning("Weapon has no projectile scene configured.")
		return
	var projectile := projectile_scene.instantiate() as PlayerProjectile
	if projectile == null:
		push_error("Configured projectile scene does not create a PlayerProjectile.")
		return
	projectile.global_transform = muzzle.global_transform
	var projectile_container := get_tree().get_first_node_in_group("projectile_container")
	if projectile_container == null:
		projectile_container = get_tree().current_scene
	projectile_container.add_child(projectile)
	fire_cooldown.start()
	fired.emit(projectile)

