extends CharacterBody2D

@onready var vel: Vector2 = Vector2.RIGHT
@onready var speed: float = 20000
@onready var sync: Node2D = $Synchronizer
@onready var collision: bool


signal hit_signal

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		collision = move_and_slide()
		if collision:
			emit_signal("hit_signal", get_last_slide_collision().get_collider())
		sync.pos = global_position
		sync.rot = global_rotation
	else:
		global_position = sync.pos
		global_rotation = sync.rot
	
	

func fire(angle: float) -> void:
	set_velocity(vel.rotated(angle) * speed)
