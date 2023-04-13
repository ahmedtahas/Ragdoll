extends Sprite2D

@onready var weapon_texture = load("res://assets/sprites/weapon/" + get_parent().get_parent().name.replace("@", "").rstrip("0123456789").to_lower() + "/weapon.png")


func _ready() -> void:
	print(str(get_parent().get_parent().name.replace("@", "").replace(str(int(str(name))), "").to_lower()))
	texture = weapon_texture
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image())
	var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, texture.get_size()))[0]
	var collision_polygon = CollisionPolygon2D.new()
	collision_polygon.polygon = polys
	add_child(collision_polygon)
	collision_polygon.reparent.call_deferred(get_parent())
	if centered:
		collision_polygon.position -= Vector2(bitmap.get_size()) / 2
