extends Node2D

@onready var hit_cooldown: Timer = get_node("../Extra/HitCooldown")
@onready var invulnerability: Timer = get_node("../Extra/InvulnerabilityCooldown")
@onready var body: Node2D = get_node("Body")
@onready var movement_vector: Vector2 = Vector2.ZERO
@onready var speed: float = 0
@onready var damage: float = 0
@onready var character_name: String

signal hit_signal


func _ready() -> void:
	Global.pushed.connect(self.pushed)
	Global.freezed.connect(self.freezed)
	Global.stunned.connect(self.stunned)
	Global.invuled.connect(self.invuled)
	Global.opponent_died.connect(died)


func setup(_character_name: String) -> void:
	character_name = _character_name
	ignore_self()
	if is_multiplayer_authority():
		speed = Config.get_value("speed", character_name)
		damage = Config.get_value("damage", character_name)
	for child in get_children():
		child.dress(character_name)
		child.set_power(character_name)


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority() and hit_cooldown.is_stopped():
		body.apply_impulse(movement_vector * speed)


func move(vector: Vector2) -> void:
	movement_vector = vector


func ignore_self() -> void:
	for child_1 in get_children():
		child_1.body_entered.connect(self.on_body_entered.bind(child_1))
		for child_2 in get_children():
			if child_1 != child_2:
				child_1.add_collision_exception_with(child_2)


func on_body_entered(hit: PhysicsBody2D, caller: RigidBody2D) -> void:
	if get_parent().dead:
		return
	if hit is RigidBody2D and not hit.is_in_group("Skill"):
		hit_stun()
		slow_motion()
		if caller.is_in_group("Damager") and hit.name == "Head":
			Global.player.health.take_damage(damage * 2)
		elif caller.is_in_group("Damager") and hit.is_in_group("Damagable"):
			Global.player.health.take_damage(damage)


func stunned(wait_time: float = 0.5) -> void:
	hit_stun(wait_time)


func freezed(duration: float) -> void:
	freeze_local(duration)


func pushed(vector: Vector2) -> void:
	push_local(vector)


func invuled(wait_time: float = 0.5) -> void:
	invul_local(wait_time)


func slow_motion(time_scale: float = 0.05, duration: float = 0.75) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(time_scale * duration).timeout
	Engine.time_scale = 1


func freeze_local(duration: float) -> void:
	for child in get_children():
		child.freeze = true
	await get_tree().create_timer(duration).timeout
	for child in get_children():
		child.freeze = false


func push_local(vector: Vector2) -> void:
	for child in get_children():
		child.freeze = true
	for child in get_children():
		child.freeze = false
	hit_stun()
	for child in get_children():
		child.apply_impulse(vector)


func hit_stun(wait_time: float = 0.5) -> void:
	hit_cooldown.wait_time = wait_time
	hit_cooldown.start()


func invul_local(wait_time: float = 0.5) -> void:
	invulnerability.wait_time = wait_time
	invulnerability.start()


func died() -> void:
	pass
