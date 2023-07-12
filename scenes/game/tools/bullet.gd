extends CharacterBody2D

var vel: Vector2 = Vector2.RIGHT
var speed: float = 20000

signal hit_signal

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		var collision = move_and_slide()
		if collision:
			emit_signal("hit_signal", get_last_slide_collision().get_collider())
		$Synchronizer.pos = global_position
		$Synchronizer.rot = global_rotation
	else:
		global_position = $Synchronizer.pos
		global_rotation = $Synchronizer.rot
	
	

func fire(angle: float) -> void:
	set_velocity(vel.rotated(angle) * speed)
