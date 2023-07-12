extends CharacterBody2D


func _ready() -> void:
	for part in get_children():
		part.get_node("Sprite").texture = get_node("../LocalCharacter/" + str(part.name) + "/Sprite").texture

