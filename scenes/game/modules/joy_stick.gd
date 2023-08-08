extends CanvasLayer

@onready var half_screen: float = get_viewport().size.x / 2
@onready var movement_area: TouchScreenButton = $MovementArea
@onready var movement_stick: Sprite2D = $MovementStick
@onready var skill_area: TouchScreenButton = $SkillArea
@onready var skill_stick: Sprite2D = $SkillStick
@onready var skill_area_position: Vector2 = $SAP.position
@onready var skill_stick_position: Vector2 = $SSP.position
@onready var movement_area_position: Vector2 = $MAP.position
@onready var movement_stick_position: Vector2 = $MSP.position

@onready var movement_center: Vector2
@onready var skill_center: Vector2
@onready var movement_radius: float
@onready var skill_radius: float

@onready var button: bool = false
@onready var moving: bool = false
@onready var using: bool = false

signal move_signal
signal skill_signal

func _ready() -> void:
	if not is_multiplayer_authority():
		visible = false
	movement_radius = movement_area.texture_normal.get_size().x / 2
	skill_radius = skill_area.texture_normal.get_size().x / 2
	movement_area.global_position = movement_area_position
	movement_stick.global_position = movement_stick_position
	skill_area.global_position = skill_area_position
	skill_stick.global_position = skill_stick_position
	movement_area.modulate.a = 0.2
	movement_stick.modulate.a = 0.2
	skill_area.modulate.a = 0.2
	skill_stick.modulate.a = 0.2


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		if event.position.x > half_screen:
			moving = true
			movement_area.modulate.a = 1
			movement_stick.modulate.a = 1
			movement_center = event.position
			movement_area.position = movement_center - Vector2(movement_radius, movement_radius)
			movement_stick.position = event.position
		else:
			using = true
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
				emit_signal("skill_signal", true)


	elif event is InputEventScreenDrag:
		if moving:
			movement_stick.position = event.position
			if event.position.distance_to(movement_center) > movement_radius:
				var temp: Vector2 = event.position - movement_center
				temp *= movement_radius / event.position.distance_to(movement_center)
				movement_stick.position = temp + movement_center
			emit_signal("move_signal", (event.position - movement_center).normalized(), true)

		elif using and not button:
			skill_stick.position = event.position
			if event.position.distance_to(skill_center) > skill_radius:
				var temp: Vector2 = event.position - skill_center
				temp *= skill_radius / event.position.distance_to(skill_center)
				skill_stick.position = temp + skill_center
			emit_signal("skill_signal", (event.position - skill_center).normalized(), true)


	elif event is InputEventScreenTouch and not event.is_pressed():
		if moving:
			moving = false
			movement_area.global_position = movement_area_position
			movement_stick.global_position = movement_stick_position
			movement_area.modulate.a = 0.2
			movement_stick.modulate.a = 0.2
			emit_signal("move_signal", Vector2.ZERO, false)
		else:
			using = false
			skill_area.global_position = skill_area_position
			skill_stick.global_position = skill_stick_position
			skill_area.modulate.a = 0.2
			skill_stick.modulate.a = 0.2
			if button:
				emit_signal("skill_signal", false)
			else:
				emit_signal("skill_signal", Vector2.ZERO, false)

