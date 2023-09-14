extends RigidBody2D



@onready var loc: Vector2 = Vector2.ZERO
@onready var rot: float = 0
@onready var teleporting: bool = false
@onready var power: float
@onready var contact_normal: Vector2
@onready var ice_color: Color = Color(0.713725, 0.898039, 0.929412)
@onready var image: Sprite2D

@export var glo_pos: Vector2 = Vector2.ZERO
@export var glo_rot: float = 0


func _ready() -> void:
	if has_node("Sprite"):
		image = get_node("Sprite")


func set_power(character_name: String) -> void:
	power = Config.get_value("power", character_name)


func _integrate_forces(state):
	if not is_multiplayer_authority():
		state.transform = Transform2D(glo_rot, glo_pos)
		return
	if state.get_velocity_at_local_position(Vector2.ZERO).length() > 12000:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
	if state.get_contact_count() > 0:
		if state.get_contact_collider_object(0) is StaticBody2D:
			if not Global.is_inside(global_position):
				locate(Global.get_inside_coordinates(global_position))
				rotate(global_rotation)
				teleport()
		if state.get_contact_collider_object(0) is RigidBody2D:
			contact_normal = state.get_contact_local_normal(0).normalized()
			state.apply_impulse(contact_normal * power)
			for child in get_parent().get_children():
				child.apply_impulse(contact_normal * power)
	if teleporting:
		state.transform = Transform2D(rot, loc)
		teleporting = false


func teleport() -> void:

	teleporting = true


func locate(_loc: Vector2) -> void:
	loc = _loc


func _rotate(_rot: float) -> void:
	rot = _rot


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	glo_pos = global_position
	glo_rot = global_rotation


func freeze_self(mode: bool) -> void:
	freeze = mode
	if image:
		if mode:
			image.modulate = ice_color
		else:
			image.modulate = Color(1, 1, 1)


func dress(character_name: String) -> void:
	var path = "assets/sprites/character/equipped/" + character_name + "/"
	if image:
		image.texture = load(path + name + ".png")
		if name == "RF" or name == "LF" or name == "RK" or name == "LK":
			image.weapon_collision(character_name)
