extends RigidBody2D

@onready var power: float
@onready var contact_normal: Vector2


func set_power(character_name: String) -> void:
	power = get_node("/root/Config").get_value("power", character_name)


func _integrate_forces(state):
	if state.get_contact_count() > 0:
		if state.get_contact_collider_object(0) is CharacterBody2D or state.get_contact_collider_object(0) is RigidBody2D:
			contact_normal = state.get_contact_local_normal(0).normalized()
			state.apply_impulse(contact_normal * power)
			for child in get_parent().get_children():
				child.apply_impulse(contact_normal * power / 2)
