extends Control


@onready var joystick_swapped: bool = false

@onready var user_prefs: UserPreferences

@onready var left_stick_position: Vector2
@onready var right_stick_position: Vector2
@onready var skill_stick: Sprite2D
@onready var movement_stick: Sprite2D


func _enter_tree() -> void:
	skill_stick = get_node("JoystickSwap/Skill")
	movement_stick = get_node("JoystickSwap/Movement")
	left_stick_position = skill_stick.position
	right_stick_position = movement_stick.position
	user_prefs = UserPreferences.load_or_create()
	if user_prefs:
		$MusicSlider.value = user_prefs.music_audio_level
		joystick_swapped = user_prefs.joystick_switch
		update_joystick_state()


func _input(event):
	if event is InputEventScreenDrag:
		if $Swiper.get_swipe_direction(event.relative, 27) == Vector2.RIGHT:
			get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()


func on_joystick_swap() -> void:
	if user_prefs:
		user_prefs.joystick_switch = !user_prefs.joystick_switch
		user_prefs.save()
		update_joystick_state()


func update_joystick_state() -> void:
	if user_prefs.joystick_switch:
		skill_stick.position = right_stick_position
		movement_stick.position = left_stick_position
	else:
		skill_stick.position = left_stick_position
		movement_stick.position = right_stick_position


func music_level_set(value: float) -> void:
	if user_prefs:
		user_prefs.music_audio_level = value
		user_prefs.save()
