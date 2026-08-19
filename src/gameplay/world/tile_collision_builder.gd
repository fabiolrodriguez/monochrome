class_name TileCollisionBuilder
extends RefCounted


static func attach_static_body(layer: TileMapLayer, shape_size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "GeneratedCollision"
	body.collision_layer = 1
	body.collision_mask = 6
	layer.add_child(body)
	for cell: Vector2i in layer.get_used_cells():
		var rectangle := RectangleShape2D.new()
		rectangle.size = shape_size
		var collision := CollisionShape2D.new()
		collision.position = layer.map_to_local(cell)
		collision.shape = rectangle
		body.add_child(collision)
	return body

