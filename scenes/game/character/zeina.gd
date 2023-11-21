extends Node2D

@onready var character_name: String = "zeina"

@onready var dagger: PackedScene = preload("res://scenes/game/tools/dagger.tscn")
@onready var after_image: PackedScene = preload("res://scenes/game/tools/after_image.tscn")

@onready var cooldown_time: float
@onready var damage: float
@onready var power: float
@onready var end_point: Vector2

@onready var cooldown_text: Label = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar

@onready var dagger_instance: CharacterBody2D
@onready var after_image_instance: Node2D

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center
@onready var character: Node2D = $Character
@onready var health: CanvasLayer = $Extra/Health
@onready var skill_joy_stick: Control = $Extra/UI/SkillJoyStick
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var body: RigidBody2D = $Character/Body
@onready var _range: Marker2D = $Character/Hip/Center/Range

@onready var hit_count: int = 2
@onready var flicker: bool = false
@onready var cooldown_set: bool = false
@onready var _hit: bool = false


func _ready() -> void:
	if get_parent().name == "Display":
		get_node("Extra/UI").hide()
		get_node("Extra/Health").hide()
		character.setup(character_name)
		center.visible = false
		return
	name = str(get_multiplayer_authority())
	character.setup(character_name)
	character.hit_signal.connect(hit_signal)
	Global.camera.add_target(center)
	health.set_health(Config.get_value("health", character_name))
	center.visible = false

	if is_multiplayer_authority():
		Global.player = self
		skill_joy_stick.skill_signal.connect(skill_signal)
		skill_joy_stick.button = false
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
		cooldown_text.set_text("" + str(cooldown.time_left).pad_decimals(1) + "s")


func _flicker() -> void:
	if not is_multiplayer_authority():
		return

	if flicker:
		for line in center.get_node("Dash").get_children():
			line.visible = true
			await get_tree().create_timer(0.017).timeout
		for line in center.get_node("Dash").get_children():
			line.visible = false
			await get_tree().create_timer(0.017).timeout
		_flicker()


func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority() or hit_count < 2:
		return
	if is_aiming:
		center.visible = true
		center.global_rotation = direction.angle()
		if not flicker:
			flicker = true
			for line in center.get_node("Dash").get_children():
				line.visible = true
			_flicker()

	else:
		hit_count = 0
		character.get_node("RF/Sprite").modulate = Color(0.1, 0.1, 0.1)
		character.get_node("LF/Sprite").modulate = Color(0.1, 0.1, 0.1)
		center.visible = false
		end_point = _range.global_position
		end_point = Global.get_inside_coordinates(end_point)
		cooldown.start()
		flicker = false
		dagger_instance = dagger.instantiate()
		dagger_instance.hit_signal.connect(dagger_hit_signal)
		dagger_instance.set_multiplayer_authority(multiplayer.get_unique_id())
		if Global.is_host:
			Global.server_skill.add_child(dagger_instance, true)
			add_skill.rpc("dagger", "ServerSkill")
		else:
			Global.client_skill.add_child(dagger_instance, true)
			add_skill.rpc("dagger", "ClientSkill")
		ignore_skill()
		character.slow_motion.rpc()
		dagger_instance.global_position = center.get_node("Dash").global_position
		dagger_instance.fire((end_point - center.get_node("Dash").global_position).angle())
		await get_tree().create_timer((end_point - center.global_position).length() / dagger_instance.speed).timeout
		if not _hit:
			end_point = Global.avoid_enemies(end_point - center.global_position)
			teleport()
			if Global.is_host:
				remove_skill.rpc("ServerSkill")
			else:
				remove_skill.rpc("ClientSkill")
		else:
			_hit = false


func ignore_skill() -> void:
	for child in character.get_children():
		child.add_collision_exception_with(dagger_instance)


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


func teleport() -> void:
	show_after_image.rpc()
	for child in character.get_children():
		child.visible = false
	for child in character.get_children():
		child.locate(end_point)
		child.rotate(child.global_rotation)
		child.teleport()
	dagger_instance.hit_signal.disconnect(dagger_hit_signal)
	dagger_instance.queue_free()
	await get_tree().create_timer((end_point - center.global_position).length() / (_range.position.x * 3)).timeout
	for child in character.get_children():
		child.visible = true
	remove_after_image.rpc()


func hit_signal(enemy: RigidBody2D, caller: RigidBody2D) -> void:
	if enemy.is_in_group("Damagable") and caller.is_in_group("Damager"):
		hit_count += 1
		if hit_count == 1:
			character.get_node("LF/Sprite").modulate = Color(1, 1, 1)
		else:
			character.get_node("RF/Sprite").modulate = Color(1, 1, 1)

func dagger_hit_signal(hit: PhysicsBody2D) -> void:
	_hit = true
	if hit is RigidBody2D and not hit.is_in_group("Skill"):
		end_point = Global.avoid_enemies(dagger_instance.global_position - center.global_position)
		Global.pushed.emit((dagger_instance.global_position - center.global_position).normalized() * power)
		Global.stunned.emit()
		if hit.name == "Head":
			Global.damaged.emit(damage * 2)
		elif not hit.is_in_group("Undamagable"):
			Global.damaged.emit(damage)
	elif hit is StaticBody2D:
		end_point = Global.get_inside_coordinates(dagger_instance.global_position)
	elif hit is CharacterBody2D:
		end_point = center.global_position
	teleport()
	if Global.is_host:
		remove_skill.rpc("ServerSkill")
	else:
		remove_skill.rpc("ClientSkill")
