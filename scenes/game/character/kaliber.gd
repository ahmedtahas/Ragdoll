extends Node2D


@onready var character_name: String = "kaliber"

@onready var max_combo: float
@onready var duration_time: float
@onready var damage: float

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var skill_joy_stick: Control = $Extra/JoyStick/SkillJoyStick
@onready var movement_joy_stick: Control = $Extra/JoyStick/MovementJoyStick
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var duration: Timer = $Extra/SkillDuration

@onready var using: bool = false
@onready var hit_count: float = 0


func _ready() -> void:
	name = str(get_multiplayer_authority())
	get_node("LocalCharacter").load_skin(character_name)

	if is_multiplayer_authority():
		get_node("RemoteCharacter").queue_free()
		movement_joy_stick.move_signal.connect(character.move_signal)
		skill_joy_stick.skill_signal.connect(self.skill_signal)

		character.hit_signal.connect(self.hit_signal)

		skill_joy_stick.button = true
		max_combo = get_node("/root/Config").get_value("duration", character_name)
		duration_time = get_node("/root/Config").get_value("cooldown", character_name)
		damage = get_node("/root/Config").get_value("damage", character_name)
		duration.wait_time = duration_time
		cooldown_bar = character.get_node('LocalUI/CooldownBar')
		cooldown_text = character.get_node('LocalUI/CooldownBar/Text')
		cooldown_bar.set_value(0)
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
		return

	if not duration.is_stopped():
		cooldown_bar.set_value((100 * duration.time_left) / duration_time)
		cooldown_text.set_text("[center]" + str(duration.time_left).pad_decimals(1) + "s[/center]")

	else:
		cooldown_bar.set_value((100 * hit_count) / max_combo)
		cooldown_text.set_text("[center]" + str(hit_count) + "x[/center]")


func hit_signal(_body: CharacterBody2D, _caller: RigidBody2D) -> void:
	if using or hit_count == max_combo:
		return
	hit_count += 1


func skill_signal(_using: bool) -> void:
	if not is_multiplayer_authority() or not duration.is_stopped():
		return

	if _using:
		pass

	else:
		character.slow_motion()
		character.damage *= (hit_count / 2)
		duration.wait_time = duration_time * hit_count / max_combo
		duration.start()
		await duration.timeout
		character.damage = damage
		hit_count = 0
