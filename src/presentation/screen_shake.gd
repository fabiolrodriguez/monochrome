class_name ScreenShake
extends Camera2D

@export_range(0.0, 16.0, 0.5) var maximum_offset := 5.0
@export_range(1.0, 20.0, 0.5) var decay_speed := 8.0

var _trauma := 0.0
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()


func _process(delta: float) -> void:
	_trauma = maxf(_trauma - decay_speed * delta, 0.0)
	if not SettingsManager.screen_shake or _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	var strength := _trauma * _trauma
	offset = Vector2(_random.randf_range(-1.0, 1.0), _random.randf_range(-1.0, 1.0)) * maximum_offset * strength


func add_trauma(amount: float) -> void:
	if SettingsManager.screen_shake:
		_trauma = clampf(_trauma + amount, 0.0, 1.0)
