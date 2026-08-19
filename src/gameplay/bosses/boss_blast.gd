class_name BossBlast
extends Node2D

@export var radius := 42.0
@export var damage := 18.0
@export var delay := 0.85

var _remaining: float
var _exploded := false


func _ready() -> void:
	_remaining = delay
	queue_redraw()


func _process(delta: float) -> void:
	_remaining -= delta
	queue_redraw()
	if _remaining <= 0.0 and not _exploded:
		_explode()


func _explode() -> void:
	_exploded = true
	var player := get_tree().get_first_node_in_group("player") as Player
	if is_instance_valid(player) and player.global_position.distance_to(global_position) <= radius:
		player.take_damage(damage)
	AudioManager.play_sfx(&"boss_spawn", -18.0)
	await get_tree().create_timer(0.15).timeout
	queue_free()


func _draw() -> void:
	if _exploded:
		draw_circle(Vector2.ZERO, radius, Color(0.61, 0.36, 1.0, 0.28))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color("9b5cff"), 3.0)
		return
	var progress := 1.0 - maxf(_remaining, 0.0) / delay
	draw_circle(Vector2.ZERO, radius, Color(0.61, 0.36, 1.0, 0.05 + progress * 0.12))
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color("9b5cff"), 2.0)
