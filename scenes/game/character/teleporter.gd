extends RigidBody2D


@onready var loc: Vector2 = Vector2.ZERO
@onready var rot: float = 0
@onready var teleporting: bool = false
@onready var power: float
@onready var contact_normal: Vector2
@onready var sync: Node2D = $"../../Extra"


func set_power(character_name: String) -> void:
	power = get_node("/root/Config").get_value("power", character_name)


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority() and CharacterSelection.mode == "world":
		sync.part_dict[name] = Vector3(global_position.x, global_position.y, global_rotation)


func _integrate_forces(state):
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
