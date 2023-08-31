extends CharacterBody2D

@export var rot: float = 0

func arm(character_name) -> void:
	$RUA.texture = load("res://assets/sprites/character/equipped/" + character_name + "/RUA.png")
	$RLA.texture = load("res://assets/sprites/character/equipped/" + character_name + "/RLA.png")
	$RF.texture = load("res://assets/sprites/character/equipped/" + character_name + "/RF.png")
	$RF.weapon_collision(character_name)


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		rot = global_rotation
	else:
		global_rotation = rot
