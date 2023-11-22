extends Control


@onready var description: Label = $Stats/skill/skill_name/skill_description
@onready var character: String

func _ready() -> void:
	for child in get_node("Characters/CharacterContainer").get_children():
		child.pressed.connect(self.character_preview.bind(child.name))
	Global.player_selection = "crock"
	for child in get_node("Stats").get_children():
		child.get_child(0).text = str(get_node("/root/Config").get_value(child.get_child(0).name, "crock"))
	description.text = str(get_node("/root/Config").get_value("skill_description", "crock"))



func character_preview(selection: String) -> void:
	Global.player_selection = selection
	for child in get_node("Stats").get_children():
		child.get_child(0).text = str(get_node("/root/Config").get_value(child.get_child(0).name, selection))
	description.text = str(get_node("/root/Config").get_value("skill_description", selection))


func character_selected() -> void:
	if Global.mode == "multi":
		get_tree().change_scene_to_file("res://scenes/menu/lobby.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/world.tscn")


func back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()

