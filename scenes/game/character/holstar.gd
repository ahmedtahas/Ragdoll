extends Node2D

@onready var character_name = "holstar"

@onready var bullet_instance: PackedScene = preload("res://scenes/game/tools/bullet.tscn")

@onready var cooldown_time: float
@onready var power: float
@onready var damage: float

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var bullet: CharacterBody2D

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var synchronizer: Node2D = $Extra
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var rua: RigidBody2D = $LocalCharacter/RUA
@onready var rla: RigidBody2D = $LocalCharacter/RLA
@onready var rf: RigidBody2D = $LocalCharacter/RF
@onready var rrua: CharacterBody2D = $RemoteCharacter/RUA
@onready var rrla: CharacterBody2D = $RemoteCharacter/RLA
@onready var rrf: CharacterBody2D = $RemoteCharacter/RF
@onready var body: RigidBody2D = $LocalCharacter/Body

@onready var ra: CharacterBody2D = $Extra/ShootingArm
@onready var crosshair: Sprite2D = $Extra/Cross
@onready var barrel: Marker2D = $Extra/ShootingArm/Barrel

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var cooldown_set: bool = false

@onready var world: Node2D = get_node("../..")


func _ready() -> void:
	name = str(get_multiplayer_authority())
	get_node("LocalCharacter").load_skin(character_name)
	get_node("Extra/ShootingArm").arm(character_name)
	character.gunner()
	_ignore_self()
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
	
	ra.visible = false
	ra.set_collision_layer_value(1, false)
	ra.set_collision_mask_value(1, false)
	
	crosshair.visible = false
	

@rpc("call_remote", "reliable")
func add_skill(skill_name: String) -> void:
	Global.world.add_skill(skill_name)
	
	
@rpc("call_remote", "reliable")
func remove_skill() -> void:
	Global.world.remove_skill()


func _physics_process(_delta: float) -> void:
	
	if not ra.visible:
		crosshair.global_position = barrel.global_position
		
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
	
	
func _ignore_self() -> void:
	for child in get_node("LocalCharacter").get_children():
		child.add_collision_exception_with(ra)
	for child in get_node("RemoteCharacter").get_children():
		child.add_collision_exception_with(ra)
	
	
func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority():
		return
	
	if is_aiming:
		ra.visible = true
		ra.set_collision_layer_value(1, true)
		ra.set_collision_mask_value(1, true)
		crosshair.visible = true
		rua.visible = false
		rla.visible = false
		rf.visible = false
		ra.look_at(crosshair.global_position)
		crosshair.global_position += direction * 20
		crosshair.rotation += 0.075
		synchronizer.aim = crosshair.global_position
			
	else:
		synchronizer.aim = Vector2.ZERO
		cooldown.wait_time = 6
		cooldown.start()
		character.slow_motion()
		bullet = bullet_instance.instantiate()
		bullet.hit_signal.connect(self.hit_signal)
		if multiplayer.is_server():
			get_node("../../ServerSkill").add_child(bullet, true)
		else:
			get_node("../../ClientSkill").add_child(bullet, true)
			rpc_id(get_node("../..").get_opponent_id(), "add_skill", "bullet")
		bullet.set_multiplayer_authority(multiplayer.get_unique_id())
		bullet.global_position = barrel.global_position
		bullet.look_at(crosshair.global_position)
		bullet.fire((crosshair.global_position - barrel.global_position).angle())
		
		crosshair.visible = false
		ra.visible = false
		ra.set_collision_layer_value(1, false)
		ra.set_collision_mask_value(1, false)
		rua.visible = true
		rla.visible = true
		rf.visible = true
		
		
func hit_signal(hit: Node2D) -> void:
	if (hit is RigidBody2D or hit is CharacterBody2D) and not hit.is_in_group("Skill"):
		if hit.get_node("../..") != self and not hit.is_in_group("Skill"):
			character.push_opponent_part((hit.global_position - barrel.global_position).normalized(), power, hit.name)
			character.push_opponent((hit.global_position - barrel.global_position).normalized(), power / 2)
			character.stun_opponent()
			if hit.name == "Head":
				character.damage_opponent(damage * 3)
			else:
				character.damage_opponent(damage * 1.5)
		else:
			cooldown.stop()
	bullet.queue_free()
	if not multiplayer.is_server():
		rpc_id(get_node("../..").get_opponent_id(), "remove_skill")
		
