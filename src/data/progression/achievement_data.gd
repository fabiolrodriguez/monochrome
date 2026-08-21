class_name AchievementData
extends Resource

enum ConditionType { CAREER_STAT, COMPLETED_LEVELS, DISCOVERED_BOSSES, SKILL_NODES }

@export var id: StringName
## Immutable API Name configured for this achievement in Steamworks App Admin.
@export var steam_api_name: StringName
@export var title_key: StringName
@export var description_key: StringName
@export var icon: Texture2D
@export var condition_type := ConditionType.CAREER_STAT
@export var stat_key: StringName
@export_range(1.0, 10000000.0, 1.0) var target_value := 1.0
@export_range(0, 10000, 1) var coin_reward := 5
