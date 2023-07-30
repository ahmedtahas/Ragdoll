extends Node

const room: Vector2 = Vector2(20420, -10180)

@onready var camera: Camera2D
@onready var world: Node2D
@onready var spawner: Node2D
@onready var server_skill: Node2D
@onready var client_skill: Node2D
@onready var player: Node2D
@onready var bot: Node2D


func get_inside_position(pos: Vector2, player_id: String) -> Vector2:
	var _player = spawner.get_node(player_id)
	if pos.x > room.x:
		pos.x = room.x
	elif pos.x < _player.radius.x:
		pos.x = 0
	if pos.y < room.y:
		pos.y = room.y
	elif pos.y > -_player.radius.x:
		pos.y -= 0
	return pos


func avoid_enemies(vector) -> Vector2:
	var list: Dictionary = {}
	if multiplayer.is_server():
		list[spawner.get_node(str(world.client_id) + "/RemoteCharacter/Body").global_position + (spawner.get_node(str(world.client_id)).center.rotated(spawner.get_node(str(world.client_id) + "/RemoteCharacter/Body").global_rotation))] = spawner.get_node(str(world.client_id)).radius
		if client_skill.get_child_count() > 0:
			if not client_skill.get_child(0) is CharacterBody2D:
				list[client_skill.get_node("Clone/RemoteCharacter/Body").global_position + (client_skill.get_node("Clone").center.rotated(client_skill.get_node("Clone/RemoteCharacter/Body").global_rotation))] = client_skill.get_node("Clone").radius
		for object in list:
			if ((spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
				print("1")
				vector = vector.normalized() * (vector.length() + list[object].length())
				if ((spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position + vector) - object).length() < list[object].length():
					print('2')
					vector = vector.normalized() * (vector.length() + list[object].length())
		vector = get_inside_position(vector + spawner.get_node(str(world.server_id) + "/LocalCharacter/Body").global_position, str(world.server_id))

	else:
		pass
#
	return vector

