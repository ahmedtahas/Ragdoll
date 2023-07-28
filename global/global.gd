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
		pos.x = room.x - _player.radius.x
	elif pos.x < _player.radius.x:
		pos.x = _player.radius.x
	if pos.y < room.y:
		pos.y = room.y + _player.radius.x
	elif pos.y > -_player.radius.x:
		pos.y -= _player.radius.x
	return pos


func avoid_enemy(player_id):
	pass
	var teleporting_player = spawner.get_node(player_id)
	var teleporting_player_body
	var enemy_locations = {}
	if teleporting_player.has_node("LocalCharacter"):
		teleporting_player_body = teleporting_player.get_node("LocalCharacter/Body").global_position
		for child in spawner.get_children():
			if child != teleporting_player:
				enemy_locations[child.center + child.get_node("RemoteCharacter/Body").global_position] = child.radius
		if server_skill.get_child_count() >= 0:
			if not server_skill.get_child(0) is CharacterBody2D:
				pass

	else:
		teleporting_player_body = teleporting_player.get_node("RemoteCharacter/Body").global_position

