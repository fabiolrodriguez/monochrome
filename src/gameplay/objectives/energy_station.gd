class_name EnergyStation
extends Area2D

var _pulse := 0.0


func _ready() -> void:
	add_to_group("objective_target")
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var radius := 20.0 + sin(_pulse * 2.5) * 2.0
	draw_circle(Vector2.ZERO, radius, Color(0.25, 0.85, 1.0, 0.06))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color("63dcff"), 2.0)
	draw_arc(Vector2.ZERO, 10.0, -_pulse, PI - _pulse, 16, Color.WHITE, 1.0)
	draw_arc(Vector2.ZERO, 10.0, PI - _pulse, TAU - _pulse, 16, Color("63dcff"), 1.0)
