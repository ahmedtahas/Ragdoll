extends Line2D

@onready var length: int = 10
@onready var parent: Marker2D = get_parent()

func  _physics_process(_delta: float) -> void:
	
	global_position = Vector2.ZERO
	global_rotation = 0
	add_point(parent.global_position)
	while get_point_count() > (length / Engine.time_scale):
		remove_point(0)
