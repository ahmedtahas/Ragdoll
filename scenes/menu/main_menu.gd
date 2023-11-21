extends Control


func _ready() -> void:
	$MultiPlayer.pressed.connect(mode_selected.bind("multi"))
	$SinglePlayer.pressed.connect(mode_selected.bind("single"))
	$Store.pressed.connect(store)
	$Inventory.pressed.connect(inventory)
	$Settings.pressed.connect(settings)


func _input(event):
	if event is InputEventScreenDrag:
		if $Swiper.get_swipe_direction(event.relative, 27) == Vector2.RIGHT:
			inventory()
		if $Swiper.get_swipe_direction(event.relative, 27) == Vector2.LEFT:
			settings()


func store() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/store.tscn")


func settings() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/settings.tscn")


func inventory() -> void:
	pass
	get_tree().change_scene_to_file("res://scenes/menu/inventory.tscn")


func mode_selected(mode: String) -> void:
	Global.mode = mode
	get_tree().change_scene_to_file("res://scenes/menu/character_selection.tscn")
