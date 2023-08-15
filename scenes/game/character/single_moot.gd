extends Node2D

@onready var character_name = "moot"

@onready var meteor_instance = preload("res://scenes/game/tools/single_meteor.tscn")

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float
@onready var damage: float

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var meteor: CharacterBody2D

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var fire_place: Node2D = $Extra/Center/Reach
@onready var magic: Node2D = $Extra/Center
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var local_character: Node2D = $LocalCharacter
@onready var duration: Timer = $Extra/SkillDuration
@onready var fire_ring: GPUParticles2D = $LocalCharacter/Body/FireRing

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
	print(duration.time_left, "     :::::::::::")
	if not cooldown.is_stopped() or not duration.is_stopped():
		return
	if using:
		pass

	else:
		fire_ring.emitting = true
		duration.start()
		await get_tree().create_timer(1).timeout
		magic.global_position = body.global_position + center.rotated(body.global_rotation)
		fire_ring.emitting = false
		meteor = meteor_instance.instantiate()
		add_sibling(meteor)
		magic.look_at(Global.bot.get_node("LocalCharacter/Body").global_position)
		meteor.global_position = fire_place.global_position
		meteor.hit_signal.connect(self.hit_signal)
		await duration.timeout
		if not is_hit:
			meteor.duration = false
			cooldown.start()
		else:
			is_hit = false


func hit_signal(hit: Node2D) -> void:
	is_hit = true
	if hit is RigidBody2D:
		if hit.get_node("../..") != self:
			Global.bot.character.hit_stun()
			character.push_all((Global.bot.get_node("LocalCharacter/Body").global_position - meteor.global_position).normalized(), power)
			if hit.name == "Head":
				character.damage_bot(damage * 3)
			else:
				character.damage_bot(damage * 1.5)
		else:
			character.take_damage(damage)
	meteor.queue_free()
	duration.stop()
	cooldown.start()
