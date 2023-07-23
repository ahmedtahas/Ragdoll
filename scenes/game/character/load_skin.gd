extends Node2D


@onready var path: String

func load_skin(character_name: String) -> void:
	path = "res://assets/sprites/character/equipped/" + character_name + "/"
	for child in get_children():
		if FileAccess.file_exists(path + child.name + ".png") and child.has_node("Sprite"):
			child.get_node("Sprite").texture = load(path + child.name + ".png")
	if get_node("RF").has_node("Sprite"):
		get_node("RF/Sprite").weapon_collision(character_name)
	if get_node("LF").has_node("Sprite"):
		get_node("LF/Sprite").weapon_collision(character_name)
	get_node("../RemoteCharacter").copy()
