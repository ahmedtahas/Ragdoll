extends Node2D


@onready var character_name: String = "meri"

@onready var clone_instance: PackedScene = preload("res://scenes/game/character/clone.tscn")

@onready var clone: Node2D
@onready var duration_time: float
@onready var cooldown_time: float

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
@onready var cloned: bool = false

signal move_signal


func _ready() -> void:
	name = str(get_multiplayer_authority())
	character.setup(character_name)
	Global.camera.add_target(center)
	health.set_health(Config.get_value("health", character_name))

	if is_multiplayer_authority():
		Global.player = self
		skill_joy_stick.skill_signal.connect(self.skill_signal)
		skill_joy_stick.button = false
		duration_time = Config.get_value("duration", character_name)
		cooldown_time = Config.get_value("cooldown", character_name)
		cooldown.wait_time = cooldown_time
		duration.wait_time = duration_time
		cooldown_bar.set_value(100)
		cooldown_text.set_text("[center]ready[/center]")

	else:
		get_node("Extra/UI").hide()
		Global.opponent = self


@rpc("reliable")
func add_skill(skill_name: String) -> void:
	Global.world.add_skill(skill_name)


@rpc("reliable")
func remove_skill() -> void:
	Global.world.remove_skill()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not duration.is_stopped():
		cooldown_bar.set_value((100 * duration.time_left) / duration_time)
		cooldown_text.set_text("[center]" + str(duration.time_left).pad_decimals(1) + "s[/center]")

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


func skill_signal(vector: Vector2, using: bool) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority():
		return

	move_signal.emit(vector)

	if using:
		if not cloned:
			duration.start()
			cloned = true
			clone = clone_instance.instantiate()
			if multiplayer.is_server():
				Global.server_skill.add_child(clone, true)
			else:
				clone.set_multiplayer_authority(multiplayer.get_unique_id())
				Global.client_skill.add_child(clone, true)
				add_skill.rpc("clone")
		else:
			await duration.timeout
			clone.queue_free()
			if not multiplayer.is_server():
				remove_skill.rpc()
			cooldown.start()
			cloned = false


