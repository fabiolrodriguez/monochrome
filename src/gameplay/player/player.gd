class_name Player
extends CharacterBody2D

@export_range(1.0, 500.0, 1.0) var movement_speed: float = 80.0
@export_range(0.0, 1.0, 0.05) var gamepad_aim_deadzone: float = 0.25

@onready var weapon: Weapon = $Weapon

var aim_direction := Vector2.RIGHT


func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * movement_speed
	move_and_slide()
	_update_aim()
	weapon.set_trigger_pressed(Input.is_action_pressed("shoot"))
	queue_redraw()


func _update_aim() -> void:
	var gamepad_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if gamepad_aim.length() >= gamepad_aim_deadzone:
		aim_direction = gamepad_aim.normalized()
	else:
		var mouse_offset := get_global_mouse_position() - global_position
		if not mouse_offset.is_zero_approx():
			aim_direction = mouse_offset.normalized()
	weapon.aim_at(aim_direction)


func _draw() -> void:
	# Logic and collision remain independent from this replaceable placeholder art.
	draw_circle(Vector2.ZERO, 6.0, Color.WHITE)
	draw_circle(Vector2.ZERO, 3.0, Color(0.04, 0.04, 0.05, 1.0))
	draw_line(Vector2.ZERO, aim_direction * 10.0, Color.WHITE, 2.0)

