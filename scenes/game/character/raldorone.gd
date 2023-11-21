extends Node2D


@onready var character_name: String = "raldorone"

@onready var cooldown_set: bool = false

@onready var duration_time: float
@onready var cooldown_time: float

@onready var cooldown_text: Label = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center

@onready var character: Node2D = $Character
@onready var skill_joy_stick: Control = $Extra/UI/SkillJoyStick
@onready var body: RigidBody2D = $Character/Body
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/SkillDuration
@onready var health: CanvasLayer = $Extra/Health
@onready var right_shield: Sprite2D = $Character/RF/Sprite
@onready var left_shield: Sprite2D = $Character/LF/Sprite
@onready var right_arm: RigidBody2D = $Character/RF
@onready var left_arm: RigidBody2D = $Character/LF


func _ready() -> void:
	if get_parent().name == "Display":
		get_node("Extra/UI").hide()
		get_node("Extra/Health").hide()
		character.setup(character_name)
		return
	name = str(get_multiplayer_authority())
	character.setup(character_name)
	Global.camera.add_target(center)
	health.set_health(Config.get_value("health", character_name))

	if is_multiplayer_authority():
		Global.player = self
		skill_joy_stick.skill_signal.connect(skill_signal)
		skill_joy_stick.button = true
		duration_time = Config.get_value("duration", character_name)
		cooldown_time = Config.get_value("cooldown", character_name)
		cooldown.wait_time = cooldown_time
		duration.wait_time = duration_time
		cooldown_bar.set_value(100)
		cooldown_text.set_text("Ready")

	else:
		get_node("Extra/UI").hide()
		Global.opponent = self


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not duration.is_stopped():
		cooldown_bar.set_value((100 * duration.time_left) / duration_time)
		cooldown_text.set_text(str(duration.time_left).pad_decimals(1) + "s")

	elif cooldown.is_stopped():
		if not cooldown_set:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("Ready")
			cooldown_set = true

	elif duration.is_stopped():
		if cooldown_set:
			cooldown_set = false
		cooldown_bar.set_value(100 - ((100 * cooldown.time_left) / cooldown_time))
		cooldown_text.set_text(str(cooldown.time_left).pad_decimals(1) + "s")


@rpc("reliable", "call_local")
func scale_shield(_scale: float) -> void:
	right_shield.scale.x = _scale
	right_shield.scale.y = _scale
	left_shield.scale.x = _scale
	left_shield.scale.y = _scale
	for part in right_arm.get_children():
		if part is CollisionPolygon2D:
			part.queue_free()
	for part in left_arm.get_children():
		if part is CollisionPolygon2D:
			part.queue_free()
	right_shield.weapon_collision(character_name)
	left_shield.weapon_collision(character_name)


func skill_signal(using: bool) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority() or not duration.is_stopped():
		return

	if using:
		duration.start()
		scale_shield.rpc(1.5)
		await duration.timeout
		scale_shield.rpc(1)
		cooldown.start()
