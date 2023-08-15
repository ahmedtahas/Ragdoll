extends Control


func _input(event):
	if event is InputEventScreenDrag:
		if $Swiper.get_swipe_direction(event.relative, 2) == Vector2.LEFT:
			get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")



func back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()
