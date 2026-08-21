class_name ObjectiveSignposts
extends Node2D

const ATLAS := preload("res://assets/art/kenney_1bit/monochrome_tilemap.png")
const TILE_SIZE := Vector2(16.0, 16.0)
const LEFT_ARROW := Vector2i(12, 3)
const RIGHT_ARROW := Vector2i(13, 3)
const SIGN_POSITIONS: Array[Vector2] = [
	Vector2(-320, -160), Vector2(0, -320), Vector2(320, -160),
	Vector2(-320, 160), Vector2(0, 320), Vector2(320, 160),
	Vector2(-160, 0), Vector2(160, 0),
]

var _signs: Array[Sprite2D] = []
var _refresh_remaining := 0.0
var _left_texture: AtlasTexture
var _right_texture: AtlasTexture


func _ready() -> void:
	_left_texture = _arrow_texture(LEFT_ARROW)
	_right_texture = _arrow_texture(RIGHT_ARROW)
	for sign_position: Vector2 in SIGN_POSITIONS:
		var sign := Sprite2D.new()
		sign.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sign.position = sign_position
		sign.z_index = 1
		sign.hide()
		add_child(sign)
		_signs.append(sign)
	_refresh_signs()


func _process(delta: float) -> void:
	_refresh_remaining -= delta
	if _refresh_remaining <= 0.0:
		_refresh_remaining = 0.2
		_refresh_signs()


func _refresh_signs() -> void:
	var targets: Array[Node2D] = []
	for candidate: Node in get_tree().get_nodes_in_group("objective_target"):
		var target := candidate as Node2D
		if target != null and is_instance_valid(target) and target.is_visible_in_tree():
			targets.append(target)
	for sign: Sprite2D in _signs:
		var target := _nearest_target(sign.global_position, targets)
		if target == null or sign.global_position.distance_squared_to(target.global_position) < 96.0 * 96.0:
			sign.hide()
			continue
		var direction := sign.global_position.direction_to(target.global_position)
		var points_right := direction.x >= 0.0
		sign.texture = _right_texture if points_right else _left_texture
		# Keep the plaque upright for mostly horizontal guidance. Rotate it only
		# when the objective is clearly above or below the crossroads.
		sign.rotation = 0.0
		if absf(direction.y) > absf(direction.x) * 1.35:
			sign.texture = _right_texture
			sign.rotation = PI * 0.5 if direction.y > 0.0 else -PI * 0.5
		sign.show()


func _nearest_target(origin: Vector2, targets: Array[Node2D]) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for target: Node2D in targets:
		var distance := origin.distance_squared_to(target.global_position)
		if distance < nearest_distance:
			nearest = target
			nearest_distance = distance
	return nearest


func _arrow_texture(atlas_coordinate: Vector2i) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = Rect2(Vector2(atlas_coordinate) * TILE_SIZE, TILE_SIZE)
	return texture
