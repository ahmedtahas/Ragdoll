extends Node2D


@onready var path: String

func load_skin(character_name: String) -> void:
	path = "res://assets/sprites/character/equipped/" + character_name + "/"
	for child in get_children():
		if FileAccess.file_exists(path + child.name + ".png") and child.has_node("Sprite"):
			child.get_node("Sprite").texture = load(path + child.name + ".png")
	if character_name != "bot":
		if get_node("RF").has_node("Sprite"):
			get_node("RF/Sprite").weapon_collision(character_name)
		if get_node("LF").has_node("Sprite"):
			get_node("LF/Sprite").weapon_collision(character_name)


func freeze_children(direction: Vector2, strength: float):
	for child in get_children():
		child.freeze = true
	for child in get_children():
		child.freeze = false
	for child in get_children():
		child.apply_impulse(direction * strength)
