extends Node2D

@onready var character_name: String = "crock"

@onready var after_image: PackedScene = preload("res://scenes/game/tools/after_image.tscn")
@onready var after_image_instance: Node2D

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


func skill_signal(_using: bool) -> void:
	if not is_multiplayer_authority() or not cooldown.is_stopped() or not duration.is_stopped():
		return

	if _using:
		var old_health = health.current_health
		var old_position = body.global_position

		duration.start()
		await duration.timeout
		if health.current_health == 0:
			return
		health.take_damage(((health.current_health - old_health) * 2) * 69 / 100)
		cooldown.start()
		teleport(old_position)


@rpc("reliable", "call_local")
func show_after_image() -> void:
	after_image_instance = after_image.instantiate()
	add_child(after_image_instance)
	after_image_instance.global_position = body.global_position
	Global.camera.add_target(after_image_instance)


@rpc("reliable", "call_local")
func remove_after_image() -> void:
	after_image_instance.queue_free()
	Global.camera.remove_target(after_image_instance)


func teleport(pos: Vector2) -> void:
	pos = Global.avoid_enemies(pos - body.global_position)
	show_after_image.rpc()
	for child in character.get_children():
		child.visible = false
	for child in character.get_children():
		child.locate(pos)
		child.rotate(child.global_rotation)
		child.teleport()
	await get_tree().create_timer((pos - center.global_position).length() / 50000).timeout
	for child in character.get_children():
		child.visible = true
	remove_after_image.rpc()
