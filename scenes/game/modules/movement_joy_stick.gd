extends Control

@onready var movement_area: TouchScreenButton = $MovementArea
@onready var movement_stick: Sprite2D = $MovementStick
@onready var movement_area_position: Vector2
@onready var movement_stick_position: Vector2

@onready var movement_center: Vector2
@onready var movement_radius: float

@onready var moving: bool = false
@onready var using: bool = false

@onready var user_prefs: UserPreferences

signal move_signal


func _ready() -> void:
	user_prefs = UserPreferences.load_or_create()
	if user_prefs:
		if user_prefs.joystick_switch:
			position = Global.ui_left
			movement_area_position = Global.right_area_position
			movement_stick_position = Global.right_stick_position
		else:
			position = Global.ui_right
			movement_area_position = Global.left_area_position
			movement_stick_position = Global.left_stick_position
		movement_radius = movement_area.texture_normal.get_size().x / 2
		movement_area.global_position = movement_area_position
		movement_stick.global_position = movement_stick_position
		movement_area.modulate.a = 0.2
		movement_stick.modulate.a = 0.2


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		movement_area.modulate.a = 1
		movement_stick.modulate.a = 1
		movement_center = event.position
		movement_area.position = movement_center - Vector2(movement_radius, movement_radius)
		movement_stick.position = event.position


	elif event is InputEventScreenDrag:
		movement_stick.position = event.position
		if event.position.distance_to(movement_center) > movement_radius:
			var temp: Vector2 = event.position - movement_center
			temp *= movement_radius / event.position.distance_to(movement_center)
			movement_stick.position = temp + movement_center
		move_signal.emit((event.position - movement_center).normalized())


	elif event is InputEventScreenTouch and not event.is_pressed():
		movement_area.global_position = movement_area_position
		movement_stick.global_position = movement_stick_position
		movement_area.modulate.a = 0.2
		movement_stick.modulate.a = 0.2
		move_signal.emit(Vector2.ZERO)

