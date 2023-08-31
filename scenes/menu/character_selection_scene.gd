extends Control


func _ready() -> void:
	for child in get_node("Buttons/ButtonContainer").get_children():
		child.pressed.connect(self.character_preview.bind(child.name))
	Global.player_selection = "crock"
	for child in get_node("Stats").get_children():
		if child is Label:
			child.text = str(get_node("/root/Config").get_value(child.name, "crock"))
	get_node("SkillDescription").text = get_node("/root/Config").get_value("skill_description", "crock")


func character_preview(selection: String) -> void:
	Global.player_selection = selection
	for child in get_node("Stats").get_children():
		if child is Label:
			child.text = str(get_node("/root/Config").get_value(child.name, selection))
	get_node("SkillDescription").text = get_node("/root/Config").get_value("skill_description", selection)


func character_selected() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/world.tscn")


func back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/play_menu.tscn")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()

