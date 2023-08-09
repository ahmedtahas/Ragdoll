extends Node2D


@onready var hit_cooldown: Timer = get_node("../HitCooldown")
@onready var paralyze_cooldown: Timer = get_node("../ParalyzeCooldown")
@onready var invul_cooldown: Timer = get_node("../InvulnerabilityCooldown")

@onready var damage: float
@onready var power: float
@onready var speed: float

@onready var bot_body: RigidBody2D = get_node("../../LocalCharacter/Body")

@onready var movement_vector: Vector2 = Vector2.ZERO

@onready var main_scene: Node2D


func _ready() -> void:
	main_scene = Global.world
	damage = get_node("/root/Config").get_value("damage", CharacterSelection.own)
	speed = get_node("/root/Config").get_value("speed", CharacterSelection.own)


func _physics_process(_delta: float) -> void:
	if hit_cooldown.is_stopped() and paralyze_cooldown.is_stopped():
		bot_body.apply_impulse(movement_vector * speed)


func on_body_entered(body: Node2D, caller: RigidBody2D) -> void:
	if body is RigidBody2D and body.get_node("../..") != get_node("../.."):
		hit_stun()
		Global.world.slow_motion(0.05, 1)
		if caller.is_in_group("Damager") and body.name == "Head":
			print(caller.name)
			Global.player.character.take_damage(damage * 2)
		elif caller.is_in_group("Damager") and body.is_in_group("Damagable"):
			Global.player.character.take_damage(damage)
			print(caller.name, "   AAAAAA  ", body.name)


func move_signal(vector: Vector2) -> void:
	movement_vector = vector


func hit_stun(wait_time: float = 0.5) -> void:
	hit_cooldown.wait_time = wait_time
	hit_cooldown.start()


func play_audio() -> void:
	$hit.play()


func paralyze(wait_time: float = 0.5) -> void:
	paralyze_cooldown.wait_time = wait_time
	paralyze_cooldown.start()

#func _input(event: InputEvent) -> void:
#	movement_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")



