extends CanvasLayer

@onready var half_screen: float = get_viewport().size.x / 2
@onready var movement_area: TouchScreenButton = $MovementStick
@onready var movement_stick: Sprite2D = $LeftStick
@onready var action_area: TouchScreenButton = $ActionStick
@onready var action_stick: Sprite2D = $RigthStick

var movement_center: Vector2
var action_center: Vector2
var movement_radius: float
var action_radius: float

signal move_signal
signal skill_signal

func _ready() -> void:
	movement_radius = movement_area.texture_normal.get_size().x / 2
	action_radius = action_area.texture_normal.get_size().x / 2
	movement_area.visible = false
	movement_stick.visible = false
	action_area.visible = false
	action_stick.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		if event.position.x > half_screen:
			movement_area.visible = true
			movement_center = event.position
			movement_area.position = movement_center - Vector2(movement_radius, movement_radius)
			movement_stick.visible = true
			movement_stick.position = event.position
		else:
			action_area.visible = true
			action_center = event.position
			action_area.position = action_center - Vector2(action_radius, action_radius)
			action_stick.visible = true
			action_stick.position = event.position
			
	elif event is InputEventScreenDrag:
		if movement_area.is_visible_in_tree():
			movement_stick.position = event.position
			if event.position.distance_to(movement_center) > movement_radius:
				var temp: Vector2 = event.position - movement_center
				temp *= movement_radius / event.position.distance_to(movement_center)
				movement_stick.position = temp + movement_center
			emit_signal("move_signal", (event.position - movement_center).normalized())
			
		elif action_area.is_visible_in_tree():
			action_stick.position = event.position
			if event.position.distance_to(action_center) > action_radius:
				var temp: Vector2 = event.position - action_center
				temp *= action_radius / event.position.distance_to(action_center)
				action_stick.position = temp + action_center
			emit_signal("skill_signal", (event.position - action_center).normalized(), true)
			
	elif event is InputEventScreenTouch and not event.is_pressed():
		if movement_area.is_visible_in_tree():
			movement_area.visible = false
			movement_stick.visible = false
			emit_signal("move_signal", Vector2.ZERO)
			
		elif action_area.is_visible_in_tree():
			action_area.visible = false
			action_stick.visible = false
			emit_signal("skill_signal", Vector2.ZERO, false)
	
