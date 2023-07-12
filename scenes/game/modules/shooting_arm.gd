extends CharacterBody2D

@onready var body: RigidBody2D = get_node("../../LocalCharacter/Body")
@onready var remote_body: CharacterBody2D = get_node("../../RemoteCharacter/Body")

func arm() -> void:
	$RUA.texture = load("res://assets/sprites/character/equipped/" + get_node("../..").character_name + "/RUA.png")
	$RLA.texture = load("res://assets/sprites/character/equipped/" + get_node("../..").character_name + "/RLA.png")
	$RF.texture = load("res://assets/sprites/character/equipped/" + get_node("../..").character_name + "/RF.png")
	$RF.gun()

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		global_position = body.global_position
	else:
		global_position = remote_body.global_position
