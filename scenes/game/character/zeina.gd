extends Node2D

@onready var character_name: String = "zeina"

@onready var dagger_instance: PackedScene = preload("res://scenes/game/tools/dagger.tscn")

@onready var cooldown_time: float
@onready var power: float
@onready var damage: float
@onready var end_point: Vector2

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel
@onready var dagger: CharacterBody2D

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $"Extra/DoubleJoyStick"
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var dash_preview: Marker2D = $Extra/Center
@onready var _range: Marker2D = $Extra/Center/Range
@onready var local_character: Node2D = $LocalCharacter

@onready var flicker: bool = false
@onready var cooldown_set: bool = false
@onready var _hit: bool = false

func _ready() -> void:
	name = str(get_multiplayer_authority())

	get_node("LocalCharacter").load_skin(character_name)

	dash_preview.visible = false

	if is_multiplayer_authority():
		get_node("RemoteCharacter").queue_free()
		joy_stick.move_signal.connect(character.move_signal)
		joy_stick.skill_signal.connect(self.skill_signal)

		joy_stick.button = false
		cooldown_time = get_node("/root/Config").get_value("cooldown", character_name)
		power = get_node("/root/Config").get_value("power", character_name)
		damage = get_node("/root/Config").get_value("damage", character_name)
		cooldown.wait_time = cooldown_time
		cooldown_bar = character.get_node('LocalUI/CooldownBar')
		cooldown_text = character.get_node('LocalUI/CooldownBar/Text')
		cooldown_bar.set_value(100)
		cooldown_text.set_text("[center]ready[/center]")
		character.get_node("RemoteUI").visible = false
		Global.camera.add_target(body)
		for part in get_node("LocalCharacter").get_children():
			part.set_power(character_name)
		character.ignore_local()

	else:
		get_node("LocalCharacter").queue_free()
		character.get_node("LocalUI").visible = false
		Global.camera.add_target(get_node("RemoteCharacter/Body"))
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
	if flicker:
		dash_preview.global_position = body.global_position + center.rotated(body.global_rotation)

	if cooldown.is_stopped():
		if not cooldown_set:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("[center]ready[/center]")
			cooldown_set = true
	else:
		if cooldown_set:
			cooldown_set = false
		cooldown_bar.set_value(100 - ((100 * cooldown.time_left) / cooldown_time))
		cooldown_text.set_text("[center]" + str(cooldown.time_left).pad_decimals(1) + "s[/center]")


func _flicker() -> void:
	if not is_multiplayer_authority():
		return

	if flicker:
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = true
			await get_tree().create_timer(0.017).timeout
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = false
			await get_tree().create_timer(0.017).timeout
		_flicker()


func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority():
		return

	if is_aiming:
		dash_preview.visible = true
		dash_preview.global_rotation = direction.angle()
		if not flicker:
			flicker = true
			for line in dash_preview.get_node("Dash").get_children():
				line.visible = true
			_flicker()

	else:
		dash_preview.visible = false
		end_point = _range.global_position
		# check if hits character update endpoint
		end_point = Global.get_inside_position(end_point, str(multiplayer.get_unique_id()))

		cooldown.start()
		flicker = false
#		for line in dash_preview.get_node("Dash").get_children():
#			line.visible = false

		dagger = dagger_instance.instantiate()
		dagger.hit_signal.connect(self.hit_signal)
		if multiplayer.is_server():
			Global.server_skill.add_child(dagger, true)
		else:
			Global.client_skill.add_child(dagger, true)
			rpc_id(Global.world.get_opponent_id(), "add_skill", "dagger")
		ignore_skill()
		dagger.set_multiplayer_authority(multiplayer.get_unique_id())
		character.slow_motion()
		dagger.global_position = dash_preview.get_node("Dash").global_position
		dagger.fire((end_point - dash_preview.get_node("Dash").global_position).angle())

		await get_tree().create_timer((end_point - body.global_position).length() / dagger.speed).timeout

		if not _hit:
			end_point = Global.avoid_enemies(end_point - body.global_position)
			teleport()
			if not multiplayer.is_server():
				rpc_id(Global.world.get_opponent_id(), "remove_skill")
		else:
			_hit = false


func ignore_skill() -> void:
	for child in local_character.get_children():
		child.add_collision_exception_with(dagger)


func teleport() -> void:

	for child in get_node("LocalCharacter").get_children():
		child._rotate(body.global_rotation)
		child.locate(end_point)
		child.teleport()
		dagger.queue_free()

func hit_signal(hit: Node2D) -> void:
	_hit = true
	if hit is RigidBody2D or hit is CharacterBody2D:
		if hit.get_node("../..") != self and not hit.is_in_group("Skill"):
			end_point = Global.avoid_enemies(end_point - body.global_position)
			character.stun_opponent()
			character._invul()
			if hit.name == "Head":
				character.damage_opponent(damage * 2)

			else:
				character.damage_opponent(damage * 1)
			character.invul_opponent()

		else:
			cooldown.stop()

	else:
		end_point = dagger.global_position
	teleport()

	if multiplayer.get_unique_id() != 1:
		rpc_id(Global.world.get_opponent_id(), "remove_skill")
