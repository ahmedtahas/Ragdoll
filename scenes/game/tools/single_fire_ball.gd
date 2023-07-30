extends CharacterBody2D

@onready var vel: Vector2 = Vector2.RIGHT
@onready var speed: float = 2500
@onready var collision: bool
@onready var duration: bool = true
@onready var vector: Vector2
@onready var fire: GPUParticles2D = $Fire

signal hit_signal

func _ready() -> void:
	fire.process_material.scale_max = 0.1
	scale.x = 0.1
	scale.y = 0.1


func _physics_process(_delta: float) -> void:
	if fire.process_material.scale_min < 1:
		fire.process_material.scale_min += 0.01
		scale.x += 0.01
		scale.y += 0.01
	if duration:
		vector = vel.rotated((Global.bot.get_node("LocalCharacter/Body").global_position - global_position).angle())
	velocity = vector * speed
	collision = move_and_slide()
	if collision:
		emit_signal("hit_signal", get_last_slide_collision().get_collider())


func _enter_tree() -> void:
	Global.camera.add_target(self)


func _exit_tree() -> void:
	Global.camera.remove_target(self)
