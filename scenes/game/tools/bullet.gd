extends CharacterBody2D

var vel: Vector2 = Vector2(1, 0)
var speed: float = 20000

signal hit_signal

func _physics_process(_delta: float) -> void:
	var collision = move_and_slide()
	if collision:
		emit_signal("hit_signal", get_last_slide_collision().get_collider())
	
	
	
func _set_velocity(angle: float) -> void:
	set_velocity(vel.rotated(angle) * speed)
