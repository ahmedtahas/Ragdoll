extends Node2D


@onready var joy_stick_instance = preload("res://scenes/game/modules/joy_stick.tscn")
@onready var character_instance = preload("res://scenes/game/modules/character.tscn")
@onready var before_image_instance = preload("res://scenes/game/tools/before_image.tscn")

@onready var cooldown_time: float = get_node("/root/Config").get_value("cooldown", "zeina")
@onready var health: float = get_node("/root/Config").get_value("health", "zeina")
@onready var current_health: float = health
@onready var damage: float = get_node("/root/Config").get_value("damage", "zeina")
@onready var power: float = get_node("/root/Config").get_value("power", "zeina")
@onready var speed: float = get_node("/root/Config").get_value("speed", "zeina")

@onready var character: Node2D
@onready var joy_stick: CanvasLayer
@onready var before_image: CharacterBody2D
@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var dash_preview: Marker2D = $Extra/Center
@onready var _range: Marker2D = $Extra/Center/Range
@onready var Body: RigidBody2D = $Body

@onready var hit_check: bool = false
@onready var flicker: bool = false
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
	
	
	for line in dash_preview.get_node("Dash").get_children():
		line.visible = false
	
	cooldown.wait_time = cooldown_time
	cooldown_bar = character.get_node("UI/CooldownBar")
	cooldown_text = character.get_node("UI/CooldownBar/Text")
	
	cooldown_bar.set_value(100)
	cooldown_text.set_text("[center]ready[/center]")
	
	_ignore_self()
	

func _physics_process(_delta: float) -> void:
	
	dash_preview.global_position = Body.global_position + Vector2(0, 213)
	
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
			for child_2 in get_children():
				if child_1 != child_2 and child_2 is RigidBody2D:
					child_1.add_collision_exception_with(child_2)


func _flicker() -> void:
	if flicker:
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = true
			await get_tree().create_timer(0.017).timeout
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = false
			await get_tree().create_timer(0.017).timeout
		_flicker()


func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped():
		return
		
	if is_aiming:
		dash_preview.global_rotation = direction.angle()
		if not flicker:
			flicker = true
			for line in dash_preview.get_node("Dash").get_children():
				line.visible = true
			_flicker()
		
	else:
		hit_check = false
		character.slow_motion()
		cooldown.start()
		for child in get_children():
			if child is RigidBody2D:
				child.visible = false
				child.set_collision_layer_value(1, false)
				child.set_collision_mask_value(1, false)
				
		flicker = false
		
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = false
			
		before_image = before_image_instance.instantiate()
		get_node("Extra").add_child(before_image)
		before_image.hit_signal.connect(skill_hit_signal)
		before_image.rotation = dash_preview.global_rotation
		before_image.global_position = dash_preview.get_node("Dash").global_position
		before_image._set_velocity(dash_preview.global_rotation)
		get_parent().mtc.remove_target(Body)
		get_parent().mtc.add_target(before_image)	
		await get_tree().create_timer((_range.position.x - dash_preview.get_node("Dash").position.x) / before_image.speed).timeout
		if hit_check:
			return
		get_parent().mtc.remove_target(before_image)
		before_image.queue_free()
		get_parent().respawn_player(dash_preview.get_node("Dash/Range").global_position, character.health, self, true)
		
func skill_hit_signal(hit: Node2D) -> void:
	hit_check = true
	if hit is RigidBody2D:
		
		if hit.get_parent() != self:
			before_image.disconnect("hit_signal", skill_hit_signal)
			
			get_parent().mtc.remove_target(before_image)
			before_image.queue_free()
			cooldown.stop()
			hit.get_parent().character.stun()
			hit.apply_central_impulse((hit.global_position - before_image.global_position).normalized() * character.power)
			#hit.get_parent().take_damage(damage * 2)
			get_parent().respawn_player(dash_preview.get_node("Dash/Range").global_position, character.health, self, true)
			
		else:
			for child in get_children():
				if child is RigidBody2D:
					child.visible = true
					child.set_collision_layer_value(1, true)
					child.set_collision_mask_value(1, true)
					
			cooldown.stop()
			before_image.disconnect("hit_signal", skill_hit_signal)
			get_parent().mtc.remove_target(before_image)
			before_image.queue_free()
			get_parent().mtc.add_target(Body)
	else:
		print("AAA")
		before_image.disconnect("hit_signal", skill_hit_signal)
		get_parent().mtc.remove_target(before_image)
		before_image.queue_free()
		get_parent().respawn_player(dash_preview.get_node("Dash/Range").global_position, character.health, self, true)
		
