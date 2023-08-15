extends Control


func _input(event):
	if event is InputEventScreenDrag:
		if $Swiper.get_swipe_direction(event.relative, 2) == Vector2.RIGHT:
			store()
		if $Swiper.get_swipe_direction(event.relative, 2) == Vector2.LEFT:
			options()

func play() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/play_menu.tscn")

func store() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/store.tscn")

func options() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/options.tscn")
