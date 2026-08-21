class_name SkillTreeNodeButton
extends Button

signal inspected(node: SkillNodeData)

var data: SkillNodeData
var is_owned := false
var is_path_unlocked := false
var is_affordable := false


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
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	queue_redraw()


func set_state(owned: bool, path_unlocked: bool, affordable: bool, hint: String) -> void:
	is_owned = owned
	is_path_unlocked = path_unlocked
	is_affordable = affordable
	tooltip_text = hint
	queue_redraw()


func _inspect() -> void:
	inspected.emit(data)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.43
	var fill := Color("08090c")
	var outline := Color("272a31")
	if is_owned:
		fill = Color("f0f1f3")
		outline = Color.WHITE
	elif is_path_unlocked:
		fill = Color("1c2028")
		outline = Color.WHITE if is_affordable else Color("727781")
	var highlighted := has_focus() or is_hovered()
	if highlighted:
		draw_circle(center, radius + 4.0, Color(1.0, 0.85, 0.29, 0.14))
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 24, outline, 2.0)
	if is_owned:
		draw_arc(center, radius - 3.0, 0.0, TAU, 20, Color("252830"), 1.0)
	if highlighted:
		draw_arc(center, radius + 3.0, 0.0, TAU, 28, Color("ffd84a"), 2.0)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius - 6), center + Vector2(-3, -radius - 10), center + Vector2(3, -radius - 10)]), Color("ffd84a"))
	var symbol_color := Color("08090b") if is_owned else (Color.WHITE if is_path_unlocked and is_affordable else (Color("9297a1") if is_path_unlocked else Color("3b3f47")))
	if data.icon != null:
		var icon_size := clampf(radius * 1.55, 11.0, 18.0)
		var icon_rect := Rect2(center - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size)
		draw_texture_rect(data.icon, icon_rect, false, symbol_color)
	else:
		_draw_symbol(center, symbol_color)


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
