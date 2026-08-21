class_name UpgradeChest
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var _base_y := 0.0
var _elapsed := 0.0
var evolution_only := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_y = sprite.position.y
	if evolution_only:
		add_to_group("evolution_chests")
		sprite.modulate = Color("d2b3ff")
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
	if controller.grant_ready_evolution():
		AudioManager.play_sfx(&"chest_open", -8.0, 0.1)
		queue_free()
		return
	if evolution_only:
		return
	var upgrade := controller.roll_world_upgrade()
	if upgrade != null and controller.grant_world_upgrade(upgrade):
		AudioManager.play_sfx(&"chest_open", -10.0, 0.1)
		queue_free()


func _draw() -> void:
	var pulse := 10.0 + sin(_elapsed * 3.0)
	draw_arc(Vector2.ZERO, pulse, 0.0, TAU, 20, Color("ffd84a") if evolution_only else Color("b67cff"), 1.0 if not evolution_only else 2.0)
