extends Node2D


func load_skin(character_name: String) -> void:
	for child in get_children():
		child.dress(character_name)
