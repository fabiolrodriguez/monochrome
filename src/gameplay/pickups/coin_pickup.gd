class_name CoinPickup
extends Area2D

@export_range(1, 1000, 1) var value: int = 1
@export_range(1.0, 500.0, 1.0) var attraction_speed: float = 90.0

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
	if player == null:
		return
	var run_currency := get_tree().get_first_node_in_group("run_currency") as RunCurrency
	if run_currency != null:
		run_currency.collect_coins(value)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color("ffd84a"))
	draw_circle(Vector2.ZERO, 1.0, Color("6d5814"))
