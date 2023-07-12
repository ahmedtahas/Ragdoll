extends RigidBody2D

@onready var loc: Vector2 = Vector2.ZERO
@onready var rot: float = 0
@onready var teleporting: bool = false
@onready var power: float

func set_power() -> void:
	power = get_node("/root/Config").get_value("power", get_node("../..").character_name)


func _integrate_forces(state):
	if teleporting:
		state.transform = Transform2D(rot,  loc)
		teleporting = false
	if state.get_contact_count() > 0:
		if state.get_contact_collider_object(0) is CharacterBody2D:
			state.apply_impulse((state.get_contact_local_normal(0)).normalized() * power)
			for child in get_parent().get_children():
				child.apply_impulse((state.get_contact_local_normal(0)).normalized() * power / 2)
func teleport() -> void:
	teleporting = true
	
func locate(_loc: Vector2) -> void:
	loc = _loc
	
func _rotate(_rot: float) -> void:
	rot = _rot

