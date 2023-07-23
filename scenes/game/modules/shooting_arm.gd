extends CharacterBody2D

@onready var body: RigidBody2D = get_node("../../LocalCharacter/Body")
@onready var remote_body: CharacterBody2D


func _ready() -> void:
	if get_node("../..").has_node("RemoteCharacter"):
		remote_body = get_node("../../RemoteCharacter/Body")

func arm(character_name) -> void:
	$RUA.texture = load("res://assets/sprites/character/equipped/" + character_name + "/RUA.png")
	$RLA.texture = load("res://assets/sprites/character/equipped/" + character_name + "/RLA.png")
	$RF.texture = load("res://assets/sprites/character/equipped/" + character_name + "/RF.png")
	$RF.gun(character_name)

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		global_position = body.global_position
	else:
		global_position = remote_body.global_position
