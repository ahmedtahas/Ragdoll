extends Node2D


func copy() -> void:
	for child in get_children():
		if get_node("../LocalCharacter/" + str(child.name)).has_node("Sprite"):
			child.get_node("Sprite").texture = get_node("../LocalCharacter/" + str(child.name) + "/Sprite").texture
