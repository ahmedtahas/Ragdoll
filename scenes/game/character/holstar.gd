extends Node2D

@onready var joy_stick_instance = preload("res://scenes/game/modules/joy_stick.tscn")
@onready var character_instance = preload("res://scenes/game/modules/character.tscn")
@onready var bullet_instance = preload("res://scenes/game/tools/bullet.tscn")

@onready var health: float = get_node("/root/Config").get_value("health", "holstar")
@onready var damage: float = get_node("/root/Config").get_value("damage", "holstar")
@onready var hit_power: float = get_node("/root/Config").get_value("power", "holstar")

@onready var character: Node2D
@onready var joy_stick: CanvasLayer
@onready var bullet: CharacterBody2D

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var rua: RigidBody2D = $RUA
@onready var rla: RigidBody2D = $RLA
@onready var ra: CharacterBody2D = $Extra/ShootingArm
@onready var crosshair: Sprite2D = $Extra/Cross
@onready var barrel: Marker2D = $Extra/ShootingArm/Barrel


func _ready() -> void:
	character = character_instance.instantiate()
	joy_stick = joy_stick_instance.instantiate()
	
	get_node("Extra").add_child(character)
	get_node("Extra").add_child(joy_stick)
	
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	
	cooldown.wait_time = get_node("/root/Config").get_value("cooldown", "holstar")
	
	ra.visible = false
	ra.set_collision_layer_value(1, false)
	ra.set_collision_mask_value(1, false)
	
	crosshair.visible = false
	
	_ignore_self()
	
	
func _ignore_self() -> void:
	for child_1 in get_children():
		if child_1 is RigidBody2D:
			child_1.body_entered.connect(self._on_body_entered.bind(child_1))
			child_1.add_collision_exception_with(ra)
			for child_2 in get_children():
				if child_1 != child_2 and child_2 is RigidBody2D:
					child_1.add_collision_exception_with(child_2)


func _on_body_entered(body: Node, caller: RigidBody2D) -> void:
	character.on_body_entered(body, caller, hit_power, damage)
	
	
func take_damage(amount: float) -> void:
	if health <= amount:
		return
	health -= amount
	
	
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
		
		
func bullet_hit_signal(hit: Node2D) -> void:
	if hit is RigidBody2D:
		if hit.get_parent() != self:
			hit.apply_central_impulse((hit.global_position - bullet.global_position).normalized() * hit_power)
			hit.get_parent().character.stun()
			if hit.name == "Head":
				hit.get_parent().take_damage(40)
			elif not hit.get_parent() is RigidBody2D:
				hit.get_parent().take_damage(20)
		else:
			cooldown.stop()
			
	bullet.disconnect("hit_signal", bullet_hit_signal)
	bullet.queue_free()
		
