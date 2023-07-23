extends Node2D


@onready var character_name: String = "tin"

@onready var cooldown_set: bool = false
@onready var charging: bool = false
@onready var shocking: bool = false

@onready var duration_time: float
@onready var cooldown_time: float
@onready var power: float

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/ChargeUp
@onready var shockwave: Sprite2D = $Extra/Shockwave


func _ready() -> void:
	name = character_name
	get_node("LocalCharacter").load_skin(character_name)
	_ignore_self()
	
	shockwave.visible = false
	
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	joy_stick.button = true
	
	cooldown_time = get_node("/root/Config").get_value("cooldown", character_name)
	duration_time = get_node("/root/Config").get_value("duration", character_name)
	power = get_node("/root/Config").get_value("power", character_name)
	
	cooldown.wait_time = cooldown_time
	duration.wait_time = duration_time

	cooldown_bar = character.get_node('LocalUI/CooldownBar')
	cooldown_text = character.get_node('LocalUI/CooldownBar/Text')

	cooldown_bar.set_value(100)
	cooldown_text.set_text("[center]ready[/center]")	
			
	for part in get_node("LocalCharacter").get_children():
		part.set_power(character_name)
	

@rpc("call_remote", "reliable")
func add_skill(skill_name: String) -> void:
	Global.world.add_skill(skill_name)
	
	
@rpc("call_remote", "reliable")
func remove_skill() -> void:
	Global.world.remove_skill()

	

func _physics_process(_delta: float) -> void:
	shockwave.global_position = body.global_position
	
	if shocking and shockwave.scale.x <= 30:
		_scale_shockwave(+0.25)
		
	elif not shocking and shockwave.scale.x > 0.25 and shockwave.visible:
		_scale_shockwave(-2)
	
	elif shockwave.scale.x <= 0.25:
		shockwave.visible = false
		shockwave.scale.x = 0.1
		shockwave.scale.y = 0.1
	
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
	for child_1 in get_node("LocalCharacter").get_children():
		child_1.body_entered.connect(character.on_body_entered.bind(child_1))
		for child_2 in get_node("LocalCharacter").get_children():
			if child_1 != child_2:
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
		var skill_range = shockwave.scale.x * 250
		duration.stop()
		cooldown.start()
		
		var opponent_pos = Global.bot.get_node("LocalCharacter/Body").global_position
		
		if (opponent_pos - body.global_position).length() < skill_range:
			character.push_all((body.global_position - opponent_pos).normalized(), power)
			character.damage_bot(multiplier * character.damage)
