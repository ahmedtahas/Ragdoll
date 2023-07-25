extends Node2D


@onready var hit_cooldown: Timer = get_node("../HitCooldown")
@onready var invul_cooldown: Timer = get_node("../InvulnerabilityCooldown")

@onready var health: float
@onready var damage: float
@onready var speed: float
@onready var current_health: float
@onready var bot_health: float
@onready var bot_current_health: float

@onready var health_bar = get_node('LocalUI/HealthBar')
@onready var health_text = get_node('LocalUI/HealthBar/Text')
@onready var bot_health_bar = get_node('RemoteUI/HealthBar')

@onready var local_body: RigidBody2D = get_node("../../LocalCharacter/Body")

@onready var movement_vector: Vector2 = Vector2.ZERO

@onready var main_scene: Node2D

signal hit_signal

func _ready() -> void:
	main_scene = Global.world
	health = get_node("/root/Config").get_value("health", CharacterSelection.own)
	damage = get_node("/root/Config").get_value("damage", CharacterSelection.own)
	speed = get_node("/root/Config").get_value("speed", CharacterSelection.own)
	print(CharacterSelection.own, speed)
	current_health = health
	health_bar.set_value(100)
	health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")
	bot_health_bar.set_value(100)
	set_health()


func _physics_process(_delta: float) -> void:
	if hit_cooldown.is_stopped():
		local_body.apply_impulse(movement_vector * speed)


func set_health() -> void:
	bot_health = get_node("/root/Config").get_value("health", "bot")
	bot_current_health = bot_health

		
func ignore_self() -> void:
	for child_1 in get_node("../../LocalCharacter").get_children():
		child_1.body_entered.connect(self.on_body_entered.bind(child_1))
		for child_2 in get_node("../../LocalCharacter").get_children():
			if child_1 != child_2:
				child_1.add_collision_exception_with(child_2)


func damage_bot(amount: float) -> void:
	
	if bot_current_health <= amount:
		bot_current_health = 0
		bot_health_bar.set_value(bot_current_health)
		return
	bot_current_health -= amount
	bot_health_bar.set_value((100 * bot_current_health) / bot_health)


func on_body_entered(body: Node2D, caller: RigidBody2D) -> void:
	if body is RigidBody2D:
		emit_signal("hit_signal", body, caller)
		hit_stun()
		Global.bot.character.hit_stun()
		Global.world.slow_motion(0.05, 1)
		if caller.is_in_group("Damager") and body.name == "Head":
			damage_bot(damage * 2)
		elif caller.is_in_group("Damager") and body.is_in_group("Damagable"):
			damage_bot(damage)
			

func push_part(direction: Vector2, strength: float, part: String) -> void:
	Global.bot.get_node("LocalCharacter/" + part).apply_impulse(direction * strength)


func push_all(direction: Vector2, strength: float) -> void:
	for part in Global.bot.get_node("LocalCharacter").get_children():
		part.apply_impulse(direction * strength)
	
	
func invul() -> void:
	invul_cooldown.start()
	

func freeze_bot(duration: float) -> void:
	for part in Global.bot.get_node("LocalCharacter").get_children():
		part.freeze = true
	await get_tree().create_timer(duration).timeout
	for part in Global.bot.get_node("LocalCharacter").get_children():
		part.freeze = false


func take_damage(amount: float) -> void:
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


func move_signal(vector: Vector2, _dummy: bool) -> void:
	movement_vector = vector
	

func hit_stun(wait_time: float = 0.5) -> void:
	hit_cooldown.wait_time = wait_time
	hit_cooldown.start()


func play_audio() -> void:
	$hit.play()


func _exit_tree() -> void:
	Global.camera.remove_target(local_body)
