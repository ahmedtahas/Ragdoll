extends Node2D


@onready var character_name: String = "tin"

@onready var cooldown_set: bool = false
@onready var charging: bool = false
@onready var shocking: bool = false

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float
@onready var damage: float

@onready var multiplier: float
@onready var skill_range: float

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center

@onready var character: Node2D = $Character
@onready var cooldown_text: Label = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar
@onready var skill_joy_stick: Control = $Extra/UI/SkillJoyStick
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/ChargeUp
@onready var body: RigidBody2D = $Character/Body
@onready var health: CanvasLayer = $Extra/Health
@onready var shockwave: Sprite2D = $Character/Body/Shockwave
@onready var gravity: GPUParticles2D = $Character/Body/Gravity


func _ready() -> void:
	if get_parent().name == "Display":
		get_node("Extra/UI").hide()
		get_node("Extra/Health").hide()
		character.setup(character_name)
		return
	name = str(get_multiplayer_authority())
	character.setup(character_name)
	shockwave.visible = false
	Global.camera.add_target(center)
	health.set_health(Config.get_value("health", character_name))
	if is_multiplayer_authority():
		Global.player = self
		skill_joy_stick.skill_signal.connect(skill_signal)
		skill_joy_stick.button = true
		duration_time = Config.get_value("duration", character_name)
		cooldown_time = Config.get_value("cooldown", character_name)
		damage = Config.get_value("damage", character_name)
		power = Config.get_value("power", character_name)
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

	if shocking and shockwave.scale.x <= 30:
		scale_shockwave.rpc(+0.25)

	elif not shocking and shockwave.scale.x > 0.25 and shockwave.visible:
		scale_shockwave.rpc(-2)

	elif shockwave.scale.x <= 0.25:
		show_shockwave.rpc(false)

	if charging:

		if shockwave.scale.x <= 30.2  and shockwave.scale.x >= 29.8:
			gravity_particles.rpc(true)

		if not duration.is_stopped():
			cooldown_bar.set_value((100 * duration.time_left) / duration_time)
			cooldown_text.set_text("charge")

		elif duration.is_stopped():
			cooldown_bar.set_value(0)
			cooldown_text.set_text("charged")

	elif cooldown.is_stopped():
		if cooldown_set:
			pass
		else:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("Ready")
			cooldown_set = true

	elif duration.is_stopped():
		if cooldown_set:
			cooldown_set = false
		cooldown_bar.set_value(100 - ((100 * cooldown.time_left) / cooldown_time))
		cooldown_text.set_text(str(cooldown.time_left).pad_decimals(1) + "s")


@rpc("reliable", "call_local")
func scale_shockwave(value: float) -> void:
	shockwave.scale.x += value
	shockwave.scale.y += value


@rpc("reliable", "call_local")
func gravity_particles(emitting: bool) -> void:
	gravity.emitting = emitting


@rpc("reliable", "call_local")
func show_shockwave(_show: bool) -> void:
	shockwave.visible = _show
	if not _show:
		shockwave.scale.x = 0.1
		shockwave.scale.y = 0.1


func skill_signal(is_charging: bool) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority():
		return

	if is_charging:
		show_shockwave.rpc(true)
		charging = true
		shocking = true
		body.freeze = true
		duration.start()

	else:
		gravity_particles.rpc(false)
		body.freeze = false
		shocking = false
		charging = false
		multiplier = duration_time - duration.time_left
		skill_range = shockwave.scale.x * 250
		duration.stop()
		cooldown.start()
		if (body.global_position - Global.opponent.center.global_position).length() < skill_range:
			Global.pushed.emit((body.global_position - Global.opponent.center.global_position).normalized() * power * multiplier / 2)
			Global.damaged.emit(multiplier * damage)
