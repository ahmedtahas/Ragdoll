extends CharacterBody2D

@onready var sync: Node2D = $"../../Extra"


func _physics_process(_delta: float) -> void:
	global_position = Vector2(sync.part_dict.get(name).x, sync.part_dict.get(name).y)
	global_rotation = sync.part_dict.get(name).z
