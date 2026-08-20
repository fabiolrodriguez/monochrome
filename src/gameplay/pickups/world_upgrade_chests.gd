class_name WorldUpgradeChests
extends Node

const CHEST_SCENE := preload("res://src/gameplay/pickups/upgrade_chest.tscn")
const CHEST_POSITIONS: Array[Vector2] = [
	Vector2(-96.0, 80.0),
	Vector2(432.0, 80.0),
	Vector2(176.0, 336.0),
]


func _ready() -> void:
	var container := get_tree().get_first_node_in_group("pickup_container")
	if container == null:
		container = get_tree().current_scene
	for chest_position: Vector2 in CHEST_POSITIONS:
		var chest := CHEST_SCENE.instantiate() as UpgradeChest
		container.add_child(chest)
		chest.global_position = chest_position
