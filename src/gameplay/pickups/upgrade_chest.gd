class_name UpgradeChest
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var _base_y := 0.0
var _elapsed := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_y = sprite.position.y
	queue_redraw()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	sprite.position.y = _base_y + roundf(sin(_elapsed * 2.5))
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var controller := get_tree().get_first_node_in_group("upgrade_controller") as UpgradeController
	if controller == null:
		return
	var upgrade := controller.roll_world_upgrade()
	if upgrade != null and controller.grant_world_upgrade(upgrade):
		queue_free()


func _draw() -> void:
	var pulse := 10.0 + sin(_elapsed * 3.0)
	draw_arc(Vector2.ZERO, pulse, 0.0, TAU, 20, Color("b67cff"), 1.0)
