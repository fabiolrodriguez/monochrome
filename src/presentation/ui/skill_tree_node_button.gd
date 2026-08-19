class_name SkillTreeNodeButton
extends Button

signal inspected(node: SkillNodeData)

var data: SkillNodeData
var is_owned := false
var is_available := false


func configure(node: SkillNodeData) -> void:
	data = node
	text = ""
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_entered.connect(_inspect)
	mouse_entered.connect(_inspect)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	queue_redraw()


func set_state(owned: bool, available: bool, hint: String) -> void:
	is_owned = owned
	is_available = available
	tooltip_text = hint
	queue_redraw()


func _inspect() -> void:
	inspected.emit(data)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var fill := Color("17191e")
	var outline := Color("4a4e56")
	if is_owned:
		fill = Color("d9dadd")
		outline = Color.WHITE
	elif is_available:
		fill = Color("292d35")
		outline = Color("d9dadd")
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 24, outline, 2.0)
	if has_focus():
		draw_arc(center, radius + 3.0, 0.0, TAU, 24, Color("ffd84a"), 1.0)
	_draw_symbol(center, Color("111318") if is_owned else outline)


func _draw_symbol(center: Vector2, color: Color) -> void:
	match data.stat_key:
		&"max_health":
			draw_line(center + Vector2(-4, 0), center + Vector2(4, 0), color, 2.0)
			draw_line(center + Vector2(0, -4), center + Vector2(0, 4), color, 2.0)
		&"damage":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -5), center + Vector2(5, 4), center + Vector2(-5, 4)]), color)
		&"movement_speed":
			draw_polyline(PackedVector2Array([center + Vector2(-4, -4), center + Vector2(2, 0), center + Vector2(-4, 4)]), color, 2.0)
		&"fire_rate":
			for offset: int in [-4, 0, 4]:
				draw_line(center + Vector2(-5, offset), center + Vector2(5, offset), color, 1.0)
		&"projectile_speed":
			draw_line(center + Vector2(-5, 0), center + Vector2(4, 0), color, 2.0)
			draw_polyline(PackedVector2Array([center + Vector2(1, -3), center + Vector2(5, 0), center + Vector2(1, 3)]), color, 1.0)
		&"pickup_radius":
			draw_arc(center, 5.0, 0.0, TAU, 16, color, 1.0)
			draw_circle(center, 1.5, color)
		&"coin_gain":
			draw_circle(center, 5.0, color)
			draw_circle(center, 2.5, fill_color())
		_:
			draw_arc(center, 5.0, 0.5, 5.5, 16, color, 2.0)
			draw_line(center + Vector2(3, -4), center + Vector2(5, 0), color, 1.0)


func fill_color() -> Color:
	return Color("d9dadd") if is_owned else Color("17191e")

