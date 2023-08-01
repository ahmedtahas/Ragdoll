extends Control


func multi_player() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/world.tscn")


func single_player() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/singleplayer_world.tscn")


func options() -> void:
	pass


