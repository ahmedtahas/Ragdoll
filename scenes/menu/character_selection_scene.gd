extends Control


func _ready() -> void:
	for child in get_node("Buttons").get_children():
		child.pressed.connect(self.character_selected.bind(child.name))


func character_selected(selection: String) -> void:
	CharacterSelection.own = selection
	get_tree().change_scene_to_file("res://scenes/world.tscn")

