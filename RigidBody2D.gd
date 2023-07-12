extends RigidBody2D


var thrust = Vector2(0, -250)
var torque = 20000

func _integrate_forces(state):
	if Input.is_action_pressed("ui_up"):
		state.apply_force(thrust.rotated(rotation))
	else:
		state.apply_force(Vector2())
	var rotation_direction = 0
	if global_rotation < (Vector2(-250,250) - global_position).angle():
		rotation_direction += 15
	else:
		rotation_direction -= 15
	if Input.is_action_pressed("ui_right"):
		rotation_direction += 5
	if Input.is_action_pressed("ui_left"):
		rotation_direction -= 5
#	state.apply_torque(rotation_direction * torque)
	state.apply_torque(rotation_direction * torque)

#var thrust = Vector2(0, -250)
#var torque = 20000
#
#var flash = false
#var push = false
#var jumped = false
#var look = false
#var jump = Vector2(700, 0)
#
#func _physics_process(delta: float) -> void:
#	if Input.is_action_pressed("ui_right"):
#		push = true
#		gravity_scale = 0
#		await get_tree().create_timer(1).timeout
#		push = false
#		gravity_scale = 0.5
#
#	if Input.is_action_pressed("ui_left"):
#		look = true
#	else:
#		look = false
#
#	if Input.is_action_pressed("ui_up"):
#		apply_force(Vector2.UP * 5000)
#	if Input.is_action_pressed("ui_down"):
#		await get_tree().create_timer(3).timeout
#		flash = true
#
#
#func _integrate_forces(state):
#	if flash:
#		state.transform = Transform2D(0,  Vector2(0,0))
#		flash = false
#
#	if push:
#		state.apply_central_impulse(Vector2(100,0))
##		state.apply_force(Vector2(0, 250))
#
#	if jumped:
#		state.transform = Transform2D(0, state.get_contact_collider_position(0) + jump)
#		print(state.get_contact_collider_position(0), " :: ", state.get_contact_collider(0))
#		print(global_position, "  :: ", name)
#		jumped = false
#
#
		



#func _on_body_entered(body: Node) -> void:
#	if body is RigidBody2D and push:
#		push = false
#		print("hello")
#		jumped = true
