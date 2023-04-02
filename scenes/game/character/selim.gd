extends Node2D


@onready var joy_stick_instance = preload("res://scenes/game/modules/joy_stick.tscn")
@onready var character_instance = preload("res://scenes/game/modules/character.tscn")

@onready var health: float = get_node("/root/Config").get_value("health", "selim")
@onready var damage: float = get_node("/root/Config").get_value("damage", "selim")
@onready var hit_power: float = get_node("/root/Config").get_value("power", "selim")
@onready var duration: float = get_node("/root/Config").get_value("duration", "selim")

@onready var character: Node2D
@onready var joy_stick: CanvasLayer

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var charge_up: Timer = $Extra/ChargeUp


func _ready() -> void:
	character = character_instance.instantiate()
	joy_stick = joy_stick_instance.instantiate()
	
	get_node("Extra").add_child(character)
	get_node("Extra").add_child(joy_stick)
	
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	
	cooldown.wait_time = get_node("/root/Config").get_value("cooldown", "selim")
	
	_ignore_self()
	
	
func _ignore_self() -> void:
	for child_1 in get_children():
		if child_1 is RigidBody2D:
			child_1.body_entered.connect(self._on_body_entered.bind(child_1))
			for child_2 in get_children():
				if child_1 != child_2 and child_2 is RigidBody2D:
					child_1.add_collision_exception_with(child_2)


func _on_body_entered(body: Node, caller: RigidBody2D) -> void:
	character.on_body_entered(body, caller, hit_power, damage)

	
func take_damage(amount: float) -> void:
	if health <= amount:
		return
	health -= amount


func skill_signal(_direction: Vector2, is_aiming) -> void:
	
	if not cooldown.is_stopped():
		return
	
	if is_aiming:
		charge_up.start()
		
	else:
		var opponent = get_parent().get_opponent(self)
		await get_tree().create_timer((opponent.get_node("Body").global_position - get_node("Body").global_position).length() / 10000).timeout
		opponent = get_parent().get_opponent(self)
		opponent.take_damage((duration - charge_up.time_left) * damage)
		
		opponent.character.push((opponent.get_node("Body").global_position - get_node("Body").global_position).normalized(), hit_power * (duration - charge_up.time_left))
		
		
