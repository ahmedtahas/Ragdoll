extends Control


func _ready() -> void:
	$MarginContainer/VBoxContainer/VBoxContainer/MarginContainer/Multi.button_up.connect(mode_selected.bind("multi"))
	$MarginContainer/VBoxContainer/VBoxContainer/MarginContainer2/Single.button_up.connect(mode_selected.bind("single"))
	$MarginContainer/VBoxContainer/VBoxContainer/MarginContainer3/Back.button_up.connect(back)


func mode_selected(mode: String) -> void:
	Global.mode = mode
	get_tree().change_scene_to_file("res://scenes/menu/character_selection.tscn")


func options() -> void:
	pass


func back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()
