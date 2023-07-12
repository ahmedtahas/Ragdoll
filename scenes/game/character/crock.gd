extends Node2D

@onready var character_name: String = "crock"

@onready var duration_time: float
@onready var cooldown_time: float


@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/SkillDuration

@onready var cooldown_set: bool = false


func _ready() -> void:
	name = str(get_multiplayer_authority())
	get_node("LocalCharacter").load_skin()
	_ignore_self()
	
	if is_multiplayer_authority():
		joy_stick.move_signal.connect(character.move_signal)
		joy_stick.skill_signal.connect(self.skill_signal)
		
		joy_stick.button = true
		duration_time = get_node("/root/Config").get_value("duration", character_name)
		cooldown_time = get_node("/root/Config").get_value("cooldown", character_name)
		
		cooldown.wait_time = cooldown_time
		duration.wait_time = duration_time
		cooldown_bar = character.get_node('UI/CooldownBar')
		cooldown_text = character.get_node('UI/CooldownBar/Text')
		cooldown_bar.set_value(100)
		cooldown_text.set_text("[center]ready[/center]")
		
	else:
		character.get_node("UI").visible = false
		
	if is_multiplayer_authority():
		get_node("../../MTC").add_target(body)
		get_node("RemoteCharacter").queue_free()
		for part in get_node("LocalCharacter").get_children():
			part.set_power()
		
	else:
		get_node("../../MTC").add_target(get_node("RemoteCharacter/Body"))
		get_node("LocalCharacter").queue_free()
	

@rpc("call_remote", "reliable")
func add_skill(skill_name: String) -> void:
	get_node("../..").add_skill(skill_name)
	
	
@rpc("call_remote", "reliable")
func remove_skill() -> void:
	get_node("../..").remove_skill()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	if not duration.is_stopped():
		cooldown_bar.set_value((100 * duration.time_left) / duration_time)
		cooldown_text.set_text("[center]" + str(duration.time_left).pad_decimals(1) + "s[/center]")
	
	elif cooldown.is_stopped():
		if not cooldown_set:
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
		for child_2 in get_node("RemoteCharacter").get_children():
			child_1.add_collision_exception_with(child_2)
			for child_3 in get_node("RemoteCharacter").get_children():
				if child_3 != child_2:
					child_3.add_collision_exception_with(child_2)


func skill_signal(using: bool) -> void:
	if not is_multiplayer_authority() or not cooldown.is_stopped() or not duration.is_stopped():
		return
		
	if using:
		pass
	
	else:
		var old_health = character.current_health
		var old_position = body.global_position
		
		duration.start()
		await get_tree().create_timer(duration_time).timeout
		character.current_health = old_health
		character._take_damage(0)
		cooldown.start()
		for child in get_node("LocalCharacter").get_children():
			child.locate(old_position)
			child.teleport()
