extends Node2D

const POOL_SCENE := preload("res://src/presentation/black_lake_pool.tscn")
const POOLS := [
	[Vector2(-280, -100), 82.0], [Vector2(320, 130), 74.0],
	[Vector2(-210, 330), 66.0], [Vector2(260, -350), 62.0],
]


func _ready() -> void:
	if ProgressionManager.selected_level_id != &"black_lake":
		queue_free()
		return
	for definition: Array in POOLS:
		var pool := POOL_SCENE.instantiate() as BlackLakePool
		pool.position = definition[0]
		pool.radius = definition[1]
		add_child(pool)
