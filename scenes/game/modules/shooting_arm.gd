extends CharacterBody2D

@onready var gun = preload("res://assets/sprites/weapon/gun.png")
@onready var body: RigidBody2D = get_parent().get_parent().get_node("Body")

func _ready() -> void:
	$Gun.texture = gun

func _physics_process(_delta: float) -> void:
	global_position = body.global_position
