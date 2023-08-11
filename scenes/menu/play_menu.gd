extends Control


func multi_player() -> void:
	CharacterSelection.mode = "world"
	get_tree().change_scene_to_file("res://scenes/menu/character_selection.tscn")


func single_player() -> void:
	CharacterSelection.mode = "singleplayer_world"
	get_tree().change_scene_to_file("res://scenes/menu/character_selection.tscn")


func options() -> void:
	pass


func back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()
