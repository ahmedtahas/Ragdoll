extends Control


@onready var left_stick_position: Vector2
@onready var right_stick_position: Vector2
@onready var skill_stick: Sprite2D
@onready var movement_stick: Sprite2D


func _enter_tree() -> void:
	skill_stick = get_node("JoystickSwap/Skill")
	movement_stick = get_node("JoystickSwap/Movement")
	left_stick_position = skill_stick.position
	right_stick_position = movement_stick.position
	$MusicSlider.value = Config.get_value("settings", "music_volume")
	update_joystick_state()


func store() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/store.tscn")


func inventory() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/inventory.tscn")


func play() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _input(event):
	if event is InputEventScreenDrag:
		if $Swiper.get_swipe_direction(event.relative, 27) == Vector2.RIGHT:
			play()


func back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()


func on_joystick_swap() -> void:
	Config.update_config("settings", "joystick_swapped", not Config.get_value("settings", "joystick_swapped"))
	update_joystick_state()


func update_joystick_state() -> void:
	if Config.get_value("settings", "joystick_swapped"):
		skill_stick.position = right_stick_position
		movement_stick.position = left_stick_position
	else:
		skill_stick.position = left_stick_position
		movement_stick.position = right_stick_position


func music_level_set(value: float) -> void:
	Config.update_config("settings", "music_volume", $MusicSlider.value)
