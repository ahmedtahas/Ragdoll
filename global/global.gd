extends Node

@onready var camera: Camera2D
@onready var world: Node2D
@onready var spawner: Node2D
@onready var player: Node2D
@onready var bot: Node2D

@onready var room: Vector2 = Vector2(20420, -10180)

func get_inside_position(pos: Vector2, player_name: String) -> Vector2:
	var _player = spawner.get_node((player_name) as NodePath)
	if pos.x > room.x:
		pos.x = room.x - _player.radius.x
	elif pos.x < _player.radius.x:
		pos.x = _player.radius.x
	if pos.y < room.y:
		pos.y = room.y + _player.radius.x
	elif pos.y > -_player.radius.x:
		pos.y -= _player.radius.x
	return pos
