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
@onready var ra: CharacterBody2D = $Character/Body/RF
@onready var crosshair: Sprite2D = $Extra/Cross
@onready var barrel: Marker2D = $Character/Body/RF/Barrel
@onready var cooldown_text: RichTextLabel = $Extra/UI/CooldownBar/Text
@onready var cooldown_bar: TextureProgressBar = $Extra/UI/CooldownBar

@onready var cooldown_set: bool = false
@onready var aiming: bool = false
@onready var growing: bool = false


func _ready() -> void:
	name = str(get_multiplayer_authority())
	character.setup(character_name)
	ignore_self()
	Global.camera.add_target(center)
	health.set_health(Config.get_value("health", character_name))
	ra.arm(character_name)
	if is_multiplayer_authority():
		Global.player = self
		skill_joy_stick.skill_signal.connect(self.skill_signal)
		skill_joy_stick.button = false
		cooldown_time = Config.get_value("cooldown", character_name)
		damage = Config.get_value("damage", character_name)
		power = Config.get_value("power", character_name)
		cooldown.wait_time = cooldown_time
		cooldown_bar.set_value(100)
		cooldown_text.set_text("[center]ready[/center]")

	else:
		get_node("Extra/UI").hide()
		Global.opponent = self

	ra.visible = false
	ra.set_collision_layer_value(1, false)
	ra.set_collision_mask_value(1, false)

	crosshair.visible = false


@rpc("reliable")
func add_skill(skill_name: String, pos: Vector2) -> void:
	Global.world.add_skill(skill_name, pos)


@rpc("reliable")
func remove_skill() -> void:
	Global.world.remove_skill()


func _physics_process(_delta: float) -> void:

	if not is_multiplayer_authority():
		return

	if aiming:
		crosshair.rotation += 0.075
		if growing:
			if crosshair.scale.x < 1.51:
				crosshair.scale.x += 0.05
				crosshair.scale.y += 0.05
			elif crosshair.scale.x >= 1.5:
				growing = false
		else:
			if crosshair.scale.x > 0.49:
				crosshair.scale.x -= 0.05
				crosshair.scale.y -= 0.05
			elif crosshair.scale.x == 0.5:
				growing = true
	else:
		crosshair.scale = Vector2(2,2)

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


func ignore_self() -> void:
	for child in character.get_children():
		child.add_collision_exception_with(ra)


func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority():
		return
	if not aiming:
		crosshair.global_position = barrel.global_position
	if is_aiming:
		aiming = is_aiming
		growing = true
		aiming_arm(true)
		aiming_arm.rpc(true)
		ra.look_at(crosshair.global_position)
		crosshair.visible = true
		crosshair.global_position += direction * 100
		crosshair.rotation += 0.075

	else:
		aiming_arm(false)
		aiming_arm.rpc(false)
		aiming = is_aiming
		growing = false
		cooldown.start()
		character.slow_motion()
		bullet_instance = bullet.instantiate()
		bullet_instance.hit_signal.connect(self.hit_signal)
		if multiplayer.is_server():
			Global.server_skill.add_child(bullet_instance, true)
		else:
			bullet_instance.set_multiplayer_authority(multiplayer.get_unique_id())
			Global.client_skill.add_child(bullet_instance, true)
			add_skill.rpc("bullet", barrel.global_position)
		ignore_skill()
		bullet_instance.global_position = barrel.global_position
		bullet_instance.look_at(crosshair.global_position)
		bullet_instance.fire((crosshair.global_position - barrel.global_position).angle())
		crosshair.visible = false


func ignore_skill() -> void:
	for child in character.get_children():
		child.add_collision_exception_with(bullet_instance)


@rpc("reliable")
func aiming_arm(show_arm: bool) -> void:
	if show_arm:
		ra.visible = true
		ra.set_collision_layer_value(1, true)
		ra.set_collision_mask_value(1, true)
		rua.visible = false
		rla.visible = false
		rf.visible = false

	else:
		ra.visible = false
		ra.set_collision_layer_value(1, false)
		ra.set_collision_mask_value(1, false)
		rua.visible = true
		rla.visible = true
		rf.visible = true


func hit_signal(hit: Node2D) -> void:
	if hit is RigidBody2D and not hit.is_in_group("Skill") and not hit.is_in_group("Undamagable"):
		Global.pushed.emit((hit.global_position - barrel.global_position).normalized() * power)
		Global.stunned.emit()
		if Global.mode == "single":
			if hit.name == "Head":
				health.damage_bot(damage * 3)
			else:
				health.damage_bot(damage * 1.5)
		if hit.name == "Head":
			Global.damaged.emit(damage * 3)
		else:
			Global.damaged.emit(damage * 1.5)
	bullet_instance.queue_free()
	if not multiplayer.is_server():
		remove_skill.rpc()
