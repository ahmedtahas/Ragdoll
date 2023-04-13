extends Node2D


@onready var hit_cooldown: Timer = get_parent().get_node("HitCooldown")

@onready var health: float = get_node("/root/Config").get_value("health", get_parent().get_parent().name.replace("@", "").rstrip("0123456789").to_lower())
@onready var current_health: float =  health
@onready var damage: float =  get_node("/root/Config").get_value("damage", get_parent().get_parent().name.replace("@", "").rstrip("0123456789").to_lower())
@onready var power: float =  get_node("/root/Config").get_value("power", get_parent().get_parent().name.replace("@", "").rstrip("0123456789").to_lower())
@onready var speed: float =  get_node("/root/Config").get_value("speed", get_parent().get_parent().name.replace("@", "").rstrip("0123456789").to_lower())

@onready var health_bar = get_node("UI/HealthBar")
@onready var health_text = get_node("UI/HealthBar/Text")

@onready var movement_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	await get_tree().create_timer(0.01).timeout
	health_bar.set_value(100)
	health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")


func on_body_entered(body: Node, caller: RigidBody2D) -> void:
	if body is RigidBody2D:
		body.apply_central_impulse((body.global_position - caller.global_position).normalized() * power)
		caller.apply_central_impulse((caller.global_position - body.global_position).normalized() * power)
		push((caller.global_position - body.global_position).normalized(), power / 2)
		
		if body.get_parent() is RigidBody2D:
			body.get_parent().get_parent().character.push((body.global_position - caller.global_position).normalized(), power / 2)
		else:
			body.get_parent().character.push((body.global_position - caller.global_position).normalized(), power / 2)
			hit_stun()
			slow_motion()
			if caller.is_in_group("Damager") and body.name == "Head":
				body.get_parent().character.take_damage(damage * 2)
			elif caller.is_in_group("Damager") and body.is_in_group("Damagable"):
				body.get_parent().character.take_damage(damage)
		
	
func push(direction: Vector2, push_strength: float) -> void:
	for part in get_parent().get_parent().get_children():
			if part is RigidBody2D:
				part.apply_central_impulse(direction * push_strength)


func slow_motion(slow_motion_speed: float = 0.05, slow_motion_duration: float = 1):
	Engine.time_scale = slow_motion_speed
	await get_tree().create_timer(slow_motion_speed * slow_motion_duration).timeout
	Engine.time_scale = 1
	

func take_damage(amount: float) -> void:
	if current_health <= amount:
		current_health = 0
		health_bar.set_value(current_health)
		health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")
		return
	current_health -= amount
	health_bar.set_value((100 * current_health) / health)
	health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")


func _physics_process(_delta: float):
	if hit_cooldown.is_stopped():
		get_parent().get_parent().get_node("Body").apply_central_impulse(movement_vector * speed)
	

func move_signal(vector: Vector2) -> void:
	movement_vector = vector
	

func stun(wait_time: float = 0.5) -> void:
	hit_cooldown.wait_time = wait_time
	hit_cooldown.start()


func hit_stun() -> void:
	hit_cooldown.wait_time = 0.2
	hit_cooldown.start()
	
func play_audio() -> void:
	$hit.play()
