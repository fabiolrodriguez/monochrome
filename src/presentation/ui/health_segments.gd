class_name HealthSegments
extends Control

@export_range(1.0, 100.0, 1.0) var health_per_segment := 10.0

var current_health := 100.0
var maximum_health := 100.0


func set_health(current: float, maximum: float) -> void:
	current_health = maxf(current, 0.0)
	maximum_health = maxf(maximum, health_per_segment)
	queue_redraw()


func _draw() -> void:
	var count := maxi(ceili(maximum_health / health_per_segment), 1)
	var gap := 1.0
	var segment_width := maxf(floorf((size.x - gap * float(count - 1)) / float(count)), 2.0)
	var segment_height := maxf(size.y - 2.0, 2.0)
	for index: int in count:
		var rect := Rect2(Vector2(float(index) * (segment_width + gap), 1.0), Vector2(segment_width, segment_height))
		draw_rect(rect, Color("17191d"), true)
		draw_rect(rect, Color("656972"), false, 1.0)
		var segment_start := float(index) * health_per_segment
		var fill_ratio := clampf((current_health - segment_start) / health_per_segment, 0.0, 1.0)
		if fill_ratio > 0.0:
			var fill_rect := Rect2(rect.position + Vector2.ONE, Vector2(maxf((rect.size.x - 2.0) * fill_ratio, 0.0), maxf(rect.size.y - 2.0, 0.0)))
			draw_rect(fill_rect, Color("f2f2f2"), true)
