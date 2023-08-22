extends GPUParticles2D

@onready var sync: Node2D = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		sync.particles_emitting = emitting
	else:
		emitting = sync.particles_emitting
