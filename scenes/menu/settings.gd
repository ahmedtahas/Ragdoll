extends Control

const joystick_state: Dictionary = {
	false: "Skill | Movement",
	true: "Movement | Skill"
}

@onready var user_prefs: UserPreferences


func _enter_tree() -> void:
	user_prefs = UserPreferences.load_or_create()
	if user_prefs:
		$MusicSlider.value = user_prefs.music_audio_level
		$CheckButton.button_pressed = user_prefs.joystick_switch
		update_joystick_state()


func _input(event):
	if event is InputEventScreenDrag:
		if $Swiper.get_swipe_direction(event.relative, 2) == Vector2.RIGHT:
			get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()


func update_joystick_state() -> void:
	$joystick.text = joystick_state.get(user_prefs.joystick_switch)


func _on_check_button_toggled(button_pressed: bool) -> void:
	if user_prefs:
		user_prefs.joystick_switch = button_pressed
		user_prefs.save()
		update_joystick_state()


func music_level_set(value: float) -> void:
	if user_prefs:
		user_prefs.music_audio_level = value
		user_prefs.save()
