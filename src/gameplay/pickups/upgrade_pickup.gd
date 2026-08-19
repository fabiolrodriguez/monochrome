class_name UpgradePickup
extends Area2D

@export var upgrade: UpgradeData
@export_range(1.0, 500.0, 1.0) var attraction_speed := 75.0

@onready var sprite: Sprite2D = $Sprite2D

var _player: Player
var _pulse := 0.0


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	body_entered.connect(_on_body_entered)
	if upgrade != null:
		sprite.texture = upgrade.icon
	queue_redraw()


func _physics_process(delta: float) -> void:
	_pulse += delta
	if not is_instance_valid(_player):
		return
	var offset := _player.global_position - global_position
	if offset.length_squared() <= _player.pickup_radius * _player.pickup_radius:
		global_position += offset.normalized() * attraction_speed * delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var controller := get_tree().get_first_node_in_group("upgrade_controller") as UpgradeController
	if controller != null and controller.grant_world_upgrade(upgrade):
		queue_free()


func _draw() -> void:
	var radius := 11.0 + sin(_pulse * 4.0) * 1.5
	draw_circle(Vector2.ZERO, radius, Color(0.61, 0.36, 1.0, 0.1))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color("b67cff"), 1.5)
	draw_polyline(PackedVector2Array([Vector2(-3, -14), Vector2(0, -17), Vector2(3, -14)]), Color.WHITE, 1.0)
