class_name SkillNodeData
extends Resource

enum NodeType { STAT, SYSTEM, UNLOCK }

@export var id: StringName
@export var title_key: StringName
@export var description_key: StringName
@export var node_type := NodeType.STAT
@export_range(0, 100000, 1) var cost: int = 0
@export var prerequisites: Array[StringName] = []
@export var stat_key: StringName
@export var stat_value: float = 0.0
@export var unlock_id: StringName
@export var tree_position := Vector2.ZERO
