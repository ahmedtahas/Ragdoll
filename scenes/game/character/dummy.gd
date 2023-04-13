extends Node2D

@onready var joy_stick_instance = preload("res://scenes/game/modules/joy_stick.tscn")
@onready var character_instance = preload("res://scenes/game/modules/character.tscn")

@onready var duration: float = get_node("/root/Config").get_value("duration", name.replace("@", "").rstrip("0123456789").to_lower())
@onready var cooldown_time: float = get_node("/root/Config").get_value("cooldown", name.replace("@", "").rstrip("0123456789").to_lower())

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel
@onready var character: Node2D
@onready var joy_stick: CanvasLayer

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown

@onready var cooldown_set: bool = false


func _ready() -> void:
	character = character_instance.instantiate()
	joy_stick = joy_stick_instance.instantiate()
	
	get_node("Extra").add_child(character)
	get_node("Extra").add_child(joy_stick)
	
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	
	cooldown.wait_time = cooldown_time
	cooldown_bar = character.get_node("UI/CooldownBar")
	cooldown_text = character.get_node("UI/CooldownBar/Text")
	cooldown_bar.set_value(100)
	cooldown_text.set_text("[center]ready[/center]")
	
	_ignore_self()
	

func _physics_process(_delta: float) -> void:
	if cooldown.is_stopped():
		if cooldown_set:
			pass
		else:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("[center]ready[/center]")
			cooldown_set = true
	else:
		if cooldown_set:
			cooldown_set = false
		cooldown_bar.set_value(100 - ((100 * cooldown.time_left) / cooldown_time))
		cooldown_text.set_text("[center]" + str(cooldown.time_left).pad_decimals(1) + "s[/center]")
	
	
func _ignore_self() -> void:
	for child_1 in get_children():
		if child_1 is RigidBody2D:
			child_1.body_entered.connect(character.on_body_entered.bind(child_1))
			for child_2 in get_children():
				if child_1 != child_2 and child_2 is RigidBody2D:
					child_1.add_collision_exception_with(child_2)


func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped():
		return
	
	if is_aiming:
		pass
		
	else:
		pass
		
		
