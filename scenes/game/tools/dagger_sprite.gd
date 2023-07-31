extends Sprite2D


func weapon_collision() -> void:
	var bitmap: BitMap = BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image())
	var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, texture.get_size()))[0]
	var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
	collision_polygon.polygon = polys
	add_child(collision_polygon)
	var top = Vector2.ZERO
	for poly in polys:
		if poly.y > top.y:
			top = poly
	get_node("../Marker").position -= Vector2(0, top.y)
	collision_polygon.reparent.call_deferred(get_parent())
	if centered:
		collision_polygon.position -= Vector2(bitmap.get_size()) / 2
		get_node("../Marker").position += Vector2(0, (Vector2(bitmap.get_size()) / 3).y + 30)
