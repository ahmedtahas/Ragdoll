extends RigidBody2D



@onready var loc: Vector2 = Vector2.ZERO
@onready var rot: float = 0
@onready var teleporting: bool = false
@onready var power: float
@onready var contact_normal: Vector2
@export var glo_pos: Vector2 = Vector2.ZERO
@export var glo_rot: float = 0

func set_power(character_name: String) -> void:
	power = get_node("/root/Config").get_value("power", character_name)


func _ready() -> void:
	if not is_multiplayer_authority():
		loc = Vector2(10000, -5000)

func _integrate_forces(state):
	if not is_multiplayer_authority():
		state.transform = Transform2D(glo_rot, glo_pos)
		print(state.transform)
		return
	if state.get_contact_count() > 0:
		if state.get_contact_collider_object(0) is CharacterBody2D or state.get_contact_collider_object(0) is RigidBody2D:
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


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		glo_pos = global_position
		glo_rot = global_rotation


func dress(character_name: String) -> void:
	var path = "res://assets/sprites/character/equipped/" + character_name + "/"
	if FileAccess.file_exists(path + name + ".png") and has_node("Sprite"):
			get_node("Sprite").texture = load(path + name + ".png")
