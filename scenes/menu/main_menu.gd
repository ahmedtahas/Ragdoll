extends Control


func multi_player() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/multiplayer_character_selection.tscn")


func single_player() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/singleplayer_character_selection.tscn")
	

func options() -> void:
	pass

	
