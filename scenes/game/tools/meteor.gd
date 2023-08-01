extends CharacterBody2D

@onready var vel: Vector2 = Vector2.RIGHT
@onready var speed: float = 2500
@onready var collision: bool
@onready var duration: bool = true
@onready var vector: Vector2
@onready var fire: GPUParticles2D = $Fire
@onready var sync: Node2D = $Synchronizer

signal hit_signal

func _ready() -> void:
	fire.process_material.scale_max = 0.1
	scale.x = 0.1
	scale.y = 0.1


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		if fire.process_material.scale_min < 1:
			fire.process_material.scale_min += 0.01
			scale.x += 0.01
			scale.y += 0.01
		if duration:
			vector = vel.rotated((Global.spawner.get_node(str(Global.world.get_opponent_id())+ "/RemoteCharacter/Body").global_position - global_position).angle())
		velocity = vector * speed
		collision = move_and_slide()
		if collision:
			emit_signal("hit_signal", get_last_slide_collision().get_collider())
		sync.pos = global_position
		sync.rot = global_rotation
		sync.particle_scale = fire.process_material.scale_min
		sync.meteor_scale = scale.x
	else:
		global_position = sync.pos
		global_rotation = sync.rot
		fire.process_material.scale_min = sync.particle_scale
		scale.x = sync.meteor_scale
		scale.y = sync.meteor_scale


func _enter_tree() -> void:
	Global.camera.add_target(self)


func _exit_tree() -> void:
	Global.camera.remove_target(self)
