extends Node2D

@onready var character_name: String = "moot"

@onready var meteor: PackedScene = preload("res://scenes/game/tools/meteor.tscn")

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float
@onready var damage: float
@onready var meteor_instance: CharacterBody2D

@onready var fire_ring: GPUParticles2D = $Character/Hip/Center/FireRing
@onready var explosion: GPUParticles2D = $Extra/Explosion

@onready var cooldown_set: bool = false
@onready var is_hit: bool = false

@onready var cooldown_text: Label = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center

@onready var character: Node2D = $Character
@onready var skill_joy_stick: Control = $Extra/UI/SkillJoyStick
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/SkillDuration
@onready var health: CanvasLayer = $Extra/Health

@onready var body: RigidBody2D = $Character/Body


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
		damage = Config.get_value("damage", character_name)
		power = Config.get_value("power", character_name)
		cooldown.wait_time = cooldown_time
		duration.wait_time = duration_time
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
func emit_particles(emit: bool) -> void:
	fire_ring.emitting = emit


func skill_signal(using: bool) -> void:
	if not is_multiplayer_authority() or not cooldown.is_stopped() or not duration.is_stopped():
		return

	if using:
		is_hit = false
		emit_particles.rpc(true)
		duration.start()
		await get_tree().create_timer(0.5).timeout
		center.look_at(Global.opponent.center.global_position)
		emit_particles.rpc(false)
		meteor_instance = meteor.instantiate()
		meteor_instance.set_multiplayer_authority(multiplayer.get_unique_id())
		if Global.is_host:
			Global.server_skill.add_child(meteor_instance, true)
			add_skill.rpc("meteor", "ServerSkill")
		else:
			Global.client_skill.add_child(meteor_instance, true)
			add_skill.rpc("meteor", "ClientSkill")
		meteor_instance.global_position = global_position
		meteor_instance.hit_signal.connect(hit_signal)
		meteor_instance.follow = true
		await duration.timeout
		if not is_hit:
			meteor_instance.follow = false
			cooldown.start()


@rpc("reliable", "call_local")
func explode(contact_point: Vector2) -> void:
	explosion.global_position = contact_point
	explosion.emitting = true


func hit_signal(hit: PhysicsBody2D) -> void:
	is_hit = true
	explode.rpc(meteor_instance.global_position)
	if hit is RigidBody2D and not hit.is_in_group("Skill") and not hit.is_in_group("Undamagable"):
		if hit.get_node("../..") != self:
			Global.pushed.emit((Global.opponent.center.global_position - meteor_instance.global_position).normalized() * power * 3)
			Global.stunned.emit()
			if hit.name == "Head":
				Global.damaged.emit(damage * 3)
			else:
				Global.damaged.emit(damage * 1.5)
		else:
			health.take_damage(damage)
			character.push_local((center.global_position - meteor_instance.global_position).normalized() * power * 3)
	meteor_instance.hit_signal.disconnect(hit_signal)
	meteor_instance.queue_free()
	duration.stop()
	cooldown.start()
	if not Global.is_host:
		remove_skill.rpc("ClientSkill")
	else:
		remove_skill.rpc("ServerSkill")
