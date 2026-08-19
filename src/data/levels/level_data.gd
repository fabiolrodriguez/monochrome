class_name LevelData
extends Resource

@export var id: StringName
@export var name_key: StringName
@export var description_key: StringName
@export var scene: PackedScene
@export_range(1.0, 3600.0, 1.0) var duration: float = 360.0
@export var objective: ObjectiveData
@export var enemy_pool: Array[EnemyData] = []
@export var elite_pool: Array[EnemyData] = []
@export var boss: BossData
@export var music: AudioStream
@export var unlock_requirements: Array[StringName] = []
@export var reward: Resource
@export var next_levels: Array[StringName] = []
@export_range(0.1, 100.0, 0.1) var difficulty: float = 1.0
@export var spawn_segments: Array[SpawnSegmentData] = []
