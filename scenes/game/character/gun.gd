extends Sprite2D

func gun(character_name) -> void:
	texture = load("res://assets/sprites/character/equipped/" + character_name + "/RF.png")
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image())
	var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, texture.get_size()))[0]
	var collision_polygon = CollisionPolygon2D.new()
	collision_polygon.polygon = polys
	add_child(collision_polygon)
	collision_polygon.reparent.call_deferred(get_parent())
	if centered:
		collision_polygon.position -= Vector2(bitmap.get_size()) / 2
	
