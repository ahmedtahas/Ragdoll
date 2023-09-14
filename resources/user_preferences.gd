class_name UserPreferences extends Resource

@export_range(0, 1, .05) var music_audio_level: float = 1.0
@export_range(0, 1, .05) var sfx_audio_level: float = 1.0

@export var joystick_switch: bool = false

func save() -> void:
	ResourceSaver.save(self, "res://resources/user_prefs.tres")


static func load_or_create() -> UserPreferences:
	var prefs: UserPreferences = load("res://resources/user_prefs.tres") as UserPreferences
	if !prefs:
		prefs = UserPreferences.new()
	return prefs



