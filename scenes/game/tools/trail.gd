extends Line2D

@onready var length: int = 10
@onready var parent: Marker2D = get_parent()
@onready var trailing: bool = false

func _ready() -> void:
	await get_tree().create_timer(0.01).timeout


func  _physics_process(_delta: float) -> void:
	global_position = Vector2.ZERO
	global_rotation = 0
	add_point(parent.global_position)
	while get_point_count() > (length / Engine.time_scale):
		remove_point(0)
