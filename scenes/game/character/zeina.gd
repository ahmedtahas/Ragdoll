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

@onready var flicker: bool = false
@onready var cooldown_set: bool = false
@onready var _hit: bool = false

func _ready() -> void:
	name = str(get_multiplayer_authority())
	
	get_node("LocalCharacter").load_skin(character_name)
	
	dash_preview.visible = false
	
	_ignore_self()
	
	if is_multiplayer_authority():
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
		
	else:
		character.get_node("LocalUI").visible = false
		
		
	
	if is_multiplayer_authority():
		Global.camera.add_target(body)
		get_node("RemoteCharacter").queue_free()
		for part in get_node("LocalCharacter").get_children():
			part.set_power(character_name)
		
	else:
		Global.camera.add_target(get_node("RemoteCharacter/Body"))
		get_node("LocalCharacter").queue_free()
	

@rpc("call_remote", "reliable")
func add_skill(skill_name: String) -> void:
	Global.world.add_skill(skill_name)
	
	
@rpc("call_remote", "reliable")
func remove_skill() -> void:
	Global.world.remove_skill()



func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
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


func _flicker() -> void:
	if not is_multiplayer_authority():
		return
		
	if flicker:
		print(dash_preview.get_node("Dash").global_position)
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = true
			await get_tree().create_timer(0.017).timeout
		for line in dash_preview.get_node("Dash").get_children():
			line.visible = false
			await get_tree().create_timer(0.017).timeout
		_flicker()


func skill_signal(direction: Vector2, is_aiming) -> void:
	if not cooldown.is_stopped() or not is_multiplayer_authority():
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
		# check if hits character update endpoint
		
		end_point = get_node("../..").get_inside_position(end_point, str(multiplayer.get_unique_id()))
		
		cooldown.start()
		flicker = false
#		for line in dash_preview.get_node("Dash").get_children():
#			line.visible = false
		
		dagger = dagger_instance.instantiate()
		dagger.hit_signal.connect(self.hit_signal)
		if multiplayer.is_server():
			get_node("../../ServerSkill").add_child(dagger, true)
		else:
			get_node("../../ClientSkill").add_child(dagger, true)
			rpc_id(get_node("../..").get_opponent_id(), "add_skill", "dagger")
#		get_node("../../MultiplayerSpawner").spawn(dagger)
		dagger.set_multiplayer_authority(multiplayer.get_unique_id())
		character.slow_motion()
		dagger.global_position = dash_preview.get_node("Dash").global_position
		dagger.fire((end_point - dash_preview.get_node("Dash").global_position).angle())
			
		await get_tree().create_timer((end_point - body.global_position).length() / dagger.speed).timeout
		
		if not _hit:
			var opponent_id = str(get_node("../..").get_opponent_id())
			var opponent_pos = get_node("../" + opponent_id + "/RemoteCharacter/Body").global_position
			var opponent_rad = get_node("../" + opponent_id).radius
			if (end_point - opponent_pos).length() < opponent_rad.length():
				end_point = opponent_pos + ((dagger.global_position - opponent_pos).normalized() * (opponent_rad.length() + radius.length()))
			end_point = Global.world.get_inside_position(end_point, name)
			teleport()
			if not multiplayer.is_server():
				rpc_id(get_node("../..").get_opponent_id(), "remove_skill")
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
	if hit is RigidBody2D or hit is CharacterBody2D:
		if hit.get_node("../..") != self and not hit.is_in_group("Skill"):
			var opponent_id = str(get_node("../..").get_opponent_id())
			var opponent_pos = get_node("../" + opponent_id + "/RemoteCharacter/Body").global_position
			var opponent_rad = get_node("../" + opponent_id).radius
			
			end_point = opponent_pos + ((dagger.global_position - body.global_position).normalized() * (opponent_rad.length() + radius.length()))
			end_point = Global.world.get_inside_position(end_point, name)
			character.stun_opponent()
			character._invul()
			if hit.name == "Head":
				character.damage_opponent(damage * 2)
			else:
				character.damage_opponent(damage * 1)
			character.invul_opponent()
	else:
		end_point = dagger.global_position
	teleport()
	
	if multiplayer.get_unique_id() != 1:
		rpc_id(get_node("../..").get_opponent_id(), "remove_skill")
