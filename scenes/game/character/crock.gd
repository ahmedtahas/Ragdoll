extends Node2D

@onready var joy_stick_instance = preload("res://scenes/game/modules/joy_stick.tscn")
@onready var character_instance = preload("res://scenes/game/modules/character.tscn")

@onready var health: float = get_node("/root/Config").get_value("health", "crock")
@onready var damage: float = get_node("/root/Config").get_value("damage", "crock")
@onready var hit_power: float = get_node("/root/Config").get_value("power", "crock")
@onready var duration: float = get_node("/root/Config").get_value("duration", "crock")

@onready var character: Node2D
@onready var joy_stick: CanvasLayer

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var cooldown: Timer = $Extra/SkillCooldown


func _ready() -> void:
	character = character_instance.instantiate()
	joy_stick = joy_stick_instance.instantiate()
	
	get_node("Extra").add_child(character)
	get_node("Extra").add_child(joy_stick)
	
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	
	cooldown.wait_time = get_node("/root/Config").get_value("cooldown", "crock")
	_ignore_self()
	
	
func _ignore_self() -> void:
	for child_1 in get_children():
		if child_1 is RigidBody2D:
			child_1.body_entered.connect(self._on_body_entered.bind(child_1))
			for child_2 in get_children():
				if child_1 != child_2 and child_2 is RigidBody2D:
					child_1.add_collision_exception_with(child_2)
					
			for child in get_node('RF').get_children():
				if child is RigidBody2D:
					child_1.add_collision_exception_with(child)
					
	for child in get_node('RF').get_children():
		if child is RigidBody2D:
			for child_2 in get_node('RF').get_children():
				if child_2 is RigidBody2D and child != child_2:
					child_2.add_collision_exception_with(child)
					
	get_node('RF/Clock').body_entered.connect(self._on_body_entered.bind(get_node('RF/Clock')))


func _on_body_entered(body: Node, caller: RigidBody2D) -> void:
	
	character.on_body_entered(body, caller, hit_power, damage)
		

func take_damage(amount: float) -> void:
	if health <= amount:
		return
	health -= amount
	

func skill_signal(_direction: Vector2, is_aiming: bool) -> void:
	if not cooldown.is_stopped():
		return
	
	if is_aiming:
		pass
		
	else:
		cooldown.start()
		var old_health = health
		var old_position = get_node('Body').global_position
		await get_tree().create_timer(duration).timeout
		get_parent().respawn_player(old_position, old_health, self, true)
		
		
