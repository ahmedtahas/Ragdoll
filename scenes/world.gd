extends Node2D

@onready var player1_instance = preload("res://scenes/game/character/holstar.tscn")
@onready var player2_instance = preload("res://scenes/game/character/crock.tscn")
@onready var mtc_instance = preload("res://scenes/game/modules/multi_target_camera.tscn")
@onready var audio_instance = preload("res://scenes/game/modules/audio.tscn")

@onready var ses = preload("res://assets/sound_effects/slowdown-92003.mp3")

@onready var point1: Marker2D = $Point1
@onready var point2: Marker2D = $Point2

@onready var mtc: Camera2D
@onready var player1: Node2D
@onready var player2: Node2D
@onready var audio: Node2D

@onready var room: Vector2 = Vector2(21120, -10560)

func _ready() -> void:
	audio = audio_instance.instantiate()
	add_child(audio)
	audio.get_node("Sound").set_stream(ses)
	audio.get_node("Sound").set_volume_db(3)
	audio.get_node("Sound").play()
	
	player2 = player1_instance.instantiate()
	player1 = player2_instance.instantiate()
	mtc = mtc_instance.instantiate()
	
	#get_node("AudioStreamPlayer2D").play()
	
	player1.transform = Transform2D(point1.transform)
	player2.transform = Transform2D(point2.transform)
	
	
	add_child(player1)
	add_child(player2)
	add_child(mtc)
	
	mtc.add_target(player1.get_node("Body"))
	mtc.add_target(player2.get_node("Body"))
	
	player2.joy_stick.disconnect("move_signal", player2.character.move_signal)
	

func respawn_player(player_position: Vector2, player_health: float, player: Node2D, cooldown: bool):
	Engine.time_scale = 1
	
	#get_node("AudioStreamPlayer2D").play()
	if player == player1:
		var potential_position = player_position
		var opponent_center = player2.get_node("Body").global_position + player2.center.rotated(player2.get_node("Body").global_rotation)
		mtc.remove_target(player1.get_node("Body"))
		player1.queue_free()
		potential_position = get_inside_position(potential_position, player)
			
		var player_center = potential_position + player.center
		if (opponent_center - player_center).length() < player2.radius.x:
			potential_position += (player_center - opponent_center).normalized() * (player2.radius.x + 200) 
		player1 = player2_instance.instantiate()
		player1.transform = Transform2D(0, potential_position)
		add_child(player1)
		mtc.add_target(player1.get_node("Body"))
		player1.health = player_health
		if cooldown:
			player1.cooldown.start()
	
	
func get_opponent(player) -> Node2D:
	if player == player1:
		return player2
	return player1
		
		
func get_inside_position(pos: Vector2, player: Node2D) -> Vector2:
	if pos.x > room.x:
		pos.x = room.x - player.radius.x
	elif pos.x < player.radius.x:
		pos.x = player.radius.x
	if pos.y < room.y:
		pos.y = room.y + player.radius.x
	elif pos.y > -player.radius.x:
		pos.y = -player.radius.x
	return pos
