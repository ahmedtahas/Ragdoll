extends Node2D

@onready var player1_instance = preload("res://scenes/game/character/crock.tscn")
@onready var player2_instance = preload("res://scenes/game/character/selim.tscn")
@onready var mtc_instance = preload("res://scenes/game/modules/multi_target_camera.tscn")

@onready var point1: Marker2D = $Point1
@onready var point2: Marker2D = $Point2

@onready var mtc: Camera2D
@onready var player1: Node2D
@onready var player2: Node2D

@onready var room: Vector2 = Vector2(21120, -10560)

func _ready() -> void:
	player2 = player1_instance.instantiate()
	player1 = player2_instance.instantiate()
	mtc = mtc_instance.instantiate()
	
	player1.transform = Transform2D(point1.transform)
	player2.transform = Transform2D(point2.transform)
	
	add_child(player1)
	add_child(player2)
	add_child(mtc)
	
	mtc.add_target(player1.get_node("Body"))
	mtc.add_target(player2.get_node("Body"))
	
	#player2.joy_stick.disconnect("move_signal", player2.character.move_signal)
	#player2.joy_stick.disconnect("skill_signal", player2.skill_signal)
	

func respawn_player(player_position: Vector2, player_health: float, player: Node2D, cooldown: bool):
	Engine.time_scale = 1
	print(player)
	if player == player1:
		var potential_position = player_position
		var opponent_center = player2.get_node("Body").global_position + player2.center.rotated(player2.get_node("Body").global_rotation)
		mtc.remove_target(player1.get_node("Body"))
		player1.queue_free()
		potential_position = get_inside_position(potential_position, player)
			
		var player_center = potential_position + player.center
		if (opponent_center - player_center).length() < player2.radius.x:
			potential_position += ((player_center - opponent_center) + Vector2.RIGHT).normalized() * (get_opponent(player1).radius.x + 200) 
		player1 = player2_instance.instantiate()
		player1.transform = Transform2D(0, potential_position)
		add_child(player1)
		mtc.add_target(player1.get_node("Body"))
		player1.character.health = player_health
		if cooldown:
			player1.cooldown.start()
	else:
		var potential_position = player_position
		var opponent_center = player1.get_node("Body").global_position + player1.center.rotated(player1.get_node("Body").global_rotation)
		mtc.remove_target(player2.get_node("Body"))
		player2.queue_free()
		potential_position = get_inside_position(potential_position, player)
			
		var player_center = potential_position + player.center
		if (opponent_center - player_center).length() < player1.radius.x:
			potential_position += ((player_center - opponent_center) + Vector2.RIGHT).normalized() * (get_opponent(player2).radius.x + 200) 
		player2 = player1_instance.instantiate()
		player2.transform = Transform2D(0, potential_position)
		add_child(player2)
		mtc.add_target(player2.get_node("Body"))
		player2.character.health = player_health
		if cooldown:
			player2.cooldown.start()
	
	
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
