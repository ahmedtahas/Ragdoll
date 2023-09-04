extends Node2D

@onready var character_name: String = "paranoc"

@onready var duration_time: float
@onready var cooldown_time: float
@onready var damage: float

@onready var cooldown_text: RichTextLabel = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center

@onready var character: Node2D = $Character
@onready var skill_joy_stick: Control = $Extra/UI/SkillJoyStick
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/SkillDuration
@onready var health: CanvasLayer = $Extra/Health

@onready var body: RigidBody2D = $Character/Body

@onready var cooldown_set: bool = false
@onready var using: bool = false


func _ready() -> void:
	name = str(get_multiplayer_authority())
	character.setup(character_name)
	character.hit_signal.connect(hit_signal)
	Global.camera.add_target(center)
	health.set_health(Config.get_value("health", character_name))

	if is_multiplayer_authority():
		Global.player = self
		skill_joy_stick.skill_signal.connect(skill_signal)
		skill_joy_stick.button = true
		duration_time = Config.get_value("duration", character_name)
		cooldown_time = Config.get_value("cooldown", character_name)
		damage = Config.get_value("damage", character_name)
		cooldown.wait_time = cooldown_time
		duration.wait_time = duration_time
		cooldown_bar.set_value(100)
		cooldown_text.set_text("[center]ready[/center]")

	else:
		get_node("Extra/UI").hide()
		Global.opponent = self


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

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
func black_out(_duration) -> void:
	Global.black_out.emit(_duration)


func hit_signal(hit: RigidBody2D, caller: RigidBody2D) -> void:
	if hit.is_in_group("Damagable") and caller.is_in_group("Damager") and using:
		health.take_damage(-(damage / 2))


func skill_signal(_using: bool) -> void:
	if not is_multiplayer_authority() or not cooldown.is_stopped() or not duration.is_stopped():
		return

	if _using:
		using = true
		character.damage /= 2
		duration.start()
		black_out.rpc(duration_time)
		if Global.mode == "single":
			Global.opponent.get_paralyzed(duration_time)
		await duration.timeout
		using = false
		character.damage *= 2
		cooldown.start()
