extends Node2D

@onready var character_name: String = "bot"

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var direction_cooldown: Timer = $Extra/DirectionCooldown

@onready var player: RigidBody2D

@onready var direction_set: bool = false


func _ready() -> void:
	name = character_name

	player = Global.player.get_node("LocalCharacter/Body")

	get_node("LocalCharacter").load_skin(character_name)

	_ignore_self()

	for part in get_node("LocalCharacter").get_children():
		part.set_power(character_name)


func _physics_process(_delta: float) -> void:

	if direction_set:
		return

	if (body.global_position - player.global_position).length() > (Global.player.radius.length() + radius.length() + 700):
		character.move_signal((player.global_position - body.global_position).normalized())

	elif (body.global_position - player.global_position).length() <= (Global.player.radius.length() + radius.length() + 700) and (body.global_position - player.global_position).length() > (Global.player.radius.length() + radius.length() + 300):
		if Global.player.get_node("LocalCharacter/Body").global_position.y > Global.room.y:
			character.move_signal((player.global_position - body.global_position).normalized().rotated((player.global_position - body.global_position).angle() + deg_to_rad(90)))
		else:

			character.move_signal((player.global_position - body.global_position).normalized().rotated((player.global_position - body.global_position).angle() + deg_to_rad(270)))
	else:
		character.move_signal((body.global_position - player.global_position).normalized())
		direction_set = true
		direction_cooldown.start()
		await direction_cooldown.timeout
		direction_set = false


func _ignore_self() -> void:
	for child_1 in get_node("LocalCharacter").get_children():
		child_1.body_entered.connect(character.on_body_entered.bind(child_1))
		for child_2 in get_node("LocalCharacter").get_children():
			if child_1 != child_2:
				child_1.add_collision_exception_with(child_2)
