class_name HealingPickup
extends Area2D

@export_range(1.0, 1000.0, 1.0) var healing_amount := 12.0
@export_range(1.0, 500.0, 1.0) var attraction_speed := 80.0

var _target: Player


func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player") as Player
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var offset := _target.global_position - global_position
	if offset.length_squared() <= _target.pickup_radius * _target.pickup_radius:
		global_position += offset.normalized() * attraction_speed * delta


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or player.health.current_health >= player.health.maximum_health:
		return
	player.health.heal(healing_amount)
	AudioManager.play_sfx(&"confirm", -16.0)
	queue_free()


func _draw() -> void:
	return
