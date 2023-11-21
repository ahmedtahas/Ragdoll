extends Node2D


@onready var character_name: String = "kaliber"

@onready var max_combo: float
@onready var duration_time: float
@onready var damage: float

@onready var cooldown_text: Label = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center

@onready var character: Node2D = $Character
@onready var skill_joy_stick: Control = $Extra/UI/SkillJoyStick
@onready var duration: Timer = $Extra/SkillDuration
@onready var health: CanvasLayer = $Extra/Health

@onready var body: RigidBody2D = $Character/Body

@onready var using: bool = false
@onready var hit_count: float = 0


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
		character.hit_signal.connect(hit_signal)
		Global.player = self
		skill_joy_stick.skill_signal.connect(skill_signal)
		skill_joy_stick.button = true
		duration_time = Config.get_value("cooldown", character_name)
		max_combo = Config.get_value("duration", character_name)
		damage = Config.get_value("damage", character_name)
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

	else:
		cooldown_bar.set_value((100 * hit_count) / max_combo)
		cooldown_text.set_text(str(hit_count) + "x")


func hit_signal(_body: RigidBody2D, _caller: RigidBody2D) -> void:
	if using or hit_count == max_combo:
		return
	hit_count += 1


func skill_signal(_using: bool) -> void:
	if not is_multiplayer_authority() or not duration.is_stopped():
		return

	if _using:
		character.slow_motion.rpc()
		character.damage *= (hit_count / 2)
		duration.wait_time = duration_time * hit_count / max_combo
		duration.start()
		await duration.timeout
		character.damage = damage
		hit_count = 0
