extends Node2D

@onready var character_name: String = "zeina"

@onready var dagger: PackedScene = preload("res://scenes/game/tools/dagger.tscn")

@onready var cooldown_time: float
@onready var damage: float
@onready var end_point: Vector2

@onready var cooldown_text: RichTextLabel = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar

@onready var dagger_instance: CharacterBody2D

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center
@onready var character: Node2D = $Character
@onready var health: CanvasLayer = $Extra/Health
@onready var skill_joy_stick: Control = $Extra/UI/SkillJoyStick
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var body: RigidBody2D = $Character/Body
@onready var _range: Marker2D = $Character/Hip/Center/Range

@onready var hit_count: int = 0
@onready var flicker: bool = false
@onready var cooldown_set: bool = false
@onready var _hit: bool = false

func _ready() -> void:
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
		cooldown.wait_time = cooldown_time
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
		center.visible = false
		end_point = _range.global_position
		end_point = Global.get_inside_coordinates(end_point)
		cooldown.start()
		flicker = false
		dagger_instance = dagger.instantiate()
		dagger_instance.hit_signal.connect(dagger_hit_signal)
		if multiplayer.is_server():
			Global.server_skill.add_child(dagger_instance, true)
		else:
			dagger_instance.set_multiplayer_authority(multiplayer.get_unique_id())
			Global.client_skill.add_child(dagger_instance, true)
			add_skill.rpc("dagger")
		ignore_skill()
		character.slow_motion()
		dagger_instance.global_position = center.get_node("Dash").global_position
		dagger_instance.fire((end_point - center.get_node("Dash").global_position).angle())
		await get_tree().create_timer((end_point - center.global_position).length() / dagger_instance.speed).timeout
		if not _hit:
			end_point = Global.avoid_enemies(end_point - center.global_position)
			teleport()
			if not multiplayer.is_server():
				remove_skill.rpc()
		else:
			_hit = false


func ignore_skill() -> void:
	for child in character.get_children():
		child.add_collision_exception_with(dagger_instance)


func teleport() -> void:
	for child in character.get_children():
		child.locate(end_point)
		child.rotate(child.global_rotation)
		child.teleport()
	dagger_instance.hit_signal.disconnect(dagger_hit_signal)
	dagger_instance.queue_free()


func hit_signal(enemy: RigidBody2D, caller: RigidBody2D) -> void:
	if enemy.is_in_group("Damagable") and caller.is_in_group("Damager"):
		hit_count += 1


func dagger_hit_signal(hit: PhysicsBody2D) -> void:
	_hit = true
	if hit is RigidBody2D and not hit.is_in_group("Skill") and not hit.is_in_group("Undamagable"):
		end_point = Global.avoid_enemies(dagger_instance.global_position - center.global_position)
		Global.stunned.emit()
		character.slow_motion()
		if hit.name == "Head":
			Global.damaged.emit(damage * 2)
		elif not hit.is_in_group("Undamagable"):
			Global.damaged.emit(damage)
	elif hit is StaticBody2D:
		end_point = Global.get_inside_coordinates(dagger_instance.global_position)
	elif hit is CharacterBody2D:
		end_point = center.global_position
	teleport()
	if not multiplayer.is_server():
		remove_skill.rpc()
