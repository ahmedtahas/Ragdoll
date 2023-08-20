extends Node2D

@onready var character_name = "buccarold"

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float
@onready var damage: float

@onready var character: Node2D = $Extra/Character
@onready var skill_joy_stick: Control = $Extra/JoyStick/SkillJoyStick
@onready var movement_joy_stick: Control = $Extra/JoyStick/MovementJoyStick

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var duration: Timer = $Extra/SkillDuration

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var cooldown_set: bool = false

@onready var flames = $LocalCharacter/RF/Flames

func _ready() -> void:
	character.ignore_self()
	name = character_name
	get_node("LocalCharacter").load_skin(character_name)

	movement_joy_stick.move_signal.connect(character.move_signal)
	skill_joy_stick.skill_signal.connect(self.skill_signal)

	skill_joy_stick.button = true
	cooldown_time = get_node("/root/Config").get_value("cooldown", character_name)
	power = get_node("/root/Config").get_value("power", character_name)
	damage = get_node("/root/Config").get_value("damage", character_name)
	duration_time = get_node("/root/Config").get_value("duration", character_name)

	cooldown.wait_time = cooldown_time
	duration.wait_time = duration_time

	cooldown_bar = character.get_node('LocalUI/CooldownBar')
	cooldown_text = character.get_node('LocalUI/CooldownBar/Text')

	cooldown_bar.set_value(100)
	cooldown_text.set_text("[center]ready[/center]")

	for part in get_node("LocalCharacter").get_children():
		part.set_power(character_name)



func _physics_process(_delta: float) -> void:
	if not duration.is_stopped():
		cooldown_bar.set_value((100 * duration.time_left) / duration_time)
		cooldown_text.set_text("[center]" + str(duration.time_left).pad_decimals(1) + "s[/center]")

	elif cooldown.is_stopped():
		if not cooldown_set:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("[center]ready[/center]")
			cooldown_set = true

	elif duration.is_stopped():
		if cooldown_set:
			cooldown_set = false
		cooldown_bar.set_value(100 - ((100 * cooldown.time_left) / cooldown_time))
		cooldown_text.set_text("[center]" + str(cooldown.time_left).pad_decimals(1) + "s[/center]")


func skill_signal(using: bool) -> void:
	if not cooldown.is_stopped() or not duration.is_stopped():
		return
	if using:
		pass

	else:
		character.damage *= 2
		duration.start()
		flames.emitting = true
		await duration.timeout
		flames.emitting = false
		cooldown.start()
		character.damage /= 2


