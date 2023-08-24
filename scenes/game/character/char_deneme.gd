extends Node2D


@onready var hit_cooldown: Timer = get_node("../HitCooldown")
@onready var invul_cooldown: Timer = get_node("../InvulnerabilityCooldown")

@onready var health: float
@onready var damage: float
@onready var speed: float
@onready var current_health: float

@onready var health_bar = get_node('LocalUI/HealthBar')
@onready var health_text = get_node('LocalUI/HealthBar/Text')
@onready var remote_health_bar = get_node('RemoteUI/HealthBar')
@onready var local_character = get_node("../../LocalCharacter")

@onready var movement_vector: Vector2 = Vector2.ZERO
@onready var synchronizer: Node2D = get_parent()
@onready var hit_count: float = 0

@onready var main_scene: Node2D

@onready var local_body = get_node("../../LocalCharacter/Body")

signal hit_signal


func _ready() -> void:
	main_scene = Global.world
	if get_node("../..").name == "Clone":
		damage = get_node("/root/Config").get_value("damage", "meri")
		speed = get_node("/root/Config").get_value("speed", "meri")
		return

	if is_multiplayer_authority():
		health = get_node("/root/Config").get_value("health", CharacterSelection.own)
		damage = get_node("/root/Config").get_value("damage", CharacterSelection.own)
		speed = get_node("/root/Config").get_value("speed", CharacterSelection.own)
		current_health = health
		health_bar.set_value(100)
		health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")

	else:
		remote_health_bar.set_value(100)
		await get_tree().create_timer(4).timeout
		set_health()


func set_health() -> void:
	health = get_node("/root/Config").get_value("health", CharacterSelection.opponent)
	current_health = health


func ignore_local() -> void:
	for child_1 in local_character.get_children():
		child_1.body_entered.connect(self.on_body_entered.bind(child_1))
		for child_2 in local_character.get_children():
			if child_1 != child_2:
				child_1.add_collision_exception_with(child_2)


func on_body_entered(body: Node2D, caller: RigidBody2D) -> void:
	if body is RigidBody2D and not body.is_in_group("Skill"):
		emit_signal("hit_signal", body, caller)
		hit_stun()
		rpc("slow_motion")

		if caller.is_in_group("Damager") and body.name == "Head":
			rpc_id(main_scene.get_opponent_id(), "take_damage", damage * 2)

		elif caller.is_in_group("Damager") and body.is_in_group("Damagable") and not body.is_in_group("Undamagable"):
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


@rpc("call_remote", "any_peer", "reliable", 1)
func push_all(direction: Vector2, strength: float) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._push_all(direction, strength)


@rpc("any_peer", "call_local", "reliable")
func slow_motion(time_scale: float = 0.05, duration: float = 0.75):
	main_scene.rpc("slowdown", time_scale, duration)


@rpc("call_remote", "any_peer", "reliable", 1)
func take_damage(amount: float) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._take_damage(amount)


@rpc("call_remote", "any_peer", "reliable", 1)
func freeze_local(duration: float) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._freeze_local(duration)


@rpc("call_remote", "any_peer", "reliable", 1)
func invul() -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character._invul()


@rpc("call_remote", "any_peer", "reliable", 1)
func stun(wait_time: float = 0.5) -> void:
	get_node("/root/Main/Spawner/" + str(multiplayer.get_unique_id())).character.hit_stun(wait_time)


func _push_part(direction: Vector2, strength: float, part: String) -> void:
	get_node("/root/Main/Spawner/" + get_node("../..").name + "/LocalCharacter/" + part).apply_impulse(direction * strength)


func _push_all(direction: Vector2, strength: float) -> void:
	for child in get_node("../../LocalCharacter").get_children():
		child.freeze = true
	for child in get_node("../../LocalCharacter").get_children():
		child.freeze = false
	for part in get_node("../../LocalCharacter").get_children():
		part.apply_impulse(direction * strength)


func _invul() -> void:
	invul_cooldown.start()


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


func _physics_process(_delta: float):
	if is_multiplayer_authority():
		if hit_cooldown.is_stopped():
			local_body.apply_impulse(movement_vector * speed)
		synchronizer.health = current_health

	else:
		current_health = synchronizer.health
		remote_health_bar.set_value((100 * current_health) / health)


func move_signal(vector: Vector2, _dummy: bool) -> void:
	movement_vector = vector


func hit_stun(wait_time: float = 0.5) -> void:
	hit_cooldown.wait_time = wait_time
	hit_cooldown.start()

