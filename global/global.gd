extends Node

const room: Vector2 = Vector2(20420, -10180)

@onready var camera: Camera2D
@onready var world: Node2D
@onready var spawner: Node2D
@onready var server_skill: Node2D
@onready var client_skill: Node2D
@onready var player: Node2D
@onready var bot: Node2D

signal black_out
signal two_players_joined

func get_inside_position(pos: Vector2) -> Vector2:
	if pos.x > room.x:
		pos.x = room.x - 120
	elif pos.x < 0:
		pos.x = 120
	if pos.y < room.y:
		pos.y = room.y + 120
	elif pos.y > 0:
		pos.y = -120
	return pos

func get_inside_position_player(pos: Vector2, player_id: String) -> Vector2:
	var _player = spawner.get_node(player_id)
	if pos.x > room.x:
		pos.x = room.x - 120
	elif pos.x < _player.radius.x:
		pos.x = 120
	if pos.y < room.y:
		pos.y = room.y + 120
	elif pos.y > -_player.radius.x:
		pos.y = -120
	return pos


func avoid_enemies(vector: Vector2) -> Vector2:
	var list: Dictionary = {}

	if multiplayer.is_server():
		list[spawner.get_node(str(world.client_id) + "/RemoteCharacter/Body").global_position + (spawner.get_node(str(world.client_id)).center.rotated(spawner.get_node(str(world.client_id) + "/RemoteCharacter/Body").global_rotation))] = spawner.get_node(str(world.client_id)).radius
		if client_skill.get_child_count() > 0:
			if not client_skill.get_child(0) is CharacterBody2D:
				list[client_skill.get_child(0).get_node("RemoteCharacter/Body").global_position + (client_skill.get_child(0).center.rotated(client_skill.get_child(0).get_node("RemoteCharacter/Body").global_rotation))] = client_skill.get_child(0).radius
		for object in list:
			if ((spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
				print("1")
				vector = vector.normalized() * (vector.length() + list[object].length())
				if ((spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
					print('2')
					vector = vector.normalized() * (vector.length() + list[object].length())
		vector = get_inside_position_player(spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position + vector, str(world.server_id)) - spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position
		for object in list:
			if ((spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
				print("1")
				print(vector)
				vector = vector.normalized() * (vector.length() - list[object].length())
				print(vector)
				if ((spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
					print('2')
					vector = vector.normalized() * (vector.length() - list[object].length())
		vector = get_inside_position_player(spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position + vector, str(world.server_id))
	else:
		list[spawner.get_node(str(world.server_id) + "/RemoteCharacter/Body").global_position + (spawner.get_node(str(world.server_id)).center.rotated(spawner.get_node(str(world.server_id) + "/RemoteCharacter/Body").global_rotation))] = spawner.get_node(str(world.server_id)).radius

		if server_skill.get_child_count() > 0:
			if not server_skill.get_child(0) is CharacterBody2D:
				list[server_skill.get_child(0).get_node("RemoteCharacter/Body").global_position + (server_skill.get_child(0).center.rotated(server_skill.get_child(0).get_node("RemoteCharacter/Body").global_rotation))] = server_skill.get_child(0).radius

		for object in list:
			if ((spawner.get_node(str(world.client_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
				print("1")
				vector = vector.normalized() * (vector.length() + list[object].length())
				if ((spawner.get_node(str(world.client_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
					print('2')
					vector = vector.normalized() * (vector.length() + list[object].length())
		vector = get_inside_position_player(spawner.get_node(str(world.client_id) + "/LocalCharacter/Body").global_position + vector, str(world.client_id)) - spawner.get_node(str(world.client_id) + "/LocalCharacter/Body").global_position
		for object in list:
			if ((spawner.get_node(str(world.client_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
				print("1")
				print(vector)
				vector = vector.normalized() * (vector.length() - list[object].length())
				print(vector)
				if ((spawner.get_node(str(world.client_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
					print('2')
					vector = vector.normalized() * (vector.length() - list[object].length())
		vector = get_inside_position_player(spawner.get_node(str(world.client_id) + "/LocalCharacter/Body").global_position + vector, str(world.client_id))
	return vector

