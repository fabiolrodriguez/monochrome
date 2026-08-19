class_name HiveNest
extends StaticBody2D

signal destroyed(nest: HiveNest)

@export var maximum_health := 280.0
@export var spawn_interval := 6.0
@export var spawn_enemy_data: EnemyData

@onready var health: HealthComponent = $Health
@onready var spawn_timer: Timer = $SpawnTimer

var director: ThreatDirector
var _elapsed := 0.0


func _ready() -> void:
	health.maximum_health = maximum_health
	health.current_health = maximum_health
	health.depleted.connect(_on_depleted)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_defender)
	spawn_timer.start()
	add_to_group("objective_target")
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	spawn_timer.wait_time = maxf(spawn_interval * (1.0 - minf(_elapsed / 240.0, 0.45)), 2.0)
	queue_redraw()


func take_damage(amount: float) -> void:
	health.damage(amount)
	queue_redraw()


func _spawn_defender() -> void:
	if director == null or spawn_enemy_data == null:
		return
	var angle := randf_range(0.0, TAU)
	director.spawn_objective_enemy(spawn_enemy_data, global_position + Vector2.RIGHT.rotated(angle) * 28.0)


func _on_depleted() -> void:
	spawn_timer.stop()
	remove_from_group("objective_target")
	destroyed.emit(self)
	queue_free()


func _draw() -> void:
	var ratio := health.current_health / maxf(health.maximum_health, 1.0) if is_instance_valid(health) else 1.0
	draw_circle(Vector2.ZERO, 17.0, Color("050507"))
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 20, Color("d6d6d8"), 2.0)
	for index: int in 6:
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 6.0)
		draw_line(direction * 8.0, direction * (19.0 + sin(_elapsed * 2.0 + index) * 2.0), Color("d6d6d8"), 2.0)
	draw_arc(Vector2.ZERO, 20.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 24, Color("9b5cff"), 1.5)
