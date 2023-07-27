extends Node2D

@onready var character_name: String = "zeina"

@onready var dagger_instance = preload("res://scenes/game/tools/dagger.tscn")

@onready var cooldown_time: float
@onready var power: float
@onready var damage: float
@onready var end_point: Vector2

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel
@onready var dagger: CharacterBody2D

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $"Extra/DoubleJoyStick"
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var dash_preview: Marker2D = $Extra/Center
@onready var _range: Marker2D = $Extra/Center/Range
@onready var dash_timer: Timer = $Extra/DashTimer

@onready var flicker: bool = false
@onready var cooldown_set: bool = false
@onready var _hit: bool = false


func _ready() -> void:
	name = character_name
	
	get_node("LocalCharacter").load_skin(character_name)
	
	dash_preview.visible = false
	
	character.ignore_self()
	
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
	

func _physics_process(_delta: float) -> void:
	dash_preview.global_position = body.global_position + Vector2(0, 280).rotated(body.global_rotation)
	
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
	if flicker:
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = true
			dash_timer.start()
			await dash_timer.timeout
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = false
			dash_timer.start()
			await dash_timer.timeout
		_flicker()


func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped():
		return
		
	if is_aiming:
		dash_preview.visible = true
		dash_preview.global_rotation = direction.angle()
		if not flicker:
			flicker = true
			for line in dash_preview.get_node("Dash").get_children():
				line.visible = true
			_flicker()
		
	else:
		dash_preview.visible = false
		end_point = _range.global_position
		cooldown.start()
		flicker = false
		dagger = dagger_instance.instantiate()
		add_sibling(dagger, true)
		dagger.hit_signal.connect(self.hit_signal)
		Global.world.slow_motion(0.05, 1)
		dagger.global_position = dash_preview.get_node("Dash").global_position
		dagger.fire((end_point - dash_preview.get_node("Dash").global_position).angle())
			
		await get_tree().create_timer((end_point - body.global_position).length() / dagger.speed).timeout
		
		if not _hit:
			var opponent_pos = Global.bot.get_node("LocalCharacter/Body").global_position
			var opponent_rad = Global.bot.radius
			
			if (end_point - opponent_pos).length() < opponent_rad.length():
				end_point = opponent_pos + ((dagger.global_position - opponent_pos).normalized() * (opponent_rad.length() + radius.length()))
			end_point = Global.get_inside_position(end_point, name)
			teleport()
		else:
			_hit = false


func teleport() -> void:
	
	for child in get_node("LocalCharacter").get_children():
		child._rotate(body.global_rotation)
		child.locate(end_point)
		child.teleport()
		dagger.queue_free()


func hit_signal(hit: Node2D) -> void:
	_hit = true
	if hit is RigidBody2D:
		if hit.get_node("../..") != self:
			end_point = Global.bot.get_node("LocalCharacter/Body").global_position + ((dagger.global_position - body.global_position).normalized() * (Global.bot.radius.length() + radius.length()))
			end_point = Global.get_inside_position(end_point, name)
			Global.bot.character.hit_stun()
			if hit.name == "Head":
				character.damage_bot(damage * 2)
			else:
				character.damage_bot(damage)
	else:
		end_point = dagger.global_position
	teleport()
