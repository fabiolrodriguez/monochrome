class_name BlackLakePool
extends Area2D

@export var radius := 70.0
@export var movement_multiplier := 0.72
var _pulse := 0.0


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	$CollisionShape2D.shape = circle
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player != null:
		player.set_movement_modifier(&"black_lake", movement_multiplier)


func _on_body_exited(body: Node) -> void:
	var player := body as Player
	if player != null:
		player.set_movement_modifier(&"black_lake", 1.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color("030407"))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.25, 0.35, 0.45, 0.65), 1.0)
	for index: int in 5:
		var y := -radius * 0.6 + float(index) * radius * 0.3
		var width := sqrt(maxf(radius * radius - y * y, 0.0)) * 0.65
		draw_line(Vector2(-width, y), Vector2(width, y), Color(0.22, 0.55, 0.7, 0.12 + sin(_pulse + index) * 0.03), 1.0)
