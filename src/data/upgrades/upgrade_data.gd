class_name UpgradeData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum Category { OFFENSE, DEFENSE, MOBILITY, UTILITY }
enum Stat { DAMAGE, FIRE_RATE, MOVEMENT_SPEED, MAX_HEALTH, PROJECTILE_SPEED, MULTISHOT, PIERCING, RICOCHET, ARMOR, REGENERATION, BARRIER }

@export var id: StringName
@export var name_key: StringName
@export var description_key: StringName
@export var icon: Texture2D
@export var rarity := Rarity.COMMON
@export var category := Category.OFFENSE
@export_range(1, 100, 1) var max_level: int = 5
@export_range(0.0, 1000.0, 0.1) var weight: float = 10.0
@export var requirements: Array[StringName] = []
@export var tags: Array[StringName] = []
@export var stat := Stat.DAMAGE
@export var amount_per_level: float = 0.05
@export var unlock_requirement: StringName
