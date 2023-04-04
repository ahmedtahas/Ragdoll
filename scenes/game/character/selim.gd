extends Node2D


@onready var joy_stick_instance = preload("res://scenes/game/modules/joy_stick.tscn")
@onready var character_instance = preload("res://scenes/game/modules/character.tscn")

@onready var duration_time: float = get_node("/root/Config").get_value("duration", "selim")
@onready var cooldown_time: float = get_node("/root/Config").get_value("cooldown", "selim")
@onready var health: float = get_node("/root/Config").get_value("health", "selim")
@onready var current_health: float = health
@onready var damage: float = get_node("/root/Config").get_value("damage", "selim")
@onready var power: float = get_node("/root/Config").get_value("power", "selim")
@onready var speed: float = get_node("/root/Config").get_value("speed", "selim")

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel
@onready var character: Node2D
@onready var joy_stick: CanvasLayer

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/ChargeUp
@onready var body: RigidBody2D = $Body
@onready var shockwave = $Extra/Shockwave

@onready var cooldown_set: bool = false
@onready var charging: bool = false
@onready var shocking: bool = false


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
	
	joy_stick.button = true
	
	cooldown.wait_time = cooldown_time
	duration.wait_time = duration_time
	cooldown_bar = character.get_node("UI/CooldownBar")
	cooldown_text = character.get_node("UI/CooldownBar/Text")
	cooldown_bar.set_value(100)
	cooldown_text.set_text("[center]ready[/center]")
	shockwave.visible = false
	
	_ignore_self()
	

func _physics_process(_delta: float) -> void:
	
	shockwave.global_position = body.global_position
	
	if shocking and shockwave.scale.x > 0.25:
		_scale_shockwave(-0.003)
	elif not shocking and shockwave.scale.x < 70 and shockwave.visible:
		_scale_shockwave(0.6)
		
	elif shockwave.scale.x >= 70:
		shockwave.visible = false
		shockwave.scale.x = 1
		shockwave.scale.y = 1
		
	if charging:
		if not duration.is_stopped():
			cooldown_bar.set_value((100 * duration.time_left) / duration_time)
			cooldown_text.set_text("[center]charge[/center]")
		
		elif duration.is_stopped():
			cooldown_bar.set_value(0)
			cooldown_text.set_text("[center]charged[/center]")
	
	elif cooldown.is_stopped():
		if cooldown_set:
			pass
		else:
			cooldown_bar.set_value(100)
			cooldown_text.set_text("[center]ready[/center]")
			cooldown_set = true
			
	elif duration.is_stopped():
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

func _scale_shockwave(value: float) -> void:
	shockwave.scale.x += value
	shockwave.scale.y += value


func skill_signal(is_charging: bool) -> void:
	
	if not cooldown.is_stopped():
		return
	
	if is_charging:
		shockwave.visible = true
		charging = true
		shocking = true
		body.freeze = true
		duration.start()
		
		
	else:
		body.freeze = false
		shocking = false
		charging = false
		var multiplier = duration_time - duration.time_left
		duration.stop()
		cooldown.start()
		var opponent = get_parent().get_opponent(self)
		await get_tree().create_timer((opponent.get_node("Body").global_position - body.global_position).length() / 10000).timeout
		opponent = get_parent().get_opponent(self)
		opponent.character.take_damage((multiplier / 2) * character.damage)
		opponent.character.push((opponent.get_node("Body").global_position - body.global_position).normalized(), character.power * multiplier)
		
		
		
		
		
		
		
