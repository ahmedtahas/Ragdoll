extends Node2D


@onready var hit_cooldown: Timer = get_node("../HitCooldown")
@onready var invul_cooldown: Timer = get_node("../InvulnerabilityCooldown")

@onready var health: float
@onready var damage: float
@onready var power: float
@onready var speed: float
@onready var current_health: float

@onready var health_bar = get_node('UI/HealthBar')
@onready var health_text = get_node('UI/HealthBar/Text')

@onready var movement_vector: Vector2 = Vector2.ZERO

@onready var synchronizer: Node2D = get_parent()
@onready var is_gunner: bool = false

@onready var arm: CharacterBody2D

@onready var main_scene: Node2D
@onready var player_character: Node2D

@onready var local_head = get_node("../../LocalCharacter/Head")
@onready var local_body = get_node("../../LocalCharacter/Body")
@onready var local_rua = get_node("../../LocalCharacter/RUA")
@onready var local_rla = get_node("../../LocalCharacter/RLA")
@onready var local_rf = get_node("../../LocalCharacter/RF")
@onready var local_lua = get_node("../../LocalCharacter/LUA")
@onready var local_lla = get_node("../../LocalCharacter/LLA")
@onready var local_lf = get_node("../../LocalCharacter/LF")
@onready var local_hip = get_node("../../LocalCharacter/Hip")
@onready var local_rul = get_node("../../LocalCharacter/RUL")
@onready var local_rll = get_node("../../LocalCharacter/RLL")
@onready var local_rk = get_node("../../LocalCharacter/RK")
@onready var local_lul = get_node("../../LocalCharacter/LUL")
@onready var local_lll = get_node("../../LocalCharacter/LLL")
@onready var local_lk = get_node("../../LocalCharacter/LK")

@onready var remote_head = get_node("../../RemoteCharacter/Head")
@onready var remote_body = get_node("../../RemoteCharacter/Body")
@onready var remote_rua = get_node("../../RemoteCharacter/RUA")
@onready var remote_rla = get_node("../../RemoteCharacter/RLA")
@onready var remote_rf = get_node("../../RemoteCharacter/RF")
@onready var remote_lua = get_node("../../RemoteCharacter/LUA")
@onready var remote_lla = get_node("../../RemoteCharacter/LLA")
@onready var remote_lf = get_node("../../RemoteCharacter/LF")
@onready var remote_hip = get_node("../../RemoteCharacter/Hip")
@onready var remote_rul = get_node("../../RemoteCharacter/RUL")
@onready var remote_rll = get_node("../../RemoteCharacter/RLL")
@onready var remote_rk = get_node("../../RemoteCharacter/RK")
@onready var remote_lul = get_node("../../RemoteCharacter/LUL")
@onready var remote_lll = get_node("../../RemoteCharacter/LLL")
@onready var remote_lk = get_node("../../RemoteCharacter/LK")

func _ready() -> void:
	main_scene = get_node("../../../..")
	if is_multiplayer_authority():
		
		health = get_node("/root/Config").get_value("health", CharacterSelection.own)
		damage = get_node("/root/Config").get_value("damage", CharacterSelection.own)
		power = get_node("/root/Config").get_value("power", CharacterSelection.own)
		speed = get_node("/root/Config").get_value("speed", CharacterSelection.own)
		current_health = health
		health_bar.set_value(100)
		health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")



func on_body_entered(body: Node2D, caller: RigidBody2D) -> void:
	if body is CharacterBody2D and not body.is_in_group("Skill"):
		hit_stun()
		rpc("slow_motion")
		if caller.is_in_group("Damager") and body.name == "Head":
			rpc_id(main_scene.get_opponent_id(), "take_damage", damage * 2)
		elif caller.is_in_group("Damager") and body.is_in_group("Damagable"):
			rpc_id(main_scene.get_opponent_id(), "take_damage", damage)
			
			
func freeze_opponent(duration: float) -> void:
	rpc_id(main_scene.get_opponent_id(), "freeze_local", duration)
			
			
func invul_opponent() -> void:
	rpc_id(main_scene.get_opponent_id(), "invul")


func push_opponent_part(direction: Vector2, strength: float, part: String) -> void:
	rpc_id(main_scene.get_opponent_id(), "push_part", direction, strength, part)


func push_opponent(direction: Vector2, strength: float) -> void:
	rpc_id(main_scene.get_opponent_id(), "push_all", direction, strength)


func damage_opponent(amount: float) -> void:
	rpc_id(main_scene.get_opponent_id(), "take_damage", amount)
	
	
func stun_opponent(wait_time: float = 0.5) -> void:
	rpc_id(main_scene.get_opponent_id(), "stun", wait_time)


@rpc("call_remote", "any_peer", "reliable", 1)
func push_part(direction: Vector2, strength: float, part: String) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._push_part(direction, strength, part)


func _push_part(direction: Vector2, strength: float, part: String) -> void:
	get_node("/root/Main/Spawner/" + get_node("../..").name + "/LocalCharacter/" + part).apply_impulse(direction * strength)


@rpc("call_remote", "any_peer", "reliable", 1)
func push_all(direction: Vector2, strength: float) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._push_all(direction, strength)


func _push_all(direction: Vector2, strength: float) -> void:
	for part in get_node("/root/Main/Spawner/" + get_node("../..").name + "/LocalCharacter").get_children():
		part.apply_impulse(direction * strength)
	

@rpc("any_peer", "call_local", "reliable")
func slow_motion():
	main_scene.rpc("slowdown", 0.05, 1)
	
	
@rpc("call_remote", "any_peer", "reliable", 1)
func take_damage(amount: float) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._take_damage(amount)


@rpc("call_remote", "any_peer", "reliable", 1)
func freeze_local(duration: float) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._freeze_local(duration)


@rpc("call_remote", "any_peer", "reliable", 1)
func invul() -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._invul()
	
	
func _invul() -> void:
	invul_cooldown.start()
	
	
func blackout_opponent(duration: float) -> void:
	rpc_id(main_scene.get_opponent_id(), "blackout", duration)
	

@rpc("call_remote", "any_peer", "reliable", 1)
func blackout(duration: float) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._blackout(duration)


func _blackout(duration: float) -> void:
	var opponent = get_node("/root/Main/Spawner/" + str(main_scene.get_opponent_id()) + "/RemoteCharacter/Body")
	get_node("../../../../MTC").remove_target(opponent)
	await get_tree().create_timer(duration).timeout
	get_node("../../../../MTC").add_target(opponent)


func _freeze_local(duration: float) -> void:
	for child in get_node("../../LocalCharacter").get_children():
		child.freeze = true
	await get_tree().create_timer(duration).timeout
	for child in get_node("../../LocalCharacter").get_children():
		child.freeze = false


func _take_damage(amount: float) -> void:
	if not invul_cooldown.is_stopped():
		return
	if current_health <= amount:
		current_health = 0
		health_bar.set_value(current_health)
		health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")
		return
	current_health -= amount
	health_bar.set_value((100 * current_health) / health)
	health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")


func gunner() -> void:
	arm = get_node("../ShootingArm")
	is_gunner = true


func _physics_process(_delta: float):
	if is_multiplayer_authority():
		if hit_cooldown.is_stopped():
			local_body.apply_impulse(movement_vector * speed)
		# save local characters position and rotation
		synchronizer.head_pos = local_head.global_position
		synchronizer.head_rot = local_head.global_rotation
		
		synchronizer.body_pos = local_body.global_position
		synchronizer.body_rot = local_body.global_rotation
		
		synchronizer.rua_pos = local_rua.global_position
		synchronizer.rua_rot = local_rua.global_rotation
		synchronizer.rla_pos = local_rla.global_position
		synchronizer.rla_rot = local_rla.global_rotation
		synchronizer.rf_pos = local_rf.global_position
		synchronizer.rf_rot = local_rf.global_rotation
		
		synchronizer.lua_pos = local_lua.global_position
		synchronizer.lua_rot = local_lua.global_rotation
		synchronizer.lla_pos = local_lla.global_position
		synchronizer.lla_rot = local_lla.global_rotation
		synchronizer.lf_pos = local_lf.global_position
		synchronizer.lf_rot = local_lf.global_rotation
		
		synchronizer.hip_pos = local_hip.global_position
		synchronizer.hip_rot = local_hip.global_rotation
		
		synchronizer.rul_pos = local_rul.global_position
		synchronizer.rul_rot = local_rul.global_rotation
		synchronizer.rll_pos = local_rll.global_position
		synchronizer.rll_rot = local_rll.global_rotation
		synchronizer.rk_pos = local_rk.global_position
		synchronizer.rk_rot = local_rk.global_rotation
		
		synchronizer.lul_pos = local_lul.global_position
		synchronizer.lul_rot = local_lul.global_rotation
		synchronizer.lll_pos = local_lll.global_position
		synchronizer.lll_rot = local_lll.global_rotation
		synchronizer.lk_pos = local_lk.global_position
		synchronizer.lk_rot = local_lk.global_rotation
		
	else:
		# set remote characters position and rotation
		remote_head.global_position = synchronizer.head_pos
		remote_head.global_rotation = synchronizer.head_rot
		
		remote_body.global_position = synchronizer.body_pos
		remote_body.global_rotation = synchronizer.body_rot
		
		if is_gunner and synchronizer.aim != Vector2.ZERO:
			remote_rua.visible = false
			remote_rla.visible = false
			remote_rf.visible = false
			arm.visible = true
			arm.look_at(synchronizer.aim)
		elif is_gunner and synchronizer.aim == Vector2.ZERO:
			remote_rua.visible = true
			remote_rla.visible = true
			remote_rf.visible = true
			arm.visible = false
			
		remote_rua.global_position = synchronizer.rua_pos
		remote_rua.global_rotation = synchronizer.rua_rot
		remote_rla.global_position = synchronizer.rla_pos
		remote_rla.global_rotation = synchronizer.rla_rot
		remote_rf.global_position = synchronizer.rf_pos
		remote_rf.global_rotation = synchronizer.rf_rot
		
		remote_lua.global_position = synchronizer.lua_pos
		remote_lua.global_rotation = synchronizer.lua_rot
		remote_lla.global_position = synchronizer.lla_pos
		remote_lla.global_rotation = synchronizer.lla_rot
		remote_lf.global_position = synchronizer.lf_pos
		remote_lf.global_rotation = synchronizer.lf_rot
		
		remote_hip.global_position = synchronizer.hip_pos
		remote_hip.global_rotation = synchronizer.hip_rot
		
		remote_rul.global_position = synchronizer.rul_pos
		remote_rul.global_rotation = synchronizer.rul_rot
		remote_rll.global_position = synchronizer.rll_pos
		remote_rll.global_rotation = synchronizer.rll_rot
		remote_rk.global_position = synchronizer.rk_pos
		remote_rk.global_rotation = synchronizer.rk_rot
		
		remote_lul.global_position = synchronizer.lul_pos
		remote_lul.global_rotation = synchronizer.lul_rot
		remote_lll.global_position = synchronizer.lll_pos
		remote_lll.global_rotation = synchronizer.lll_rot
		remote_lk.global_position = synchronizer.lk_pos
		remote_lk.global_rotation = synchronizer.lk_rot
	

func move_signal(vector: Vector2) -> void:
	movement_vector = vector
	

@rpc("call_remote", "any_peer", "reliable", 1)
func stun(wait_time: float = 0.5) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character.hit_stun(wait_time)


func hit_stun(wait_time: float = 0.5) -> void:
	hit_cooldown.wait_time = wait_time
	hit_cooldown.start()
	

func play_audio() -> void:
	$hit.play()


#func _input(event: InputEvent) -> void:
#	movement_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	


