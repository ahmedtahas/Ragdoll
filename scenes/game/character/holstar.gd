extends Node2D

@onready var joy_stick_instance = preload("res://scenes/game/modules/joy_stick.tscn")
@onready var character_instance = preload("res://scenes/game/modules/character.tscn")
@onready var bullet_instance = preload("res://scenes/game/tools/bullet.tscn")

@onready var cooldown_time: float = get_node("/root/Config").get_value("cooldown", "holstar")
@onready var health: float = get_node("/root/Config").get_value("health", "holstar")
@onready var current_health: float = health
@onready var damage: float = get_node("/root/Config").get_value("damage", "holstar")
@onready var power: float = get_node("/root/Config").get_value("power", "holstar")
@onready var speed: float = get_node("/root/Config").get_value("speed", "holstar")

@onready var character: Node2D
@onready var joy_stick: CanvasLayer
@onready var bullet: CharacterBody2D

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var rua: RigidBody2D = $RUA
@onready var rla: RigidBody2D = $RLA
@onready var rf: RigidBody2D = $RF
@onready var ra: CharacterBody2D = $Extra/ShootingArm
@onready var crosshair: Sprite2D = $Extra/Cross
@onready var barrel: Marker2D = $Extra/ShootingArm/Barrel


@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var cooldown_set: bool = false


func _ready() -> void:
	character = character_instance.instantiate()
	joy_stick = joy_stick_instance.instantiate()
	
	get_node("Extra").add_child(character)
	get_node("Extra").add_child(joy_stick)
	
	character.health = health
	character.current_health = current_health
	character.damage = damage
	character.power = power
	character.speed = speed
	
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	
	ra.visible = false
	ra.set_collision_layer_value(1, false)
	ra.set_collision_mask_value(1, false)
	
	crosshair.visible = false
	
	cooldown.wait_time = cooldown_time
	cooldown.start()
	cooldown_bar = character.get_node("UI/CooldownBar")
	cooldown_text = character.get_node("UI/CooldownBar/Text")
	cooldown_bar.set_value(100)
	cooldown_text.set_text("[center]ready[/center]")
	
	_ignore_self()
	

func _physics_process(_delta: float) -> void:
	if not ra.visible:
		crosshair.global_position = barrel.global_position
	if cooldown.is_stopped():
		if cooldown_set:
			pass
		else:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("[center]ready[/center]")
			cooldown_set = true
	else:
		if cooldown_set:
			cooldown_set = false
		cooldown_bar.set_value(100 - ((100 * cooldown.time_left) / cooldown_time))
		cooldown_text.set_text("[center]" + str(cooldown.time_left).pad_decimals(1) + "s[/center]")
	
	
func _ignore_self() -> void:
	for child_1 in get_children():
		if child_1 is RigidBody2D:
			child_1.body_entered.connect(character.on_body_entered.bind(child_1))
			child_1.add_collision_exception_with(ra)
			for child_2 in get_children():
				if child_1 != child_2 and child_2 is RigidBody2D:
					child_1.add_collision_exception_with(child_2)


	
func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped():
		return
	
	if is_aiming:
		ra.visible = true
		ra.set_collision_layer_value(1, true)
		ra.set_collision_mask_value(1, true)
		crosshair.visible = true
		crosshair.global_position += direction * 20
		crosshair.rotation += 0.075
		ra.look_at(crosshair.global_position)
		rua.visible = false
		rla.visible = false
		rf.visible = false
		
	else:
		cooldown.wait_time = 6
		cooldown.start()
		character.slow_motion(0.05, 1)
		bullet = bullet_instance.instantiate()
		get_node("Extra").add_child(bullet)
		bullet.hit_signal.connect(bullet_hit_signal)
		bullet.rotation = ra.global_rotation
		bullet.global_position = barrel.global_position
		bullet._set_velocity(ra.global_rotation)
		crosshair.visible = false
		crosshair.global_position = barrel.global_position
		ra.visible = false
		ra.set_collision_layer_value(1, false)
		ra.set_collision_mask_value(1, false)
		rua.visible = true
		rla.visible = true
		rf.visible = true
		
		
func bullet_hit_signal(hit: Node2D) -> void:
	if hit is RigidBody2D:
		if hit.get_parent() != self:
			hit.apply_central_impulse((hit.global_position - bullet.global_position).normalized() * character.power)
			if hit.get_parent() is RigidBody2D:
				hit.get_parent().get_parent().character.push((hit.global_position - bullet.global_position).normalized(), character.power * 0.5)
				hit.get_parent().get_parent().character.stun()
			else:
				hit.get_parent().character.push((hit.global_position - bullet.global_position).normalized(), character.power * 0.5)
				hit.get_parent().character.stun()
			if hit.name == "Head":
				hit.get_parent().character.take_damage(character.damage * 4)
			elif not hit.get_parent() is RigidBody2D:
				hit.get_parent().character.take_damage(character.damage * 2)
		else:
			cooldown.stop()
			
	bullet.disconnect("hit_signal", bullet_hit_signal)
	bullet.queue_free()
		
