extends CharacterBody2D

@onready var vel: Vector2 = Vector2.RIGHT
@onready var speed: float = 10000
@onready var sync: Node2D = $Synchronizer
@onready var original_position: Vector2
@onready var position_set: bool = false
@onready var max_distance: float = 6900


signal hit_signal
signal travel_signal


func _ready() -> void:
	$Sprite2D.texture = load("res://assets/sprites/character/equipped/zeina/RF.png")
	var bitmap: BitMap = BitMap.new()
	bitmap.create_from_image_alpha($Sprite2D.texture.get_image())
	var polys: Array = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, $Sprite2D.texture.get_size()))[0]
	var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
	var top: float = bitmap.get_size().y
	for pol in polys:
		if pol.y < top:
			top = pol.y
	collision_polygon.polygon = polys
	add_child(collision_polygon)
	collision_polygon.position -= Vector2(bitmap.get_size()) / 2
	$Marker.position.y = (top - (float(bitmap.get_size().y) / 2)) * 6 / 7


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		if move_and_slide():
			hit_signal.emit(get_last_slide_collision().get_collider())
		global_rotation += 0.5 * Engine.time_scale
		sync.pos = global_position
		sync.rot = global_rotation
		if not position_set:
			return
		if (global_position - original_position).length() >= max_distance:
			travel_signal.emit()
	else:
		global_position = sync.pos
		global_rotation = sync.rot


func fire(angle: float) -> void:
	set_velocity(vel.rotated(angle) * speed)


func _enter_tree() -> void:
	Global.camera.add_target(self)


func _exit_tree() -> void:
	Global.camera.remove_target(self)


func set_original_position() -> void:
	position_set = true
	original_position = global_position
