extends Node2D

@onready var character_name = "holstar"

@onready var bullet_instance = preload("res://scenes/game/tools/bullet.tscn")

@onready var cooldown_time: float
@onready var power: float
@onready var damage: float

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var bullet: CharacterBody2D

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var rua: RigidBody2D = $LocalCharacter/RUA
@onready var rla: RigidBody2D = $LocalCharacter/RLA
@onready var rf: RigidBody2D = $LocalCharacter/RF
@onready var body: RigidBody2D = $LocalCharacter/Body

@onready var ra: CharacterBody2D = $Extra/ShootingArm
@onready var crosshair: Sprite2D = $Extra/Cross
@onready var barrel: Marker2D = $Extra/ShootingArm/Barrel

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var cooldown_set: bool = false
@onready var aiming: bool = false
@onready var growing: bool = false


func _ready() -> void:
	ignore_self()
	connect_body_signal()
	name = character_name
	get_node("LocalCharacter").load_skin(character_name)
	get_node("Extra/ShootingArm").arm(character_name)
	
	
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
			
	for part in get_node("LocalCharacter").get_children():
		part.set_power(character_name)
		
	ra.visible = false
	ra.set_collision_layer_value(1, false)
	ra.set_collision_mask_value(1, false)
	
	crosshair.visible = false
	

func connect_body_signal() -> void:
	for child in get_node("LocalCharacter").get_children():
		child.body_entered.connect(character.on_body_entered.bind(child))


func _physics_process(_delta: float) -> void:
	if not ra.visible:
		crosshair.global_position = barrel.global_position
		
	if aiming:
		crosshair.rotation += 0.075
		if growing:
			if crosshair.scale.x < 3.1:
				crosshair.scale.x += 0.1
				crosshair.scale.y += 0.1
			elif crosshair.scale.x >= 3:
				growing = false
		else:
			if crosshair.scale.x > 0.9:
				crosshair.scale.x -= 0.1
				crosshair.scale.y -= 0.1
			elif crosshair.scale.x == 1:
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
	for child_1 in get_node("LocalCharacter").get_children():
		child_1.add_collision_exception_with(ra)
		for child_2 in get_node("LocalCharacter").get_children():
			if child_1 != child_2:
				child_1.add_collision_exception_with(child_2)

	
func skill_signal(direction: Vector2, is_aiming: bool) -> void:
	if not cooldown.is_stopped():
		return
	if is_aiming:
		aiming = is_aiming
		growing = true
		ra.visible = true
		ra.set_collision_layer_value(1, true)
		ra.set_collision_mask_value(1, true)
		crosshair.visible = true
		rua.visible = false
		rla.visible = false
		rf.visible = false
		ra.look_at(crosshair.global_position)
		crosshair.global_position += direction * 20
			
	else:
		aiming = is_aiming
		growing = false
		cooldown.wait_time = 6
		cooldown.start()
		Global.world.slow_motion(0.05, 1)
		bullet = bullet_instance.instantiate()
		add_sibling(bullet)
		bullet.hit_signal.connect(self.hit_signal)
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
	if hit is RigidBody2D:
		if hit.get_node("../..") != self:
			character.push_part((hit.global_position - barrel.global_position).normalized(), power, hit.name)
			character.push_all((hit.global_position - barrel.global_position).normalized(), power / 2)
			Global.bot.character.hit_stun()
			if hit.name == "Head":
				character.damage_bot(damage * 3)
			else:
				character.damage_bot(damage * 1.5)
		else:
			cooldown.stop()
	bullet.queue_free()
		
