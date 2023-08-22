extends Node2D


@onready var character_name: String = "tin"

@onready var cooldown_set: bool = false
@onready var charging: bool = false
@onready var shocking: bool = false

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float
@onready var damage: float

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var skill_joy_stick: Control = $Extra/JoyStick/SkillJoyStick
@onready var movement_joy_stick: Control = $Extra/JoyStick/MovementJoyStick
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var remote_body: CharacterBody2D = $RemoteCharacter/Body
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/ChargeUp
@onready var shockwave: Sprite2D = $Extra/Shockwave
@onready var gravity: GPUParticles2D = $Extra/Gravity


func _ready() -> void:
	name = str(get_multiplayer_authority())
	get_node("LocalCharacter").load_skin(character_name)
	shockwave.visible = false
	if is_multiplayer_authority():
		get_node("RemoteCharacter").queue_free()
		movement_joy_stick.move_signal.connect(character.move_signal)
		skill_joy_stick.skill_signal.connect(self.skill_signal)

		skill_joy_stick.button = true
		duration_time = get_node("/root/Config").get_value("duration", character_name)
		cooldown_time = get_node("/root/Config").get_value("cooldown", character_name)
		power = get_node("/root/Config").get_value("power", character_name)
		damage = get_node("/root/Config").get_value("damage", character_name)

		cooldown.wait_time = cooldown_time
		duration.wait_time = duration_time

		cooldown_bar = character.get_node('LocalUI/CooldownBar')
		cooldown_text = character.get_node('LocalUI/CooldownBar/Text')
		cooldown_bar.set_value(100)
		cooldown_text.set_text("[center]ready[/center]")
		character.get_node("RemoteUI").visible = false
		Global.camera.add_target(body)
		for part in get_node("LocalCharacter").get_children():
			part.set_power(character_name)
		character.ignore_local()

	else:
		get_node("LocalCharacter").queue_free()
		character.get_node("LocalUI").visible = false
		Global.camera.add_target(get_node("RemoteCharacter/Body"))
		character.ignore_remote()


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		gravity.global_position = body.global_position
		shockwave.global_position = body.global_position
	else:
		gravity.global_position = remote_body.global_position
		shockwave.global_position = remote_body.global_position

	if shocking and shockwave.scale.x <= 30:
		_scale_shockwave(+0.25)

	elif not shocking and shockwave.scale.x > 0.25 and shockwave.visible:
		_scale_shockwave(-2)

	elif shockwave.scale.x <= 0.25:
		shockwave.visible = false
		shockwave.scale.x = 0.1
		shockwave.scale.y = 0.1

	if not is_multiplayer_authority():
		return

	if charging:

		if shockwave.scale.x <= 30.2  and shockwave.scale.x >= 29.8:
			gravity.emitting = true

		if not duration.is_stopped():
			cooldown_bar.set_value((100 * duration.time_left) / duration_time)
			cooldown_text.set_text("[center]charge[/center]")

		elif duration.is_stopped():
			cooldown_bar.set_value(0)
			cooldown_text.set_text("[center]charged[/center]")

	elif cooldown.is_stopped():
		if cooldown_set:
			pass
		else:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("[center]ready[/center]")
			cooldown_set = true

	elif duration.is_stopped():
		if cooldown_set:
			cooldown_set = false
		cooldown_bar.set_value(100 - ((100 * cooldown.time_left) / cooldown_time))
		cooldown_text.set_text("[center]" + str(cooldown.time_left).pad_decimals(1) + "s[/center]")


func _scale_shockwave(value: float) -> void:
	shockwave.scale.x += value
	shockwave.scale.y += value


func skill_signal(is_charging: bool) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority():
		return

	if is_charging:
		shockwave.visible = true
		charging = true
		shocking = true
		body.freeze = true
		duration.start()

	else:
		gravity.emitting = false
		body.freeze = false
		shocking = false
		charging = false
		var multiplier = duration_time - duration.time_left
		var skill_range = shockwave.scale.x * 250
		duration.stop()
		cooldown.start()

		var opponent_pos = get_node("../" + str(Global.world.get_opponent_id()) + "/RemoteCharacter/Body").global_position

		if (opponent_pos - body.global_position).length() < skill_range:
			character.push_opponent((body.global_position - opponent_pos).normalized(), power)
			character.damage_opponent(multiplier * damage)
