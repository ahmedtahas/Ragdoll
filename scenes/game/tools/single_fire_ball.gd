extends CharacterBody2D

@onready var vel: Vector2 = Vector2.RIGHT
@onready var speed: float = 2500
@onready var collision: bool
@onready var duration: bool = true

signal hit_signal


func _physics_process(_delta: float) -> void:
	if duration:
		vel = vel.rotated((Global.bot.get_node("LocalCharacter/Body").global_position - global_position).angle())
	velocity = vel * speed
	collision = move_and_slide()
	if collision:
		emit_signal("hit_signal", get_last_slide_collision().get_collider())
