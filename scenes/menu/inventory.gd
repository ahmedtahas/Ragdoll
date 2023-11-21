extends Control


func _input(event):
	if event is InputEventScreenDrag:
		if $Swiper.get_swipe_direction(event.relative, 27) == Vector2.RIGHT:
			play()
		if $Swiper.get_swipe_direction(event.relative, 27) == Vector2.LEFT:
			store()


func play() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func store() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/store.tscn")


func settings() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/store.tscn")
