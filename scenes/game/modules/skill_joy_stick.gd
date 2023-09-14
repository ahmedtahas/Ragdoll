extends Control

@onready var skill_area: TouchScreenButton = $SkillArea
@onready var skill_stick: Sprite2D = $SkillStick
@onready var skill_area_position: Vector2
@onready var skill_stick_position: Vector2

@onready var skill_center: Vector2
@onready var skill_radius: float

@onready var button: bool = false
@onready var moving: bool = false
@onready var using: bool = false

signal skill_signal


func _ready() -> void:
	if Global.switch:
		position = Global.ui_right
		skill_area_position = Global.left_area_position
		skill_stick_position = Global.left_stick_position
	else:
		position = Global.ui_left
		skill_area_position = Global.right_area_position
		skill_stick_position = Global.right_stick_position
	skill_radius = skill_area.texture_normal.get_size().x / 2
	skill_area.global_position = skill_area_position
	skill_stick.global_position = skill_stick_position
	skill_area.modulate.a = 0.2
	skill_stick.modulate.a = 0.2


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		skill_area.modulate.a = 1
		skill_stick.modulate.a = 1
		if not button:
			skill_center = event.position
			skill_area.position = skill_center - Vector2(skill_radius, skill_radius)
			skill_stick.position = event.position

		else:
			skill_center = event.position
			skill_area.position = skill_center - Vector2(skill_radius, skill_radius)
			skill_stick.position = event.position
			skill_signal.emit(true)


	elif event is InputEventScreenDrag:
		if not button:
			skill_stick.position = event.position
			if event.position.distance_to(skill_center) > skill_radius:
				var temp: Vector2 = event.position - skill_center
				temp *= skill_radius / event.position.distance_to(skill_center)
				skill_stick.position = temp + skill_center
			skill_signal.emit((event.position - skill_center).normalized(), true)


	elif event is InputEventScreenTouch and not event.is_pressed():
		skill_area.global_position = skill_area_position
		skill_stick.global_position = skill_stick_position
		skill_area.modulate.a = 0.2
		skill_stick.modulate.a = 0.2
		if button:
			skill_signal.emit(false)
		else:
			skill_signal.emit(Vector2.ZERO, false)

