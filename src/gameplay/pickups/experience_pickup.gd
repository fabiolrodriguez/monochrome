class_name ExperiencePickup
extends Area2D

@export_range(0.1, 1000.0, 0.1) var value: float = 5.0
@export_range(1.0, 500.0, 1.0) var attraction_radius: float = 48.0
@export_range(1.0, 500.0, 1.0) var attraction_speed: float = 105.0

var _target: Player


func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player") as Player
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var offset := _target.global_position - global_position
	var effective_radius := maxf(attraction_radius, _target.pickup_radius)
	if offset.length_squared() <= effective_radius * effective_radius:
		global_position += offset.normalized() * attraction_speed * delta


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	player.experience.add_experience(value)
	AudioManager.play_sfx(&"pickup", -24.0, 0.08)
	queue_free()


func _draw() -> void:
	return
