extends RigidBody2D

@onready var dash_speed: Vector2 = Vector2.RIGHT * 470
@onready var dash_direction: float = 0
@onready var dashing: bool = false
@onready var location: Vector2 = Vector2.ZERO
@onready var teleporting: bool = false


func teleport() -> void:
	teleporting = true


func locate(_location: Vector2) -> void:
	location = _location


func set_dashing(_dashing: bool):
	dashing = _dashing


func direct(angle: float) -> void:
	dash_direction = angle


func _integrate_forces(state):
	if teleporting:
		state.transform = Transform2D(0,  location)
		teleporting = false

	if dashing:
		state.apply_central_impulse(dash_speed.rotated(dash_direction))

