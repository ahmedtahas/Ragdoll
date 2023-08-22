extends Node2D


@onready var character_name: String = "raldorone"

@onready var cooldown_set: bool = false
@onready var charging: bool = false
@onready var shocking: bool = false

@onready var duration_time: float
@onready var cooldown_time: float

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
@onready var duration: Timer = $Extra/SkillDuration
@onready var shield: Sprite2D = $LocalCharacter/RF/Sprite
@onready var remote_shield: Sprite2D = $RemoteCharacter/RF/Sprite
@onready var syncronizer: Node2D = $Extra
@onready var arm: RigidBody2D = $LocalCharacter/RF
@onready var remote_arm: CharacterBody2D = $RemoteCharacter/RF


func _ready() -> void:
	name = str(get_multiplayer_authority())
	get_node("LocalCharacter").load_skin(character_name)
	if is_multiplayer_authority():
		get_node("RemoteCharacter").queue_free()
		movement_joy_stick.move_signal.connect(character.move_signal)
		skill_joy_stick.skill_signal.connect(self.skill_signal)

		skill_joy_stick.button = true
		duration_time = get_node("/root/Config").get_value("duration", character_name)
		cooldown_time = get_node("/root/Config").get_value("cooldown", character_name)

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

	if not is_multiplayer_authority():
		remote_shield.scale.x = syncronizer.shield_scale
		remote_shield.scale.y = syncronizer.shield_scale
		return

	syncronizer.shield_scale = shield.scale.x
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


@rpc("reliable")
func scale_shield(_scale: float) -> void:
	remote_shield.scale.x = _scale
	remote_shield.scale.y = _scale
	for part in remote_arm.get_children():
		if part is CollisionPolygon2D:
			part.queue_free()
	remote_shield.weapon_collision(character_name)


func skill_signal(using: bool) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority() or not duration.is_stopped():
		return

	if using:
		pass

	else:
		duration.start()
		shield.scale.x = 2
		shield.scale.y = 2
		for part in arm.get_children():
			if part is CollisionPolygon2D:
				part.queue_free()
		shield.weapon_collision(character_name)
		rpc("scale_shield", 2)
		await duration.timeout
		shield.scale.x = 1
		shield.scale.y = 1
		for part in arm.get_children():
			if part is CollisionPolygon2D:
				part.queue_free()
		shield.weapon_collision(character_name)
		rpc("scale_shield", 1)
		cooldown.start()
