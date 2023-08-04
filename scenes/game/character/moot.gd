extends Node2D

@onready var character_name: String = "moot"

@onready var meteor_instance: PackedScene = preload("res://scenes/game/tools/meteor.tscn")

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float
@onready var damage: float
@onready var meteor: CharacterBody2D

@onready var fire_place: Node2D = $Extra/Center/Reach
@onready var magic: Node2D = $Extra/Center

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/SkillDuration
@onready var fire_ring_1: Sprite2D = $Extra/FireRing1
@onready var fire_ring_2: Sprite2D = $Extra/FireRing2


@onready var cooldown_set: bool = false
@onready var is_hit: bool = false

func _ready() -> void:
	name = str(get_multiplayer_authority())
	get_node("LocalCharacter").load_skin(character_name)

	if is_multiplayer_authority():
		joy_stick.move_signal.connect(character.move_signal)
		joy_stick.skill_signal.connect(self.skill_signal)

		joy_stick.button = true
		duration_time = get_node("/root/Config").get_value("duration", character_name)
		cooldown_time = get_node("/root/Config").get_value("cooldown", character_name)
		damage = get_node("/root/Config").get_value("damage", character_name)
		power = get_node("/root/Config").get_value("power", character_name)

		cooldown.wait_time = cooldown_time
		duration.wait_time = duration_time
		cooldown_bar = character.get_node('LocalUI/CooldownBar')
		cooldown_text = character.get_node('LocalUI/CooldownBar/Text')
		cooldown_bar.set_value(100)
		cooldown_text.set_text("[center]ready[/center]")
		character.get_node("RemoteUI").visible = false
		Global.camera.add_target(body)
		get_node("RemoteCharacter").queue_free()
		for part in get_node("LocalCharacter").get_children():
			part.set_power(character_name)
		character.ignore_local()

	else:
		character.get_node("LocalUI").visible = false
		Global.camera.add_target(get_node("RemoteCharacter/Body"))
		get_node("LocalCharacter").queue_free()
		character.ignore_remote()


@rpc("call_remote", "reliable")
func add_skill(skill_name: String) -> void:
	Global.world.add_skill(skill_name)


@rpc("call_remote", "reliable")
func remove_skill() -> void:
	Global.world.remove_skill()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not duration.is_stopped():
		fire_ring_1.global_position = body.global_position + center.rotated(body.global_rotation)
		fire_ring_2.global_position = body.global_position + center.rotated(body.global_rotation)
		fire_ring_1.global_rotation += 0.5
		fire_ring_2.global_rotation -= 0.5

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


func skill_signal(using: bool) -> void:
	if not is_multiplayer_authority() or not cooldown.is_stopped() or not duration.is_stopped():
		return

	if using:
		pass

	else:
		fire_ring_1.visible = true
		fire_ring_2.visible = true
		duration.start()
		magic.global_position = body.global_position + center.rotated(body.global_rotation)
		character.slow_motion()
		await get_tree().create_timer(0.05).timeout
		fire_ring_1.visible = false
		fire_ring_2.visible = false
		meteor = meteor_instance.instantiate()
		if multiplayer.is_server():
			Global.server_skill.add_child(meteor, true)
		else:
			Global.client_skill.add_child(meteor, true)
			rpc_id(Global.world.get_opponent_id(), "add_skill", "meteor")
		meteor.set_multiplayer_authority(multiplayer.get_unique_id())
		magic.look_at(Global.spawner.get_node(str(Global.world.get_opponent_id()) + "/RemoteCharacter/Body").global_position)
		meteor.global_position = fire_place.global_position
		meteor.hit_signal.connect(self.hit_signal)
		await duration.timeout
		if not is_hit:
			meteor.duration = false
			if not multiplayer.is_server():
				rpc_id(Global.world.get_opponent_id(), "remove_skill")
			cooldown.start()
		else:
			is_hit = false

func hit_signal(hit: Node2D) -> void:
	is_hit = true
	if (hit is RigidBody2D or hit is CharacterBody2D) and not hit.is_in_group("Skill"):
		if hit.get_node("../..") != self:
			character.push_opponent_part((hit.global_position - meteor.global_position).normalized(), power, hit.name)
			character.push_opponent((hit.global_position - meteor.global_position).normalized(), power / 2)
			character.stun_opponent()
			if hit.name == "Head":
				character.damage_opponent(damage * 3)
			else:
				character.damage_opponent(damage * 1.5)
		else:
			character.take_damage(damage)
	meteor.queue_free()
	duration.stop()
	cooldown.start()
	if not multiplayer.is_server():
		rpc_id(Global.world.get_opponent_id(), "remove_skill")
