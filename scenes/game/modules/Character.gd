extends Node2D


@onready var cooldown: Timer = get_parent().get_node("HitCooldown")

const movement_strength: float = 50
var movement_vector: Vector2 = Vector2.ZERO


func on_body_entered(body: Node, caller: RigidBody2D, hit_power: float, damage: float) -> void:
	if body is RigidBody2D:
		body.apply_central_impulse((body.global_position - caller.global_position).normalized() * hit_power)
		caller.apply_central_impulse((caller.global_position - body.global_position).normalized() * hit_power)
		push((caller.global_position - body.global_position).normalized(), hit_power / 2)
		
		if body.get_parent() is RigidBody2D:
			body.get_parent().get_parent().character.push((body.global_position - caller.global_position).normalized(), hit_power / 2)
		else:
			body.get_parent().character.push((body.global_position - caller.global_position).normalized(), hit_power / 2)
			hit_stun()
			slow_motion()
			if caller.is_in_group("Damager") and body.name == "Head":
				body.get_parent().take_damage(damage * 2)
			elif caller.is_in_group("Damager") and body.is_in_group("Damagable"):
				body.get_parent().take_damage(damage)
		
	
func push(direction: Vector2, push_strength: float) -> void:
	for part in get_parent().get_parent().get_children():
			if part is RigidBody2D:
				part.apply_central_impulse(direction * push_strength)


func slow_motion(slow_motion_speed: float = 0.05, slow_motion_duration: float = 1):
	Engine.time_scale = slow_motion_speed
	await get_tree().create_timer(slow_motion_speed * slow_motion_duration).timeout
	Engine.time_scale = 1
	


func _physics_process(_delta: float):
	if cooldown.is_stopped():
		get_parent().get_parent().get_node("Body").apply_central_impulse(movement_vector * movement_strength)
	

func move_signal(vector: Vector2) -> void:
	movement_vector = vector
	

func stun() -> void:
	cooldown.wait_time = 0.5
	cooldown.start()


func hit_stun() -> void:
	cooldown.wait_time = 0.2
	cooldown.start()
	
func play_audio() -> void:
	$hit.play()
