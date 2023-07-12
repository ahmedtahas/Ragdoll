extends Node2D

func _ready() -> void:
	for child_1 in get_children():
		if child_1 is RigidBody2D:
			for child_2 in get_children():
				if child_1 != child_2 and child_2 is RigidBody2D:
					child_1.add_collision_exception_with(child_2)
