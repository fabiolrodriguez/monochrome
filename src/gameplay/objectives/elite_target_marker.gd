extends Node2D

var target: Enemy
var _pulse := 0.0


func _process(delta: float) -> void:
	_pulse += delta
	if is_instance_valid(target):
		global_position = target.global_position
	queue_redraw()


func _draw() -> void:
	var radius := 15.0 + sin(_pulse * 4.0) * 2.0
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color("ffd84a"), 1.5)
	draw_polyline(PackedVector2Array([Vector2(-4, -21), Vector2.ZERO - Vector2(0, 16), Vector2(4, -21)]), Color("ffd84a"), 1.5)
