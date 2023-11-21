extends Node2D

@onready var character_name = "holstar"

@onready var bullet: PackedScene = preload("res://scenes/game/tools/bullet.tscn")

@onready var cooldown_time: float
@onready var power: float
@onready var damage: float

@onready var character: Node2D = $Character
@onready var skill_joy_stick: Control = $Extra/UI/SkillJoyStick
@onready var bullet_instance: CharacterBody2D

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center

@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var rua: RigidBody2D = $Character/RUA
@onready var rla: RigidBody2D = $Character/RLA
@onready var rf: RigidBody2D = $Character/RF
@onready var body: RigidBody2D = $Character/Body
@onready var health: CanvasLayer = $Extra/Health
@onready var barrel: Marker2D = $Character/RF/Barrel
@onready var cooldown_text: Label = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar
@onready var blood: GPUParticles2D = $Extra/Blood

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
		cooldown_time = Config.get_value("cooldown", character_name)
		damage = Config.get_value("damage", character_name)
		power = Config.get_value("power", character_name)
		cooldown.wait_time = cooldown_time
		cooldown_bar.set_value(100)
		cooldown_text.set_text("Ready")

	else:
		get_node("Extra/UI").hide()
		Global.opponent = self


@rpc("reliable")
func add_skill(skill_name: String, place: String) -> void:
	Global.world.add_skill(skill_name, place, name.to_int())


@rpc("reliable")
func remove_skill(place: String) -> void:
	Global.world.remove_skill(place)


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if cooldown.is_stopped():
		if not cooldown_set:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("Ready")
			cooldown_set = true
	else:
		if cooldown_set:
			cooldown_set = false
		cooldown_bar.set_value(100 - ((100 * cooldown.time_left) / cooldown_time))
		cooldown_text.set_text(str(cooldown.time_left).pad_decimals(1) + "s")


func skill_signal(did_shot: bool) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority():
		return
	if did_shot:
		cooldown.start()
		character.slow_motion.rpc()
		bullet_instance = bullet.instantiate()
		bullet_instance.hit_signal.connect(hit_signal)
		bullet_instance.set_multiplayer_authority(multiplayer.get_unique_id())
		if Global.is_host:
			Global.server_skill.add_child(bullet_instance, true)
			add_skill.rpc("bullet", "ServerSkill")
		else:
			Global.client_skill.add_child(bullet_instance, true)
			add_skill.rpc("bullet", "ClientSkill")
		ignore_skill()
		bullet_instance.global_position = barrel.global_position
		bullet_instance.fire(rf.global_rotation)


func ignore_skill() -> void:
	for child in character.get_children():
		child.add_collision_exception_with(bullet_instance)


@rpc("reliable", "call_local")
func blood_splat(hit_position: Vector2, hit_rotation: float) -> void:
	blood.global_position = hit_position
	blood.global_rotation = hit_rotation
	blood.emitting = true


func hit_signal(hit: PhysicsBody2D) -> void:
	if hit is RigidBody2D and not hit.is_in_group("Skill") and not hit.is_in_group("Undamagable"):
		blood_splat.rpc(bullet_instance.global_position, bullet_instance.global_rotation)
		Global.pushed.emit((hit.global_position - barrel.global_position).normalized() * power * 2)
		Global.stunned.emit()
		if hit.name == "Head":
			Global.damaged.emit(damage * 4)
		else:
			Global.damaged.emit(damage * 2)
	bullet_instance.hit_signal.disconnect(hit_signal)
	bullet_instance.queue_free()
	if not Global.is_host:
		remove_skill.rpc("ClientSkill")
	else:
		remove_skill.rpc("ServerSkill")
