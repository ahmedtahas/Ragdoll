extends Node2D

@onready var character_name: String = "moot"

@onready var meteor: PackedScene = preload("res://scenes/game/tools/meteor.tscn")

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float
@onready var damage: float
@onready var meteor_instance: CharacterBody2D

@onready var fire_ring: GPUParticles2D = $Character/Hip/Center/FireRing

@onready var cooldown_set: bool = false
@onready var is_hit: bool = false

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


func _ready() -> void:
	name = str(get_multiplayer_authority())
	character.setup(character_name)
	Global.camera.add_target(center)
	health.set_health(Config.get_value("health", character_name))

	if is_multiplayer_authority():
		Global.player = self
		skill_joy_stick.skill_signal.connect(self.skill_signal)
		skill_joy_stick.button = true
		duration_time = Config.get_value("duration", character_name)
		cooldown_time = Config.get_value("cooldown", character_name)
		damage = Config.get_value("damage", character_name)
		power = Config.get_value("power", character_name)
		cooldown.wait_time = cooldown_time
		duration.wait_time = duration_time
		cooldown_bar.set_value(100)
		cooldown_text.set_text("[center]ready[/center]")

	else:
		get_node("Extra/UI").hide()
		Global.opponent = self


@rpc("reliable")
func add_skill(skill_name: String, pos: Vector2) -> void:
	Global.world.add_skill(skill_name, pos)


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
func emit_particles(emit) -> void:
	fire_ring.emitting = emit


func skill_signal(using: bool) -> void:
	if not is_multiplayer_authority() or not cooldown.is_stopped() or not duration.is_stopped():
		return

	if using:
		pass

	else:
		fire_ring.emitting = true
		emit_particles.rpc(true)
		duration.start()
		await get_tree().create_timer(0.5).timeout
		center.look_at(Global.opponent.center.global_position)
		fire_ring.emitting = false
		emit_particles.rpc(false)
		meteor_instance = meteor.instantiate()
		if multiplayer.is_server():
			Global.server_skill.add_child(meteor_instance, true)
		else:
			meteor_instance.set_multiplayer_authority(multiplayer.get_unique_id())
			Global.client_skill.add_child(meteor_instance, true)
			add_skill.rpc("meteor", radius.global_position)
		meteor_instance.global_position = radius.global_position
		meteor_instance.hit_signal.connect(self.hit_signal)
		await duration.timeout
		if not is_hit:
			meteor_instance.duration = false
			cooldown.start()
		else:
			is_hit = false


func hit_signal(hit: Node2D) -> void:
	is_hit = true
	if hit is RigidBody2D and not hit.is_in_group("Skill") and not hit.is_in_group("Undamagable"):
		if hit.get_node("../..") != self:
			Global.pushed.emit((hit.global_position - meteor_instance.global_position).normalized() * power * 3)
			Global.stunned.emit()
			if Global.mode == "multi":
				if hit.name == "Head":
					Global.damaged.emit(damage * 3)
				else:
					Global.damaged.emit(damage * 1.5)
			else:
				if hit.name == "Head":
					health.damage_bot(damage * 3)
				else:
					health.damage_bot(damage * 1.5)
		else:
			health.take_damage(damage)
	meteor_instance.queue_free()
	duration.stop()
	cooldown.start()
	if not multiplayer.is_server():
		remove_skill.rpc()
