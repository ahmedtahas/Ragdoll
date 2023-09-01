extends Node2D

@onready var character_name: String = "bot"

@onready var radius: Marker2D = $Character/Hip/Center/Radius
@onready var center: Marker2D = $Character/Hip/Center
@onready var character: Node2D = $Character
@onready var direction_cooldown: Timer = $Extra/DirectionCooldown
@onready var paralyzed: Timer = $Extra/ParalyzeCooldown
@onready var dead: bool = false


func _ready() -> void:
	Global.opponent = self
	Global.camera.add_target(center)
	character.setup(character_name)
	paralyzed.start()
	Global.opponent_died.connect(death)


func _physics_process(_delta: float) -> void:
	if not direction_cooldown.is_stopped() or not paralyzed.is_stopped() or dead:
		return
	if (center.global_position - Global.player.center.global_position).length() > (Global.player.radius.position.x + radius.position.x + 500):
		character.move((Global.player.center.global_position - center.global_position).normalized())
	elif (center.global_position - Global.player.center.global_position).length() <= (Global.player.radius.position.x + radius.position.x + 500) and (center.global_position - Global.player.center.global_position).length() > (Global.player.radius.position.x + radius.position.x + 200):
		if Global.player.center.global_position.y < (Global.room.y / 2):
			character.move((Global.player.center.global_position - center.global_position).normalized().rotated(((Global.player.center.global_position - center.global_position) + Vector2.UP).angle()))
		else:
			character.move((Global.player.center.global_position - center.global_position).normalized().rotated(((Global.player.center.global_position - center.global_position) + Vector2.DOWN).angle()))
	else:
		character.move((center.global_position - Global.player.center.global_position).normalized())
		direction_cooldown.start()


func get_paralyzed(duration) -> void:
	paralyzed.wait_time = duration
	paralyzed.start()


func death() -> void:
	dead = true
	for child in character.get_children():
		for part in Global.player.character.get_children():
			child.add_collision_exception_with(part)
	for child in character.get_children():
		for joint in child.get_children():
			if joint is Joint2D:
				joint.queue_free()
	await get_tree().create_timer(4).timeout
	Global.camera.remove_target(center)
	for child in character.get_children():
		child.set_collision_layer_value(1, false)
		child.set_collision_mask_value(1, false)
		child.set_collision_layer_value(2, true)
		child.set_collision_mask_value(2, true)
		child.body_entered.disconnect(character.on_body_entered)
		child.set_script(null)
	character.set_script(null)
	set_script(null)

