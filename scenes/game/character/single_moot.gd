extends Node2D

@onready var character_name = "moot"

@onready var fire_ball_instance = preload("res://scenes/game/tools/single_fire_ball.tscn")

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float
@onready var damage: float

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var fire_ball: CharacterBody2D

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var fire_place: Node2D = $Extra/Center/Reach
@onready var magic: Node2D = $Extra/Center
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var duration: Timer = $Extra/SkillDuration

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var cooldown_set: bool = false
@onready var is_hit: bool = false


func _ready() -> void:
	character.ignore_self()
	name = character_name
	get_node("LocalCharacter").load_skin(character_name)
	
	
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	
	joy_stick.button = true
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
	if not cooldown.is_stopped() and not duration.is_stopped():
		return
	if using:
		pass
	
	else:
		magic.global_position = body.global_position + center.rotated(body.global_rotation)
		Global.world.slow_motion(0.05, 1)
		await get_tree().create_timer(0.05).timeout
		fire_ball = fire_ball_instance.instantiate()
		add_sibling(fire_ball)
		magic.look_at(Global.bot.get_node("LocalCharacter/Body").global_position)
		fire_ball.global_position = fire_place.global_position
		fire_ball.hit_signal.connect(self.hit_signal)
		duration.start()
		await duration.timeout
		if not is_hit:
			fire_ball.duration = false
			cooldown.start()
		else:
			is_hit = false


func hit_signal(hit: Node2D) -> void:
	is_hit = true
	if hit is RigidBody2D:
		if hit.get_node("../..").name == "Bot":
			Global.bot.character.hit_stun()
			if hit.name == "Head":
				character.damage_bot(damage * 3)
			else:
				character.damage_bot(damage * 1.5)
		else:
			character.take_damage(damage)
	fire_ball.queue_free()
	duration.stop()
	cooldown.start()
