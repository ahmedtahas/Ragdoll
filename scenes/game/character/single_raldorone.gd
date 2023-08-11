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
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/SkillDuration
@onready var shield: Sprite2D = $LocalCharacter/RF/Sprite
@onready var arm: RigidBody2D = $LocalCharacter/RF


func _ready() -> void:
	name = character_name
	get_node("LocalCharacter").load_skin(character_name)
	character.ignore_self()
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	joy_stick.button = true

	cooldown_time = get_node("/root/Config").get_value("cooldown", character_name)
	duration_time = get_node("/root/Config").get_value("duration", character_name)

	cooldown.wait_time = cooldown_time
	duration.wait_time = duration_time

	cooldown_bar = character.get_node('LocalUI/CooldownBar')
	cooldown_text = character.get_node('LocalUI/CooldownBar/Text')

	cooldown_bar.set_value(100)
	cooldown_text.set_text("[center]ready[/center]")

	for part in get_node("LocalCharacter").get_children():
		part.set_power(character_name)


@rpc("call_remote", "reliable")
func add_skill(skill_name: String) -> void:
	Global.world.add_skill(skill_name)


@rpc("call_remote", "reliable")
func remove_skill() -> void:
	Global.world.remove_skill()


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
	if not cooldown.is_stopped():
		return

	if using:
		pass

	else:
		duration.start()
		shield.scale.x = 1.5
		shield.scale.y = 1.5
		for part in arm.get_children():
			if part is CollisionPolygon2D:
				part.queue_free()
		shield.weapon_collision(character_name)
		await duration.timeout
		shield.scale.x = 1
		shield.scale.y = 1
		for part in arm.get_children():
			if part is CollisionPolygon2D:
				part.queue_free()
		shield.weapon_collision(character_name)
		cooldown.start()
