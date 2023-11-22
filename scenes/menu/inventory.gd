extends Control


@onready var pilot_item = $Items/ItemContainer/HBoxContainer/PilotItem
var path: String = "res://assets/sprites/character/equipped/tin/Body.png"


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			print("pressed")
			pilot_item.add_item(path)
	if event is InputEventScreenDrag:
		if $Swiper.get_swipe_direction(event.relative, 27) == Vector2.RIGHT:
			store()
		if $Swiper.get_swipe_direction(event.relative, 27) == Vector2.LEFT:
			play()


func play() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func store() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/store.tscn")


func settings() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/settings.tscn")
