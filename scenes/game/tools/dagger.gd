extends CharacterBody2D

@onready var vel: Vector2 = Vector2.RIGHT
@onready var speed: float = 10000
@onready var sync: Node2D = $Synchronizer
@onready var collision: bool


signal hit_signal


func _ready() -> void:
	$Sprite2D.texture = load("res://assets/sprites/character/equipped/zeina/RF.png")
	$Sprite2D.weapon_collision()


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		collision = move_and_slide()
		if collision:
			emit_signal("hit_signal", get_last_slide_collision().get_collider())
		global_rotation += 0.5 * Engine.time_scale
		sync.pos = global_position
		sync.rot = global_rotation
	else:
		global_position = sync.pos
		global_rotation = sync.rot


func fire(angle: float) -> void:
	set_velocity(vel.rotated(angle) * speed)


func _enter_tree() -> void:
	Global.camera.add_target(self)


func _exit_tree() -> void:
	Global.camera.remove_target(self)

