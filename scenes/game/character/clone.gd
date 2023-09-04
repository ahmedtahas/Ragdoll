extends Node2D


@onready var character_name: String = "meri"

@onready var hit_cooldown: Timer = $Extra/HitCooldown

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center

@onready var character: Node2D = $Character
@onready var body: RigidBody2D = $Character/Body

@onready var movement_vector: Vector2
@onready var damage: float
@onready var speed: float


func _ready() -> void:
	for part in character.get_children():
		part.locate(Global.player.body.global_position)
		part.rotate(Global.player.body.global_rotation)
		part.teleport()
	ignore_self()
	Global.camera.add_target(center)
	speed = Config.get_value("speed", character_name)
	damage = Config.get_value("damage", character_name)
	if is_multiplayer_authority():
		Global.player.move_signal.connect(move_signal)

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority() and hit_cooldown.is_stopped():
		body.apply_impulse(movement_vector * speed)


func ignore_self() -> void:
	for child_1 in character.get_children():
		child_1.body_entered.connect(on_body_entered.bind(child_1))
		child_1.dress(character_name)
		child_1.set_power(character_name)
		for child_2 in character.get_children():
			if child_1 != child_2:
				child_1.add_collision_exception_with(child_2)
		if is_multiplayer_authority():
			for child in Global.player.character.get_children():
				child_1.add_collision_exception_with(child)
		else:
			for child in Global.opponent.character.get_children():
				child_1.add_collision_exception_with(child)


func on_body_entered(hit: PhysicsBody2D, caller: RigidBody2D) -> void:
	if hit is RigidBody2D and not hit.is_in_group("Skill"):
		hit_stun()
		slow_motion()
		if Global.mode == "multi":
			if caller.is_in_group("Damager") and hit.name == "Head":
				Global.damaged.emit(damage * 2)
			elif caller.is_in_group("Damager") and hit.is_in_group("Damagable"):
				Global.damaged.emit(damage)
		else:
			if caller.is_in_group("Damager") and hit.name == "Head":
				Global.player.health.damage_bot(damage * 2)
			elif caller.is_in_group("Damager") and hit.is_in_group("Damagable"):
				Global.player.health.damage_bot(damage)


func hit_stun(wait_time: float = 0.5) -> void:
	hit_cooldown.wait_time = wait_time
	hit_cooldown.start()


@rpc("reliable", "any_peer")
func slow_motion(time_scale: float = 0.05, duration: float = 0.75) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(time_scale * duration).timeout
	Engine.time_scale = 1


func move_signal(vector: Vector2) -> void:
	movement_vector = vector


func _exit_tree() -> void:
	Global.camera.remove_target(center)
